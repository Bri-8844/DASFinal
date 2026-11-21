using Microsoft.AspNetCore.Identity;

namespace GestionFTTH.Web.Services
{
    /// <summary>
    /// Mensajes de error de ASP.NET Core Identity en español
    /// (se muestran en los módulos Usuarios y Administrar cuenta).
    /// </summary>
    public class IdentityErroresEspanol : IdentityErrorDescriber
    {
        private static IdentityError E(string codigo, string mensaje) =>
            new() { Code = codigo, Description = mensaje };

        public override IdentityError DefaultError() =>
            E(nameof(DefaultError), "Ocurrió un error desconocido.");

        public override IdentityError ConcurrencyFailure() =>
            E(nameof(ConcurrencyFailure), "El registro fue modificado por otro usuario. Vuelva a intentarlo.");

        public override IdentityError PasswordMismatch() =>
            E(nameof(PasswordMismatch), "La contraseña es incorrecta.");

        public override IdentityError InvalidToken() =>
            E(nameof(InvalidToken), "El token no es válido.");

        public override IdentityError LoginAlreadyAssociated() =>
            E(nameof(LoginAlreadyAssociated), "Ya existe un usuario con este inicio de sesión.");

        public override IdentityError InvalidUserName(string? userName) =>
            E(nameof(InvalidUserName), $"El nombre de usuario '{userName}' no es válido.");

        public override IdentityError InvalidEmail(string? email) =>
            E(nameof(InvalidEmail), $"El correo '{email}' no es válido.");

        public override IdentityError DuplicateUserName(string userName) =>
            E(nameof(DuplicateUserName), $"Ya existe una cuenta con el usuario '{userName}'.");

        public override IdentityError DuplicateEmail(string email) =>
            E(nameof(DuplicateEmail), $"Ya existe una cuenta con el correo '{email}'.");

        public override IdentityError InvalidRoleName(string? role) =>
            E(nameof(InvalidRoleName), $"El rol '{role}' no es válido.");

        public override IdentityError DuplicateRoleName(string role) =>
            E(nameof(DuplicateRoleName), $"El rol '{role}' ya existe.");

        public override IdentityError UserAlreadyHasPassword() =>
            E(nameof(UserAlreadyHasPassword), "El usuario ya tiene una contraseña.");

        public override IdentityError UserLockoutNotEnabled() =>
            E(nameof(UserLockoutNotEnabled), "El bloqueo no está habilitado para este usuario.");

        public override IdentityError UserAlreadyInRole(string role) =>
            E(nameof(UserAlreadyInRole), $"El usuario ya tiene el rol '{role}'.");

        public override IdentityError UserNotInRole(string role) =>
            E(nameof(UserNotInRole), $"El usuario no tiene el rol '{role}'.");

        public override IdentityError PasswordTooShort(int length) =>
            E(nameof(PasswordTooShort), $"La contraseña debe tener al menos {length} caracteres.");

        public override IdentityError PasswordRequiresUniqueChars(int uniqueChars) =>
            E(nameof(PasswordRequiresUniqueChars), $"La contraseña debe tener al menos {uniqueChars} caracteres distintos.");

        public override IdentityError PasswordRequiresNonAlphanumeric() =>
            E(nameof(PasswordRequiresNonAlphanumeric), "La contraseña debe tener al menos un símbolo (por ejemplo # o !).");

        public override IdentityError PasswordRequiresDigit() =>
            E(nameof(PasswordRequiresDigit), "La contraseña debe tener al menos un número.");

        public override IdentityError PasswordRequiresLower() =>
            E(nameof(PasswordRequiresLower), "La contraseña debe tener al menos una letra minúscula.");

        public override IdentityError PasswordRequiresUpper() =>
            E(nameof(PasswordRequiresUpper), "La contraseña debe tener al menos una letra mayúscula.");

        public override IdentityError RecoveryCodeRedemptionFailed() =>
            E(nameof(RecoveryCodeRedemptionFailed), "El código de recuperación no es válido.");
    }
}
