using System.Security.Claims;
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Services
{
    /// <summary>
    /// Determina qué tareas puede ver y gestionar el usuario actual:
    ///  - Administradores: todas.
    ///  - Jefe de área: tareas de proyectos de su área (según su trabajador vinculado).
    ///  - Trabajador: solo las tareas donde es responsable.
    /// </summary>
    public class AlcanceUsuario
    {
        public string UsuarioId { get; init; } = string.Empty;
        public bool EsAdministrador { get; init; }
        public bool EsJefeArea { get; init; }
        public bool EsTrabajador { get; init; }
        public AreaProyecto? Area { get; init; }

        public bool PuedeGestionarTareas => EsAdministrador || EsJefeArea;

        public IQueryable<Tarea> Filtrar(IQueryable<Tarea> consulta)
        {
            if (EsAdministrador)
            {
                return consulta;
            }

            if (EsJefeArea)
            {
                return Area.HasValue
                    ? consulta.Where(t => t.Proyecto!.Area == Area.Value)
                    : consulta.Where(t => false);
            }

            return consulta.Where(t => t.ResponsableId == UsuarioId);
        }

        public bool PuedeVer(Tarea tarea) =>
            EsAdministrador ||
            (EsJefeArea && Area.HasValue && tarea.Proyecto?.Area == Area) ||
            tarea.ResponsableId == UsuarioId;

        public bool PuedeGestionar(Tarea tarea) =>
            EsAdministrador ||
            (EsJefeArea && Area.HasValue && tarea.Proyecto?.Area == Area);

        public bool PuedeUsarProyecto(Proyecto proyecto) =>
            EsAdministrador ||
            (EsJefeArea && Area.HasValue && proyecto.Area == Area);
    }

    public class AlcanceUsuarioService
    {
        private readonly ApplicationDbContext _context;

        public AlcanceUsuarioService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<AlcanceUsuario> ObtenerAsync(ClaimsPrincipal usuario)
        {
            var usuarioId = usuario.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;

            bool esAdmin =
                usuario.IsInRole(Roles.AdministradorPrincipal) ||
                usuario.IsInRole(Roles.AdministradorGerencia);

            bool esJefe = !esAdmin && usuario.IsInRole(Roles.JefeArea);

            AreaProyecto? area = null;

            if (esJefe)
            {
                area = await _context.Users
                    .Where(u => u.Id == usuarioId && u.TrabajadorId != null)
                    .Select(u => (AreaProyecto?)u.Trabajador!.Area)
                    .FirstOrDefaultAsync();
            }

            return new AlcanceUsuario
            {
                UsuarioId = usuarioId,
                EsAdministrador = esAdmin,
                EsJefeArea = esJefe,
                EsTrabajador = !esAdmin && !esJefe && usuario.IsInRole(Roles.Trabajador),
                Area = area
            };
        }

        /// <summary>
        /// Nombre visible de los usuarios: "Nombres Apellidos" del trabajador
        /// vinculado o, si no tiene, su correo.
        /// </summary>
        public async Task<Dictionary<string, string>> NombresUsuariosAsync(
            IEnumerable<string> ids)
        {
            var lista = ids.Distinct().ToList();

            if (lista.Count == 0)
            {
                return new Dictionary<string, string>();
            }

            var usuarios = await _context.Users
                .AsNoTracking()
                .Where(u => lista.Contains(u.Id))
                .Select(u => new
                {
                    u.Id,
                    u.UserName,
                    Nombres = u.Trabajador != null ? u.Trabajador.Nombres : null,
                    Apellidos = u.Trabajador != null ? u.Trabajador.Apellidos : null
                })
                .ToListAsync();

            return usuarios.ToDictionary(
                u => u.Id,
                u => u.Nombres != null
                    ? $"{u.Nombres} {u.Apellidos}"
                    : u.UserName ?? "Sin nombre");
        }
    }
}
