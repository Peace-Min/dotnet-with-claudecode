# FluentValidation + WPF Integration Guide

> Implements FluentValidation with WPF INotifyDataErrorInfo bridge for form validation. Use when building complex validation rules with RuleFor, AbstractValidator, or integrating FluentValidation with a hand-rolled BindableBase (no CommunityToolkit.Mvvm).

> **net472/no-CTK note (this fork):** keep the FluentValidation +
> `INotifyDataErrorInfo` bridge pattern, but use the hand-rolled
> `BindableBase`/`RelayCommand` (do NOT use CommunityToolkit.Mvvm) and
> C# 7.3-safe syntax. The fork's MVVM standard is `implementing-handrolled-mvvm`.
> Prism 사용 시 → [PRISM.md](PRISM.md) 참조

FluentValidation을 WPF MVVM 패턴에 통합하는 가이드.

## NuGet Packages

```xml
<!-- FluentValidation 11.x targets .NET Standard 2.0, so it runs on net472/net48. -->
<PackageReference Include="FluentValidation" Version="11.*" />
```

> ⚠️ FluentValidation 12는 .NET 8 이상 필수이므로 net472/net48에서는 사용할 수 없습니다.
> Use FluentValidation 11.x on net472/net48 (it targets .NET Standard 2.0).
> `FluentValidation.DependencyInjectionExtensions`는 `Microsoft.Extensions.DependencyInjection`
> 사용 시에만 추가합니다.

## 1. Validator 정의

```csharp
namespace MyApp.Core.Validators
{
    public sealed class UserValidator : AbstractValidator<User>
    {
        public UserValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("이름을 입력하세요.")
                // Name is required.
                .MinimumLength(2).WithMessage("이름은 2자 이상이어야 합니다.");
                // Name must be at least 2 characters.

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("이메일을 입력하세요.")
                // Email is required.
                .EmailAddress().WithMessage("올바른 이메일 형식이 아닙니다.");
                // Invalid email format.

            RuleFor(x => x.Age)
                .InclusiveBetween(1, 150).WithMessage("유효한 나이를 입력하세요.");
                // Please enter a valid age.
        }
    }
}
```

## 2. INotifyDataErrorInfo Bridge

FluentValidation → WPF 바인딩 연결을 위한 Base ViewModel:

```csharp
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using FluentValidation;
using MyApp.Mvvm; // hand-rolled BindableBase

namespace MyApp.ViewModels
{
    public abstract class ValidatableViewModel<TModel> : BindableBase, INotifyDataErrorInfo
    {
        private readonly IValidator<TModel> _validator;
        private readonly Dictionary<string, List<string>> _errors =
            new Dictionary<string, List<string>>();

        protected ValidatableViewModel(IValidator<TModel> validator)
        {
            _validator = validator;
        }

        public bool HasErrors
        {
            get { return _errors.Count > 0; }
        }

        public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

        public IEnumerable GetErrors(string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName))
                return _errors.SelectMany(e => e.Value);

            List<string> errors;
            return _errors.TryGetValue(propertyName, out errors)
                ? (IEnumerable)errors
                : new List<string>();
        }

        protected void ValidateProperty(TModel model, string propertyName)
        {
            var result = _validator.Validate(model);

            ClearErrors(propertyName);

            foreach (var error in result.Errors.Where(e => e.PropertyName == propertyName))
            {
                AddError(propertyName, error.ErrorMessage);
            }
        }

        protected bool ValidateAll(TModel model)
        {
            var result = _validator.Validate(model);

            // 전체 에러 초기화 후 재설정
            // Clear all errors and rebuild
            var previousProperties = _errors.Keys.ToList();
            _errors.Clear();

            foreach (var prop in previousProperties)
                OnErrorsChanged(prop);

            foreach (var error in result.Errors)
            {
                AddError(error.PropertyName, error.ErrorMessage);
            }

            return result.IsValid;
        }

        private void AddError(string propertyName, string error)
        {
            if (!_errors.ContainsKey(propertyName))
                _errors[propertyName] = new List<string>();

            if (!_errors[propertyName].Contains(error))
            {
                _errors[propertyName].Add(error);
                OnErrorsChanged(propertyName);
            }
        }

        private void ClearErrors(string propertyName)
        {
            if (_errors.Remove(propertyName))
                OnErrorsChanged(propertyName);
        }

        private void OnErrorsChanged(string propertyName)
        {
            var handler = ErrorsChanged;
            if (handler != null)
                handler(this, new DataErrorsChangedEventArgs(propertyName));

            RaisePropertyChanged(nameof(HasErrors));
        }
    }
}
```

## 3. ViewModel 구현

```csharp
using System.Windows.Input;
using FluentValidation;
using MyApp.Mvvm; // hand-rolled RelayCommand

namespace MyApp.ViewModels
{
    public sealed class UserFormViewModel : ValidatableViewModel<User>
    {
        private readonly User _user = new User();

        public UserFormViewModel(IValidator<User> validator) : base(validator)
        {
            SubmitCommand = new RelayCommand(Submit, CanSubmit);
        }

        private string _name = string.Empty;
        public string Name
        {
            get { return _name; }
            set
            {
                if (SetProperty(ref _name, value))
                {
                    _user.Name = value;
                    ValidateProperty(_user, nameof(Name));
                }
            }
        }

        private string _email = string.Empty;
        public string Email
        {
            get { return _email; }
            set
            {
                if (SetProperty(ref _email, value))
                {
                    _user.Email = value;
                    ValidateProperty(_user, nameof(Email));
                }
            }
        }

        private int _age;
        public int Age
        {
            get { return _age; }
            set
            {
                if (SetProperty(ref _age, value))
                {
                    _user.Age = value;
                    ValidateProperty(_user, nameof(Age));
                }
            }
        }

        public ICommand SubmitCommand { get; }

        private void Submit()
        {
            if (ValidateAll(_user))
            {
                // 제출 처리
                // Handle submission
            }
        }

        private bool CanSubmit()
        {
            return !HasErrors;
        }
    }
}
```

> `RelayCommand`의 `CanExecuteChanged`는 `CommandManager.RequerySuggested`에
> 연결되어 있어, 속성 변경 시 WPF가 `CanSubmit()`을 자동으로 재평가합니다.
> RelayCommand re-queries CanExecute automatically via CommandManager.

## 4. DI Registration

DI 컨테이너 없이도 동작합니다. ViewModel 생성 시 Validator를 직접 넘기면 됩니다.
Works without any DI container — just pass the validator when creating the ViewModel.

```csharp
// 컨테이너 없는 수동 구성 (가장 단순)
// Manual wiring without a container (simplest)
var vm = new UserFormViewModel(new UserValidator());
```

`Microsoft.Extensions.DependencyInjection`을 사용하는 경우
`FluentValidation.DependencyInjectionExtensions` 패키지로 일괄 등록할 수 있습니다.
When using Microsoft.Extensions.DependencyInjection, register validators in bulk:

```csharp
// 기본 수명: Scoped → WPF에서는 Singleton 권장
// Default lifetime: Scoped → Singleton recommended for WPF
services.AddValidatorsFromAssemblyContaining<UserValidator>(ServiceLifetime.Singleton);

services.AddTransient<UserFormViewModel>();
```

## 5. XAML Binding

```xml
<TextBox Text="{Binding Name,
                UpdateSourceTrigger=PropertyChanged,
                ValidatesOnNotifyDataErrors=True}" />

<TextBox Text="{Binding Email,
                UpdateSourceTrigger=PropertyChanged,
                ValidatesOnNotifyDataErrors=True}" />
```

> ⚠️ `UpdateSourceTrigger=PropertyChanged` 필수. 없으면 포커스 이탈 시에만 검증.

## 6. DataAnnotations 검증과의 관계

CommunityToolkit.Mvvm의 `ObservableValidator`는 이 포크에서 사용하지 않습니다.
DataAnnotations 검증이 필요하면 `BindableBase` + 직접 구현한
`INotifyDataErrorInfo`에서 `Validator.TryValidateProperty()`를 호출하세요.
This fork does NOT use CommunityToolkit.Mvvm's `ObservableValidator`; for
attribute-based validation, hand-roll `INotifyDataErrorInfo` on `BindableBase`
and call `Validator.TryValidateProperty()` from `System.ComponentModel.DataAnnotations`.

| 비교 | DataAnnotations (hand-rolled) | FluentValidation |
|------|-------------------------------|------------------|
| 규칙 정의 | 특성 (`[Required]`) | Fluent API (`RuleFor`) |
| 복잡한 규칙 | 제한적 | 교차 필드, 조건부, 컬렉션 검증 |
| 의존성 | BCL만 (추가 패키지 불필요) | `FluentValidation` 패키지 필요 |
| 적합한 경우 | 단순 폼 검증 | 복잡한 비즈니스 규칙 |

**혼용 금지**: DataAnnotations 검증과 FluentValidation을 같은 모델에 동시 사용하면 에러가 중복/누락됩니다. 하나만 선택하세요.
Do not mix DataAnnotations and FluentValidation on the same model — pick one.

## 7. Common Mistakes

| 실수 | 올바른 방법 |
|------|------------|
| Model 대신 ViewModel을 직접 검증 | `AbstractValidator<Model>` 사용, ViewModel에서 Model 동기화 |
| 매 변경마다 전체 Validate 호출 | `ValidateProperty`로 해당 속성만 필터링 |
| ErrorsChanged 미발생 | `_errors` 변경 후 반드시 `ErrorsChanged` 이벤트 |
| Singleton Validator에 Scoped 의존성 주입 | Captive Dependency 주의, WPF에서는 Singleton 권장 |
| UpdateSourceTrigger 미설정 | `PropertyChanged` 명시 필수 |
| FluentValidation 12 패키지 사용 | net472/net48에서는 FluentValidation 11.x 사용 |

## Key Rules

- Validator는 Model(POCO)을 대상으로 정의
- ViewModel에서 Model 동기화 후 `ValidateProperty()` 호출
- `INotifyDataErrorInfo` 브릿지로 WPF 바인딩 연결 (`BindableBase` 기반, 직접 구현)
- DI 컨테이너 없이도 Validator를 생성자에 직접 주입 가능
- DataAnnotations 검증과 혼용 금지 (둘 중 하나만)
- net472/net48에서는 FluentValidation 11.x 사용
- See also: `implementing-handrolled-mvvm` (이 포크의 MVVM 표준), `handling-errors-with-erroror` (서비스 레이어 에러 처리)

## 참고

- [FluentValidation Docs](https://docs.fluentvalidation.net/)
- [v12 Upgrade Guide](https://docs.fluentvalidation.net/en/latest/upgrading-to-12.html)
