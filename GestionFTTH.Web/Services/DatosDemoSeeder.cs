using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Services;

// Crea cuentas de demostración solo cuando se solicita expresamente.
// Antes de ejecutarlo, importar el SQL de datos demo y configurar Demo:Password en user secrets.
public static class DatosDemoSeeder
{
    public static async Task EjecutarAsync(IServiceProvider services, IConfiguration config)
    {
        var password = config["Demo:Password"];
        if (string.IsNullOrWhiteSpace(password))
            throw new InvalidOperationException("Configure Demo:Password en user secrets antes de continuar.");

        var db = services.GetRequiredService<ApplicationDbContext>();
        var usuarios = services.GetRequiredService<UserManager<ApplicationUser>>();

        // Gerente sin trabajador asociado; los otros ocho usuarios sí tienen trabajador.
        var cuentas = new (string Correo, string Rol, string? Codigo)[]
        {
            ("gerencia.demo@gestionftth.test", Roles.AdministradorGerencia, null),
            ("jefe.pred.demo@gestionftth.test", Roles.JefeArea, "DEMO-TRB-001"),
            ("jefe.dis.demo@gestionftth.test", Roles.JefeArea, "DEMO-TRB-002"),
            ("jefe.cons.demo@gestionftth.test", Roles.JefeArea, "DEMO-TRB-003"),
            ("mateo.demo@gestionftth.test", Roles.Trabajador, "DEMO-TRB-004"),
            ("valeria.demo@gestionftth.test", Roles.Trabajador, "DEMO-TRB-005"),
            ("daniela.demo@gestionftth.test", Roles.Trabajador, "DEMO-TRB-009"),
            ("jorge.demo@gestionftth.test", Roles.Trabajador, "DEMO-TRB-010"),
            ("mariana.demo@gestionftth.test", Roles.Trabajador, "DEMO-TRB-015")
        };

        // Verificar primero que se importaron los trabajadores del script SQL.
        foreach (var cuenta in cuentas)
        {
            if (cuenta.Codigo != null &&
                !await db.Trabajadores.AnyAsync(t => t.Codigo == cuenta.Codigo))
                throw new InvalidOperationException($"Falta el trabajador {cuenta.Codigo}. Ejecute primero el SQL demo.");
        }

        foreach (var cuenta in cuentas)
        {
            var trabajador = cuenta.Codigo == null ? null :
                await db.Trabajadores.SingleAsync(t => t.Codigo == cuenta.Codigo);

            var usuario = await usuarios.FindByEmailAsync(cuenta.Correo);
            if (usuario == null)
            {
                usuario = new ApplicationUser
                {
                    UserName = cuenta.Correo,
                    Email = cuenta.Correo,
                    EmailConfirmed = true,
                    TrabajadorId = trabajador?.Id
                };

                var resultado = await usuarios.CreateAsync(usuario, password);
                if (!resultado.Succeeded)
                    throw new InvalidOperationException(
                        $"Error al crear {cuenta.Correo}: " +
                        string.Join("; ", resultado.Errors.Select(e => e.Description)));
            }
            else if (usuario.TrabajadorId != trabajador?.Id)
            {
                // No modificar una cuenta existente que pudiera pertenecer a otra persona.
                throw new InvalidOperationException($"La cuenta {cuenta.Correo} ya existe con otro trabajador.");
            }

            if (!await usuarios.IsInRoleAsync(usuario, cuenta.Rol))
            {
                var resultado = await usuarios.AddToRoleAsync(usuario, cuenta.Rol);
                if (!resultado.Succeeded)
                    throw new InvalidOperationException($"No se pudo asignar el rol a {cuenta.Correo}.");
            }
        }

        // Asignar solo tareas demo que todavía no tengan responsable.
        // Los responsables pertenecen siempre a la misma área del proyecto.
        var responsables = new Dictionary<AreaProyecto, string[]>
        {
            [AreaProyecto.Prediseño] = new[] { "DEMO-TRB-004", "DEMO-TRB-005" },
            [AreaProyecto.Diseño] = new[] { "DEMO-TRB-009", "DEMO-TRB-010" },
            [AreaProyecto.Construccion] = new[] { "DEMO-TRB-015" }
        };

        var tareas = await db.Tareas.Include(t => t.Proyecto)
            .Where(t => t.Codigo.StartsWith("DEMO-TAR-") && t.ResponsableId == null)
            .OrderBy(t => t.Codigo).ToListAsync();

        foreach (var tarea in tareas)
        {
            if (tarea.Proyecto == null || !tarea.Proyecto.Codigo.StartsWith("DEMO-PRY-"))
                continue;

            var codigos = responsables[tarea.Proyecto.Area];
            var numero = int.Parse(tarea.Codigo.Substring("DEMO-TAR-".Length));
            var codigo = codigos[(numero - 1) % codigos.Length];
            var trabajador = await db.Trabajadores.SingleAsync(t => t.Codigo == codigo);
            var responsable = await db.Users.SingleAsync(u => u.TrabajadorId == trabajador.Id);
            tarea.ResponsableId = responsable.Id;
        }

        await db.SaveChangesAsync();
        Console.WriteLine("Datos demo: cuentas y responsables procesados correctamente.");
    }
}
