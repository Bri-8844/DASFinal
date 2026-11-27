
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Controllers
{
    [Authorize(Roles = Roles.Administradores + "," + Roles.JefeArea)]
    public class ProyectosController : Controller
    {
        private const string CamposFormulario =
            "Id,Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega";

        private readonly ApplicationDbContext _context;
        private readonly ILogger<ProyectosController> _logger;
        private readonly AlcanceUsuarioService _alcance;

        public ProyectosController(
            ApplicationDbContext context,
            ILogger<ProyectosController> logger,
            AlcanceUsuarioService alcance)
        {
            _context = context;
            _logger = logger;
            _alcance = alcance;
        }

        // Listar proyectos (filtro opcional por área)
        public async Task<IActionResult> Index(AreaProyecto? area)
        {
            var alcance = await _alcance.ObtenerAsync(User);
            var consulta = _context.Proyectos.AsNoTracking();

            if (!alcance.EsAdministrador)
            {
                if (!alcance.Area.HasValue) return Forbid();
                consulta = consulta.Where(p => p.Area == alcance.Area.Value);
                area = alcance.Area;
            }

            if (area.HasValue)
            {
                if (!Enum.IsDefined(typeof(AreaProyecto), area.Value))
                {
                    return BadRequest("Área de proyecto no válida.");
                }

                consulta = consulta.Where(p => p.Area == area.Value);
            }

            var proyectos = await consulta
                .OrderByDescending(p => p.FechaRegistro)
                .ToListAsync();

            // Cantidad de tareas por proyecto (para el listado)
            var ids = proyectos.Select(p => p.Id).ToList();

            ViewBag.TareasPorProyecto = await _context.Tareas
                .Where(t => ids.Contains(t.ProyectoId))
                .GroupBy(t => t.ProyectoId)
                .Select(g => new { g.Key, Total = g.Count() })
                .ToDictionaryAsync(x => x.Key, x => x.Total);

            ViewBag.AreaSeleccionada = area;

            return View(proyectos);
        }

        // Mostrar detalles de un proyecto
        [HttpGet]
        public async Task<IActionResult> Details(int id)
        {
            var proyecto = await _context.Proyectos
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id);

            if (proyecto == null) return NotFound();
            var alcance = await _alcance.ObtenerAsync(User);
            if (!alcance.PuedeUsarProyecto(proyecto)) return Forbid();

            ViewBag.Tareas = await _context.Tareas
                .AsNoTracking()
                .Where(t => t.ProyectoId == id)
                .OrderBy(t => t.FechaLimite)
                .ToListAsync();

            return View(proyecto);
        }

        // Mostrar formulario de registro
        [Authorize(Roles = Roles.Administradores)]
        [HttpGet]
        public IActionResult Create()
        {
            return View(new Proyecto());
        }

        // Guardar proyecto en SQL Server
        [Authorize(Roles = Roles.Administradores)]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            [Bind(CamposFormulario)] Proyecto proyecto)
        {
            await ValidarProyectoAsync(proyecto, idActual: null);

            if (!ModelState.IsValid)
            {
                return View(proyecto);
            }

            proyecto.Id = 0;
            proyecto.FechaRegistro = DateTime.UtcNow;

            _context.Proyectos.Add(proyecto);
            await _context.SaveChangesAsync();

            TempData["Mensaje"] =
                $"Proyecto {proyecto.Codigo} registrado correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // Mostrar formulario de edición
        [Authorize(Roles = Roles.Administradores)]
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var proyecto = await _context.Proyectos
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id);

            if (proyecto == null)
            {
                return NotFound();
            }

            return View(proyecto);
        }

        // Guardar cambios del proyecto
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(
            int id,
            [Bind(CamposFormulario)] Proyecto datos)
        {
            if (id != datos.Id)
            {
                return BadRequest();
            }

            var proyecto = await _context.Proyectos
                .FindAsync(id);

            if (proyecto == null)
            {
                return NotFound();
            }

            await ValidarProyectoAsync(datos, idActual: id);

            if (!ModelState.IsValid)
            {
                // Se conserva la fecha de registro original para la vista
                datos.FechaRegistro = proyecto.FechaRegistro;
                return View(datos);
            }

            proyecto.Codigo = datos.Codigo;
            proyecto.Nombre = datos.Nombre;
            proyecto.Descripcion = datos.Descripcion;
            proyecto.Area = datos.Area;
            proyecto.Estado = datos.Estado;
            proyecto.FechaInicio = datos.FechaInicio;
            proyecto.FechaEntrega = datos.FechaEntrega;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Error al actualizar el proyecto {ProyectoId}.", id);

                ModelState.AddModelError("",
                    "No se pudieron guardar los cambios. Verifique que el código no esté duplicado.");

                return View(datos);
            }

            TempData["Mensaje"] = "Proyecto actualizado correctamente.";

            return RedirectToAction(nameof(Details), new { id = proyecto.Id });
        }

        // Eliminar proyecto (solo si no tiene tareas asociadas)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var proyecto = await _context.Proyectos.FindAsync(id);

            if (proyecto == null)
            {
                return NotFound();
            }

            int tareas = await _context.Tareas.CountAsync(t => t.ProyectoId == id);

            if (tareas > 0)
            {
                TempData["MensajeError"] =
                    $"No se puede eliminar el proyecto {proyecto.Codigo} porque tiene " +
                    $"{tareas} tarea(s) asociada(s). Elimine o reasigne primero sus tareas.";

                return RedirectToAction(nameof(Details), new { id });
            }

            _context.Proyectos.Remove(proyecto);
            await _context.SaveChangesAsync();

            TempData["Mensaje"] = $"Proyecto {proyecto.Codigo} eliminado correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // Validaciones compartidas por Create y Edit
        private async Task ValidarProyectoAsync(Proyecto proyecto, int? idActual)
        {
            proyecto.Codigo = proyecto.Codigo?.Trim().ToUpperInvariant() ?? string.Empty;
            proyecto.Nombre = proyecto.Nombre?.Trim() ?? string.Empty;
            proyecto.Descripcion = string.IsNullOrWhiteSpace(proyecto.Descripcion)
                ? null
                : proyecto.Descripcion.Trim();

            if (!Enum.IsDefined(typeof(AreaProyecto), proyecto.Area))
            {
                ModelState.AddModelError(nameof(Proyecto.Area),
                    "Seleccione un área válida.");
            }

            if (!Enum.IsDefined(typeof(EstadoProyecto), proyecto.Estado))
            {
                ModelState.AddModelError(nameof(Proyecto.Estado),
                    "Seleccione un estado válido.");
            }

            if (proyecto.FechaInicio.HasValue &&
                proyecto.FechaEntrega.HasValue &&
                proyecto.FechaEntrega.Value.Date < proyecto.FechaInicio.Value.Date)
            {
                ModelState.AddModelError(nameof(Proyecto.FechaEntrega),
                    "La fecha de entrega no puede ser anterior al inicio.");
            }

            if (!string.IsNullOrEmpty(proyecto.Codigo))
            {
                int id = idActual ?? 0;

                bool duplicado = await _context.Proyectos
                    .AnyAsync(p => p.Codigo == proyecto.Codigo && p.Id != id);

                if (duplicado)
                {
                    ModelState.AddModelError(nameof(Proyecto.Codigo),
                        "Ya existe otro proyecto con ese código.");
                }
            }
        }
    }
}
