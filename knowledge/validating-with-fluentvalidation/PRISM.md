# FluentValidation + WPF - Prism Version (opt-in)

> **MVVM Framework Rule**: `.claude/rules/dotnet/wpf/prism9.md` 규칙이 적용됩니다.
> 이 포크의 기본값은 hand-rolled MVVM입니다 → [TOPIC.md](TOPIC.md) 참조

이 포크의 **기본** FluentValidation 통합은 hand-rolled `BindableBase`
(`implementing-handrolled-mvvm`)를 사용합니다. 이 문서는 프로젝트가 **이미** Prism을
도입한 경우(opt-in)에만 적용되며, Prism 자체의 `BindableBase`/`DelegateCommand`를
사용합니다.

> ⚠️ Prism 9는 .NET 8+ 전용입니다. net472/net48에서는 **Prism 7.2 또는 8.1**을 사용하고,
> 모든 코드는 C# 7.3 호환으로 작성합니다. Never auto-introduce Prism — opt-in only.

> SKILL([TOPIC.md](TOPIC.md))의 Validator 정의 (`AbstractValidator<T>`), XAML 바인딩은 프레임워크 무관이므로 그대로 사용합니다.
> 이 문서는 INotifyDataErrorInfo 브릿지의 Prism `BindableBase` 버전만 다룹니다.

## Hand-rolled (기본) vs Prism (opt-in) 비교

| 항목 | Hand-rolled (default) | Prism (opt-in) |
|------|-----------------------|----------------|
| 브릿지 Base Class | `ValidatableViewModel<T> : BindableBase` (hand-rolled) | `ValidatableBindableBase<T> : BindableBase` (Prism) |
| 속성 변경 콜백 | `SetProperty()` 내부 콜백 | `SetProperty()` 내부 콜백 |
| Command | `RelayCommand` (hand-rolled) | `DelegateCommand` (Prism) |
| DI 등록 | 생성자에 직접 주입 또는 MS.DI | `containerRegistry`에 수동 등록 |

## ValidatableBindableBase\<T\> (Prism BindableBase + FluentValidation)

> Prism의 `BindableBase`를 상속합니다. C# 7.3 호환으로 작성합니다.

```csharp
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using FluentValidation;
using Prism.Mvvm; // Prism's BindableBase

namespace MyApp.Core.Mvvm
{
    public abstract class ValidatableBindableBase<TModel> : BindableBase, INotifyDataErrorInfo
    {
        private readonly IValidator<TModel> _validator;
        private readonly Dictionary<string, List<string>> _errors =
            new Dictionary<string, List<string>>();

        protected ValidatableBindableBase(IValidator<TModel> validator)
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
                AddError(propertyName, error.ErrorMessage);
        }

        protected bool ValidateAll(TModel model)
        {
            var result = _validator.Validate(model);

            var previousProperties = _errors.Keys.ToList();
            _errors.Clear();
            foreach (var prop in previousProperties)
                OnErrorsChanged(prop);

            foreach (var error in result.Errors)
                AddError(error.PropertyName, error.ErrorMessage);

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

## ViewModel 구현

```csharp
using FluentValidation;
using Prism.Commands;

namespace MyApp.ViewModels
{
    public class UserFormViewModel : ValidatableBindableBase<User>
    {
        private readonly User _user = new User();

        public UserFormViewModel(IValidator<User> validator) : base(validator) { }

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

        private DelegateCommand _submitCommand;
        public DelegateCommand SubmitCommand
        {
            get
            {
                return _submitCommand ?? (_submitCommand =
                    new DelegateCommand(ExecuteSubmit, CanSubmit)
                        .ObservesProperty(() => HasErrors));
            }
        }

        private void ExecuteSubmit()
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

## DI 등록 (IContainerRegistry)

```csharp
protected override void RegisterTypes(IContainerRegistry containerRegistry)
{
    // FluentValidation Validator 등록
    // Register FluentValidation validators
    containerRegistry.RegisterSingleton<IValidator<User>, UserValidator>();

    // ViewModel 등록
    // Register ViewModel
    containerRegistry.Register<UserFormViewModel>();
}
```

> ⚠️ Prism은 `AddValidatorsFromAssemblyContaining<T>()` 확장 메서드를 직접 지원하지 않습니다. 개별 등록하거나 DryIoc 컨테이너에 직접 접근하여 일괄 등록할 수 있습니다.

## Key Differences from the hand-rolled default ([TOPIC.md](TOPIC.md))

- **Prism BindableBase**: hand-rolled `BindableBase` 대신 Prism의 `BindableBase` 상속 (둘 다 `SetProperty` 제공)
- **DelegateCommand**: hand-rolled `RelayCommand` 대신 Prism `DelegateCommand` + `.ObservesProperty()`
- **개별 DI 등록**: 생성자 직접 주입 대신 `RegisterSingleton<IValidator<T>, Validator>()` 개별 등록
- **Validator 정의 동일**: `AbstractValidator<T>` 정의는 변경 없음
- **net472/net48**: Prism 7.2/8.1 사용, C# 7.3 호환 코드
