# WPF Data Validation

> Implements WPF data validation using ValidationRule, IDataErrorInfo, and INotifyDataErrorInfo. Use when building forms, validating user input, or displaying validation errors in UI.

> **MVVM Framework Rule**: `.claude/rules/dotnet/wpf/mvvm-framework.md` 설정에 따라 코드 스타일이 결정됩니다.
> Prism 9 사용 시 → [PRISM.md](PRISM.md) 참조

## 1. Validation Approaches

| Approach | Location | Pros | Cons |
|----------|----------|------|------|
| `ValidationRule` | XAML (Binding) | Simple, declarative XAML | Hard to separate from ViewModel |
| `IDataErrorInfo` | ViewModel | ViewModel integration | Synchronous validation only |
| `INotifyDataErrorInfo` | ViewModel | Async support, multiple errors | Complex implementation |
| `ExceptionValidationRule` | XAML | Exception-based | Potential performance impact |

---

## 2. ValidationRule

### 2.1 Custom ValidationRule

```csharp
public sealed class EmailValidationRule : ValidationRule
{
    private static readonly Regex EmailPattern = new Regex(
        @"^[^@\s]+@[^@\s]+\.[^@\s]+$",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public override ValidationResult Validate(object value, CultureInfo cultureInfo)
    {
        var email = value as string;
        if (email == null || string.IsNullOrWhiteSpace(email))
        {
            return new ValidationResult(false, "Please enter an email address.");
        }

        if (!EmailPattern.IsMatch(email))
        {
            return new ValidationResult(false, "Invalid email format.");
        }

        return ValidationResult.ValidResult;
    }
}
```

> **Note**: `GeneratedRegexAttribute` (compile-time regex) requires .NET 7+, so
> this fork uses a `static readonly Regex` with `RegexOptions.Compiled` instead.

### 2.2 XAML Usage

```xml
<TextBox>
    <TextBox.Text>
        <Binding Path="Email" UpdateSourceTrigger="PropertyChanged">
            <Binding.ValidationRules>
                <local:EmailValidationRule ValidatesOnTargetUpdated="True"/>
            </Binding.ValidationRules>
        </Binding>
    </TextBox.Text>
</TextBox>
```

### 2.3 Error Template

```xml
<Style TargetType="TextBox">
    <Setter Property="Validation.ErrorTemplate">
        <Setter.Value>
            <ControlTemplate>
                <DockPanel>
                    <TextBlock DockPanel.Dock="Right" Foreground="Red" Text="!"
                               FontWeight="Bold" Margin="5,0"/>
                    <Border BorderBrush="Red" BorderThickness="1">
                        <AdornedElementPlaceholder/>
                    </Border>
                </DockPanel>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
    <Style.Triggers>
        <Trigger Property="Validation.HasError" Value="True">
            <Setter Property="ToolTip"
                    Value="{Binding RelativeSource={RelativeSource Self},
                           Path=(Validation.Errors)[0].ErrorContent}"/>
        </Trigger>
    </Style.Triggers>
</Style>
```

---

## 3. IDataErrorInfo

### 3.1 Implementation

```csharp
public sealed class UserViewModel : BindableBase, IDataErrorInfo
{
    private string _name = string.Empty;
    public string Name
    {
        get { return _name; }
        set { SetProperty(ref _name, value); }
    }

    private int _age;
    public int Age
    {
        get { return _age; }
        set { SetProperty(ref _age, value); }
    }

    public string Error { get { return string.Empty; } }

    public string this[string columnName]
    {
        get
        {
            if (columnName == nameof(Name) && string.IsNullOrWhiteSpace(Name))
            {
                return "Please enter a name.";
            }

            if (columnName == nameof(Name) && Name.Length < 2)
            {
                return "Name must be at least 2 characters.";
            }

            if (columnName == nameof(Age) && (Age < 0 || Age > 150))
            {
                return "Please enter a valid age.";
            }

            return string.Empty;
        }
    }
}
```

### 3.2 XAML Binding

```xml
<TextBox Text="{Binding Name,
                        UpdateSourceTrigger=PropertyChanged,
                        ValidatesOnDataErrors=True}"/>
```

---

## 4. INotifyDataErrorInfo (Recommended)

### 4.1 Base Implementation

```csharp
public abstract class ValidatableViewModelBase : BindableBase, INotifyDataErrorInfo
{
    private readonly Dictionary<string, List<string>> _errors =
        new Dictionary<string, List<string>>();

    public bool HasErrors { get { return _errors.Count > 0; } }

    public event EventHandler<DataErrorsChangedEventArgs> ErrorsChanged;

    public IEnumerable GetErrors(string propertyName)
    {
        if (string.IsNullOrEmpty(propertyName))
        {
            return _errors.SelectMany(e => e.Value);
        }

        List<string> errors;
        return _errors.TryGetValue(propertyName, out errors)
            ? errors
            : Enumerable.Empty<string>();
    }

    protected void AddError(string propertyName, string error)
    {
        if (!_errors.ContainsKey(propertyName))
        {
            _errors[propertyName] = new List<string>();
        }

        if (!_errors[propertyName].Contains(error))
        {
            _errors[propertyName].Add(error);
            OnErrorsChanged(propertyName);
        }
    }

    protected void ClearErrors(string propertyName)
    {
        if (_errors.Remove(propertyName))
        {
            OnErrorsChanged(propertyName);
        }
    }

    protected void ClearAllErrors()
    {
        var properties = _errors.Keys.ToList();
        _errors.Clear();
        foreach (var prop in properties)
        {
            OnErrorsChanged(prop);
        }
    }

    private void OnErrorsChanged(string propertyName)
    {
        var handler = ErrorsChanged;
        if (handler != null)
        {
            handler(this, new DataErrorsChangedEventArgs(propertyName));
        }

        RaisePropertyChanged(nameof(HasErrors));
    }
}
```

### 4.2 ViewModel with Validation

```csharp
public sealed class RegistrationViewModel : ValidatableViewModelBase
{
    public RegistrationViewModel()
    {
        SubmitCommand = new RelayCommand(Submit, CanSubmit);
    }

    private string _email = string.Empty;
    public string Email
    {
        get { return _email; }
        set
        {
            if (SetProperty(ref _email, value))
            {
                ValidateEmail();
                SubmitCommand.RaiseCanExecuteChanged();
            }
        }
    }

    private string _password = string.Empty;
    public string Password
    {
        get { return _password; }
        set
        {
            if (SetProperty(ref _password, value))
            {
                ValidatePassword();
                ValidateConfirmPassword();
                SubmitCommand.RaiseCanExecuteChanged();
            }
        }
    }

    private string _confirmPassword = string.Empty;
    public string ConfirmPassword
    {
        get { return _confirmPassword; }
        set
        {
            if (SetProperty(ref _confirmPassword, value))
            {
                ValidateConfirmPassword();
                SubmitCommand.RaiseCanExecuteChanged();
            }
        }
    }

    private void ValidateEmail()
    {
        ClearErrors(nameof(Email));

        if (string.IsNullOrWhiteSpace(Email))
        {
            AddError(nameof(Email), "Please enter an email address.");
        }
        else if (!Email.Contains('@'))
        {
            AddError(nameof(Email), "Invalid email format.");
        }
    }

    private void ValidatePassword()
    {
        ClearErrors(nameof(Password));

        if (Password.Length < 8)
        {
            AddError(nameof(Password), "Password must be at least 8 characters.");
        }

        if (!Password.Any(char.IsDigit))
        {
            AddError(nameof(Password), "Password must contain a digit.");
        }
    }

    private void ValidateConfirmPassword()
    {
        ClearErrors(nameof(ConfirmPassword));

        if (ConfirmPassword != Password)
        {
            AddError(nameof(ConfirmPassword), "Passwords do not match.");
        }
    }

    public RelayCommand SubmitCommand { get; }

    private void Submit()
    {
        ValidateAll();
        if (!HasErrors)
        {
            // Submit logic
        }
    }

    private bool CanSubmit()
    {
        return !HasErrors && !string.IsNullOrEmpty(Email);
    }

    private void ValidateAll()
    {
        ValidateEmail();
        ValidatePassword();
        ValidateConfirmPassword();
    }
}
```

### 4.3 XAML Binding

```xml
<TextBox Text="{Binding Email,
                        UpdateSourceTrigger=PropertyChanged,
                        ValidatesOnNotifyDataErrors=True}"/>

<!-- Error list display -->
<ItemsControl ItemsSource="{Binding (Validation.Errors),
              RelativeSource={RelativeSource Self}}">
    <ItemsControl.ItemTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding ErrorContent}" Foreground="Red"/>
        </DataTemplate>
    </ItemsControl.ItemTemplate>
</ItemsControl>
```

---

## 5. DataAnnotations-Based Validation (Hand-Rolled)

> This fork does NOT use CommunityToolkit.Mvvm's `ObservableValidator`.
> Instead, drive DataAnnotations attributes through `Validator.TryValidateProperty`
> on top of the hand-rolled `ValidatableViewModelBase` from section 4.1.

Add two helpers to `ValidatableViewModelBase` (section 4.1) so attribute-based
validation can reuse the same error store:

```csharp
// using System.ComponentModel.DataAnnotations;

protected void ValidateProperty(object value, string propertyName)
{
    ClearErrors(propertyName);

    var context = new ValidationContext(this) { MemberName = propertyName };
    var results = new List<ValidationResult>();

    if (!Validator.TryValidateProperty(value, context, results))
    {
        foreach (var result in results)
        {
            AddError(propertyName, result.ErrorMessage);
        }
    }
}

protected void ValidateAllProperties()
{
    var context = new ValidationContext(this);
    var results = new List<ValidationResult>();

    Validator.TryValidateObject(this, context, results, validateAllProperties: true);

    ClearAllErrors();
    foreach (var result in results)
    {
        foreach (var member in result.MemberNames)
        {
            AddError(member, result.ErrorMessage);
        }
    }
}
```

The ViewModel decorates each full property with DataAnnotations attributes and
calls `ValidateProperty` from the setter:

```csharp
public sealed class UserViewModel : ValidatableViewModelBase
{
    public UserViewModel()
    {
        SubmitCommand = new RelayCommand(Submit);
    }

    private string _name = string.Empty;
    [Required(ErrorMessage = "Please enter a name.")]
    [MinLength(2, ErrorMessage = "Name must be at least 2 characters.")]
    public string Name
    {
        get { return _name; }
        set
        {
            if (SetProperty(ref _name, value))
            {
                ValidateProperty(value, nameof(Name));
            }
        }
    }

    private int _age;
    [Required]
    [Range(1, 150, ErrorMessage = "Please enter a valid age.")]
    public int Age
    {
        get { return _age; }
        set
        {
            if (SetProperty(ref _age, value))
            {
                ValidateProperty(value, nameof(Age));
            }
        }
    }

    private string _email = string.Empty;
    [EmailAddress(ErrorMessage = "Invalid email format.")]
    public string Email
    {
        get { return _email; }
        set
        {
            if (SetProperty(ref _email, value))
            {
                ValidateProperty(value, nameof(Email));
            }
        }
    }

    public RelayCommand SubmitCommand { get; }

    private void Submit()
    {
        ValidateAllProperties();
        if (!HasErrors)
        {
            // Submit logic
        }
    }
}
```

---

## 6. Summary

| Requirement | Recommended Approach |
|-------------|---------------------|
| Simple XAML validation | ValidationRule |
| ViewModel-based validation | INotifyDataErrorInfo |
| DataAnnotations usage | INotifyDataErrorInfo + `Validator.TryValidateProperty` |
| Async validation | INotifyDataErrorInfo |
| Legacy compatibility | IDataErrorInfo |
| Complex business rules | FluentValidation (`validating-with-fluentvalidation` skill) |
| Service layer errors | ErrorOr (`handling-errors-with-erroror` skill) |
