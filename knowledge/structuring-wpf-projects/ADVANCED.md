# WPF Solution and Project Structure — Advanced Patterns

> Core concepts: See [SKILL.md](SKILL.md)

> **net472/no-CTK note (this fork):** the layer separation here is the subject;
> the MVVM/wiring code uses the hand-rolled `BindableBase`/`RelayCommand`
> (no CommunityToolkit.Mvvm) and C# 7.3-safe syntax (block-scoped namespaces,
> no records/init/target-typed `new`/nullable reference types). The fork's MVVM
> standard is `implementing-handrolled-mvvm`.

## Detailed Layer Descriptions

### Domain Layer (Pure Domain)

```csharp
// Domain/Entities/User.cs
namespace GameDataTool.Domain.Entities
{
    public sealed class User
    {
        public Guid Id { get; set; }
        public string Name { get; private set; } = string.Empty;
        public Email Email { get; private set; }

        public void UpdateName(string name)
        {
            // Domain business rule validation
            if (string.IsNullOrWhiteSpace(name))
                throw new DomainException("Name is required.");

            Name = name;
        }
    }
}
```

```csharp
// Domain/ValueObjects/Email.cs
namespace GameDataTool.Domain.ValueObjects
{
    public sealed class Email
    {
        public string Value { get; private set; }

        public Email(string value)
        {
            if (!IsValid(value))
                throw new DomainException("Invalid email format.");

            Value = value;
        }

        private static bool IsValid(string email)
        {
            return !string.IsNullOrWhiteSpace(email) && email.Contains("@");
        }
    }
}
```

### Application Layer (Use Cases)

```csharp
// Application/Interfaces/IUserRepository.cs
namespace GameDataTool.Application.Interfaces
{
    public interface IUserRepository
    {
        Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default(CancellationToken));
        Task<IReadOnlyList<User>> GetAllAsync(CancellationToken cancellationToken = default(CancellationToken));
        Task AddAsync(User user, CancellationToken cancellationToken = default(CancellationToken));
        Task UpdateAsync(User user, CancellationToken cancellationToken = default(CancellationToken));
    }
}
```

```csharp
// Application/Services/UserService.cs
namespace GameDataTool.Application.Services
{
    public sealed class UserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<UserDto> GetUserAsync(Guid id, CancellationToken cancellationToken = default(CancellationToken))
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            return user == null ? null : new UserDto(user.Id, user.Name, user.Email.Value);
        }

        public async Task UpdateUserNameAsync(Guid id, string newName, CancellationToken cancellationToken = default(CancellationToken))
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            if (user == null)
                throw new NotFoundException("User not found.");

            user.UpdateName(newName);
            await _userRepository.UpdateAsync(user, cancellationToken);
        }
    }
}
```

```csharp
// Application/DTOs/UserDto.cs
namespace GameDataTool.Application.DTOs
{
    public sealed class UserDto
    {
        public Guid Id { get; private set; }
        public string Name { get; private set; }
        public string Email { get; private set; }

        public UserDto(Guid id, string name, string email)
        {
            Id = id;
            Name = name;
            Email = email;
        }
    }
}
```

### Infrastructure Layer (External System Implementation)

```csharp
// Infrastructure/Persistence/UserRepository.cs
namespace GameDataTool.Infrastructure.Persistence
{
    public sealed class UserRepository : IUserRepository
    {
        private readonly AppDbContext _dbContext;

        public UserRepository(AppDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<User> GetByIdAsync(Guid id, CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _dbContext.Users.FindAsync(new object[] { id }, cancellationToken);
        }

        public async Task<IReadOnlyList<User>> GetAllAsync(CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _dbContext.Users.ToListAsync(cancellationToken);
        }

        public async Task AddAsync(User user, CancellationToken cancellationToken = default(CancellationToken))
        {
            await _dbContext.Users.AddAsync(user, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        public async Task UpdateAsync(User user, CancellationToken cancellationToken = default(CancellationToken))
        {
            _dbContext.Users.Update(user);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
```

### ViewModels Layer (Presentation - Depends on Application Only)

```csharp
// ViewModels/UserViewModel.cs
using System.Windows.Input;
using GameDataTool.Mvvm; // hand-rolled BindableBase / RelayCommand<T>

namespace GameDataTool.ViewModels
{
    public sealed class UserViewModel : BindableBase
    {
        private readonly UserService _userService;

        public UserViewModel(UserService userService)
        {
            _userService = userService;
            LoadUserCommand = new RelayCommand<Guid>(
                async userId => await LoadUserAsync(userId));
        }

        private string _userName = string.Empty;
        public string UserName
        {
            get { return _userName; }
            set { SetProperty(ref _userName, value); }
        }

        private string _userEmail = string.Empty;
        public string UserEmail
        {
            get { return _userEmail; }
            set { SetProperty(ref _userEmail, value); }
        }

        public ICommand LoadUserCommand { get; }

        private async Task LoadUserAsync(Guid userId)
        {
            var user = await _userService.GetUserAsync(userId);
            if (user == null) return;

            UserName = user.Name;
            UserEmail = user.Email;
        }
    }
}
```

> The async lambda passed to `RelayCommand<Guid>` is `async void` at the
> delegate boundary (it returns `void`). Keep the awaited work inside a private
> `async Task` method as shown, and add try/catch in `LoadUserAsync` so faults
> are not lost. (`AsyncRelayCommand` from CommunityToolkit is not used in this fork.)

### WpfApp Layer (Composition Root - DI Setup)

```csharp
// WpfApp/App.xaml.cs
// GenericHost (Microsoft.Extensions.Hosting) is optional and runs on net472/net48.
// It is the DI container only; it does NOT pull in CommunityToolkit.Mvvm.
using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace GameDataTool.WpfApp
{
    public partial class App : Application
    {
        private readonly IHost _host;

        public App()
        {
            _host = Host.CreateDefaultBuilder()
                .ConfigureServices((context, services) =>
                {
                    // Domain - No registration needed (pure models)

                    // Application Layer
                    services.AddTransient<UserService>();

                    // Infrastructure Layer
                    services.AddDbContext<AppDbContext>();
                    services.AddScoped<IUserRepository, UserRepository>();

                    // Presentation Layer
                    services.AddTransient<UserViewModel>();
                    services.AddTransient<MainViewModel>();

                    // WPF Services
                    services.AddSingleton<IDialogService, DialogService>();
                    services.AddSingleton<INavigationService, NavigationService>();

                    // Views
                    services.AddSingleton<MainWindow>();
                })
                .Build();
        }

        protected override async void OnStartup(StartupEventArgs e)
        {
            await _host.StartAsync();
            _host.Services.GetRequiredService<MainWindow>().Show();
            base.OnStartup(e);
        }

        protected override async void OnExit(ExitEventArgs e)
        {
            using (_host)
            {
                await _host.StopAsync();
            }
            base.OnExit(e);
        }
    }
}
```

## Actual Folder Structure Example

```
GameDataTool/
├── src/
│   ├── GameDataTool.Domain/
│   │   ├── Entities/
│   │   │   ├── User.cs
│   │   │   └── GameData.cs
│   │   ├── ValueObjects/
│   │   │   ├── Email.cs
│   │   │   └── GameVersion.cs
│   │   ├── Interfaces/
│   │   │   └── IDomainEventPublisher.cs
│   │   ├── Exceptions/
│   │   │   └── DomainException.cs
│   │   ├── GlobalUsings.cs
│   │   └── GameDataTool.Domain.csproj
│   │
│   ├── GameDataTool.Application/
│   │   ├── Interfaces/
│   │   │   ├── IUserRepository.cs
│   │   │   ├── IGameDataRepository.cs
│   │   │   └── IFileExportService.cs
│   │   ├── Services/
│   │   │   ├── UserService.cs
│   │   │   └── GameDataService.cs
│   │   ├── DTOs/
│   │   │   ├── UserDto.cs
│   │   │   └── GameDataDto.cs
│   │   ├── Exceptions/
│   │   │   └── NotFoundException.cs
│   │   ├── GlobalUsings.cs
│   │   └── GameDataTool.Application.csproj
│   │
│   ├── GameDataTool.Infrastructure/
│   │   ├── Persistence/
│   │   │   ├── AppDbContext.cs
│   │   │   ├── UserRepository.cs
│   │   │   └── GameDataRepository.cs
│   │   ├── FileSystem/
│   │   │   └── ExcelExportService.cs
│   │   ├── ExternalServices/
│   │   │   └── ApiClient.cs
│   │   ├── GlobalUsings.cs
│   │   └── GameDataTool.Infrastructure.csproj
│   │
│   ├── GameDataTool.ViewModels/
│   │   ├── MainViewModel.cs
│   │   ├── UserViewModel.cs
│   │   ├── GameDataViewModel.cs
│   │   ├── GlobalUsings.cs
│   │   └── GameDataTool.ViewModels.csproj
│   │
│   ├── GameDataTool.WpfServices/
│   │   ├── DialogService.cs
│   │   ├── NavigationService.cs
│   │   ├── WindowService.cs
│   │   ├── GlobalUsings.cs
│   │   └── GameDataTool.WpfServices.csproj
│   │
│   ├── GameDataTool.UI/
│   │   ├── Themes/
│   │   │   ├── Generic.xaml
│   │   │   └── CustomButton.xaml
│   │   ├── CustomControls/
│   │   │   └── CustomButton.cs
│   │   ├── Properties/
│   │   │   └── AssemblyInfo.cs
│   │   └── GameDataTool.UI.csproj
│   │
│   └── GameDataTool.WpfApp/
│       ├── Views/
│       │   ├── MainWindow.xaml
│       │   ├── MainWindow.xaml.cs
│       │   ├── UserView.xaml
│       │   └── UserView.xaml.cs
│       ├── App.xaml
│       ├── App.xaml.cs
│       ├── Mappings.xaml
│       ├── GlobalUsings.cs
│       └── GameDataTool.WpfApp.csproj
│
├── tests/
│   ├── GameDataTool.Domain.Tests/
│   │   ├── Entities/
│   │   │   └── UserTests.cs
│   │   └── GameDataTool.Domain.Tests.csproj
│   │
│   ├── GameDataTool.Application.Tests/
│   │   ├── Services/
│   │   │   └── UserServiceTests.cs
│   │   └── GameDataTool.Application.Tests.csproj
│   │
│   └── GameDataTool.ViewModels.Tests/
│       ├── UserViewModelTests.cs
│       └── GameDataTool.ViewModels.Tests.csproj
│
├── GameDataTool.sln
└── Directory.Build.props
```
