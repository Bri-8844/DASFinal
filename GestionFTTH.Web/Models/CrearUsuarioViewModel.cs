
using System.ComponentModel.DataAnnotations;

namespace GestionFTTH.Web.Models
{
    public class CrearUsuarioViewModel
    {
        [Required(ErrorMessage = "Ingrese el correo electrónico")]
        [EmailAddress(ErrorMessage = "Ingrese un correo válido")]
        [StringLength(256)]
        [Display(Name = "Correo electrónico")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Ingrese una contraseña")]
        [StringLength(100, MinimumLength = 6,
            ErrorMessage = "La contraseña debe tener entre 6 y 100 caracteres")]
        [DataType(DataType.Password)]
        [Display(Name = "Contraseña")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Confirme la contraseña")]
        [DataType(DataType.Password)]
        [Compare("Password",
            ErrorMessage = "Las contraseñas no coinciden")]
        [Display(Name = "Confirmar contraseña")]
        public string ConfirmPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Seleccione un rol")]
        [Display(Name = "Rol")]
        public string Rol { get; set; } = string.Empty;

        [Display(Name = "Trabajador")]
        public int? TrabajadorId { get; set; }
    }

    public class EditarUsuarioViewModel
    {
        [Required]
        public string Id { get; set; } = string.Empty;

        [Required(ErrorMessage = "Ingrese el correo electrónico")]
        [EmailAddress(ErrorMessage = "Ingrese un correo válido")]
        [StringLength(256)]
        [Display(Name = "Correo electrónico")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Seleccione un rol")]
        [Display(Name = "Rol")]
        public string Rol { get; set; } = string.Empty;

        [Display(Name = "Trabajador")]
        public int? TrabajadorId { get; set; }

        // Opcional: solo se cambia si se ingresa
        [StringLength(100, MinimumLength = 6,
            ErrorMessage = "La contraseña debe tener entre 6 y 100 caracteres")]
        [DataType(DataType.Password)]
        [Display(Name = "Nueva contraseña (opcional)")]
        public string? NuevaPassword { get; set; }

        [DataType(DataType.Password)]
        [Compare(nameof(NuevaPassword),
            ErrorMessage = "Las contraseñas no coinciden")]
        [Display(Name = "Confirmar nueva contraseña")]
        public string? ConfirmarNuevaPassword { get; set; }
    }
}
