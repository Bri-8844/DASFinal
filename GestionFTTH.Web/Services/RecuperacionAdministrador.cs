using System.Security.Cryptography;
using GestionFTTH.Web.Data;
using Microsoft.AspNetCore.Identity;

namespace GestionFTTH.Web.Services
{
    /// <summary>
    /// Herramienta de línea de comandos para recuperar el acceso de un
    /// Administrador principal cuando no hay correo configurado ni otro
    /// administrador disponible.
    ///
    /// Uso (requiere acceso a la consola del servidor y a la base de datos):
    ///   GestionFTTH.Web --restablecer-admin correo@dominio --confirmar
    ///   (en desarrollo: dotnet run --project GestionFTTH.Web -- --restablecer-admin correo@dominio --confirmar)
    ///
    /// - Usa el mecanismo estándar de Identity (token de restablecimiento).
    /// - Genera una contraseña temporal aleatoria (RandomNumberGenerator) y la
    ///   muestra UNA sola vez en la consola. No se escribe en logs ni archivos.
    /// - Desbloquea la cuenta; el cambio de contraseña renueva el security stamp,
    ///   por lo que se cierran las sesiones abiertas.
    /// - No inicia la aplicación web.
    /// </summary>
    public static class RecuperacionAdministrador
    {
        public const string Comando = "--restablecer-admin";
        private const string Confirmacion = "--confirmar";

        public static bool Solicitado(string[] args) =>
            args.Any(a => string.Equals(a, Comando, StringComparison.OrdinalIgnoreCase));

        public static async Task<int> EjecutarAsync(IServiceProvider servicios, string[] args)
        {
            int indice = Array.FindIndex(args, a => string.Equals(a, Comando, StringComparison.OrdinalIgnoreCase));
            string? email = indice + 1 < args.Length && !args[indice + 1].StartsWith("--")
                ? args[indice + 1].Trim()
                : null;
            bool confirmado = args.Any(a => string.Equals(a, Confirmacion, StringComparison.OrdinalIgnoreCase));

            if (string.IsNullOrWhiteSpace(email))
            {
                Console.WriteLine($"Uso: GestionFTTH.Web {Comando} <correo del administrador> {Confirmacion}");
                return 2;
            }

            using var scope = servicios.CreateScope();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>()
                .CreateLogger("GestionFTTH.RecuperacionAdministrador");

            var usuario = await userManager.FindByEmailAsync(email);

            if (usuario == null)
            {
                Console.WriteLine("No existe ninguna cuenta con ese correo.");
                return 3;
            }

            if (!await userManager.IsInRoleAsync(usuario, Roles.AdministradorPrincipal))
            {
                Console.WriteLine(
                    "La cuenta no es Administrador principal. Las contraseñas de los demás " +
                    "usuarios se restablecen desde el módulo Usuarios (Editar).");
                return 4;
            }

            if (!confirmado)
            {
                Console.WriteLine(
                    $"Se restablecerá la contraseña de {usuario.Email} y se cerrarán sus sesiones abiertas.");
                Console.WriteLine($"Para continuar, repita el comando agregando {Confirmacion}.");
                return 5;
            }

            string temporal = GenerarContrasenaTemporal(20);

            string token = await userManager.GeneratePasswordResetTokenAsync(usuario);
            var resultado = await userManager.ResetPasswordAsync(usuario, token, temporal);

            if (!resultado.Succeeded)
            {
                Console.WriteLine("No se pudo restablecer la contraseña:");
                foreach (var error in resultado.Errors)
                {
                    Console.WriteLine("  - " + error.Description);
                }
                return 6;
            }

            await userManager.SetLockoutEndDateAsync(usuario, null);
            await userManager.ResetAccessFailedCountAsync(usuario);

            // Registro de auditoría SIN la contraseña
            logger.LogWarning(
                "Contraseña del Administrador principal {Email} restablecida con la herramienta de recuperación.",
                usuario.Email);

            Console.WriteLine();
            Console.WriteLine("Contraseña restablecida correctamente.");
            Console.WriteLine($"  Cuenta:               {usuario.Email}");
            Console.WriteLine($"  Contraseña temporal:  {temporal}");
            Console.WriteLine();
            Console.WriteLine("Inicie sesión y cámbiela de inmediato en Administrar cuenta > Password.");
            Console.WriteLine("Esta contraseña no se guarda en ningún archivo ni registro: no se volverá a mostrar.");

            return 0;
        }

        /// <summary>
        /// Contraseña aleatoria criptográficamente segura que cumple la política de
        /// Identity (mayúscula, minúscula, número y símbolo).
        /// </summary>
        public static string GenerarContrasenaTemporal(int longitud)
        {
            const string mayusculas = "ABCDEFGHJKLMNPQRSTUVWXYZ";
            const string minusculas = "abcdefghijkmnpqrstuvwxyz";
            const string numeros = "23456789";
            const string simbolos = "#$%&*+-=?@";
            string todos = mayusculas + minusculas + numeros + simbolos;

            var caracteres = new List<char>
            {
                mayusculas[RandomNumberGenerator.GetInt32(mayusculas.Length)],
                minusculas[RandomNumberGenerator.GetInt32(minusculas.Length)],
                numeros[RandomNumberGenerator.GetInt32(numeros.Length)],
                simbolos[RandomNumberGenerator.GetInt32(simbolos.Length)]
            };

            while (caracteres.Count < longitud)
            {
                caracteres.Add(todos[RandomNumberGenerator.GetInt32(todos.Length)]);
            }

            // Mezcla (Fisher-Yates) con generador seguro
            for (int i = caracteres.Count - 1; i > 0; i--)
            {
                int j = RandomNumberGenerator.GetInt32(i + 1);
                (caracteres[i], caracteres[j]) = (caracteres[j], caracteres[i]);
            }

            return new string(caracteres.ToArray());
        }
    }
}
