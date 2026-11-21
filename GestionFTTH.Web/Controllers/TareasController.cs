
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Models.MachineLearning;
using GestionFTTH.Web.Services;
using GestionFTTH.Web.Services.MachineLearning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Controllers
{
    [Authorize(Roles = Roles.Todos)]
    public class TareasController : Controller
    {
        private const string CamposFormulario =
            "Id,Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad," +
            "FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance";

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly AlcanceUsuarioService _alcanceService;
        private readonly TaskPredictionService _prediccion;
        private readonly ILogger<TareasController> _logger;

        public TareasController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            AlcanceUsuarioService alcanceService,
            TaskPredictionService prediccion,
            ILogger<TareasController> logger)
        {
            _context = context;
            _userManager = userManager;
            _alcanceService = alcanceService;
            _prediccion = prediccion;
            _logger = logger;
        }

        private const int TamanoPagina = 25;

        // GET: Tareas  (filtro opcional: riesgo-alto | activas | finalizadas; paginado)
        public async Task<IActionResult> Index(string? filtro, int pagina = 1)
        {
            var alcance = await _alcanceService.ObtenerAsync(User);

            var consulta = alcance.Filtrar(
                _context.Tareas
                    .AsNoTracking()
                    .Include(t => t.Proyecto));

            if (filtro == "activas" || filtro == "riesgo-alto")
            {
                consulta = consulta.Where(t => t.Estado != EstadoTarea.Finalizada);
            }
            else if (filtro == "finalizadas")
            {
                consulta = consulta.Where(t => t.Estado == EstadoTarea.Finalizada);
            }

            var tareas = await consulta
                .OrderByDescending(t => t.FechaRegistro)
                .ThenByDescending(t => t.Id)
                .ToListAsync();

            // Predicción ML.NET con los datos actuales de cada tarea
            // (es rápida; el filtro de riesgo alto la necesita para todas)
            var predicciones = _prediccion.Predecir(tareas);

            if (filtro == "riesgo-alto")
            {
                tareas = tareas
                    .Where(t => predicciones[t.Id].Riesgo == NivelRiesgo.Alto)
                    .ToList();
            }

            // Paginación (evita páginas pesadas con muchos registros)
            int totalRegistros = tareas.Count;
            int totalPaginas = Math.Max(1, (int)Math.Ceiling(totalRegistros / (double)TamanoPagina));
            pagina = Math.Clamp(pagina, 1, totalPaginas);

            tareas = tareas
                .Skip((pagina - 1) * TamanoPagina)
                .Take(TamanoPagina)
                .ToList();

            if (alcance.EsJefeArea && !alcance.Area.HasValue)
            {
                TempData["MensajeError"] =
                    "Su cuenta de jefe de área no tiene un trabajador vinculado. " +
                    "Solicite al administrador que lo vincule para ver las tareas de su área.";
            }

            var modelo = new TareasIndexViewModel
            {
                Tareas = tareas,
                Predicciones = predicciones,
                NombresResponsables = await _alcanceService.NombresUsuariosAsync(
                    tareas.Where(t => t.ResponsableId != null).Select(t => t.ResponsableId!)),
                PuedeGestionar = alcance.PuedeGestionarTareas,
                ModeloDisponible = _prediccion.ModeloDisponible,
                EstadoModelo = _prediccion.EstadoModelo,
                ModoDemostrativo = _prediccion.ModoDemostrativo,
                UmbralRiesgoPorcentaje = (int)Math.Round(_prediccion.UmbralRiesgoAlto * 100),
                Filtro = filtro,
                Pagina = pagina,
                TotalPaginas = totalPaginas,
                TotalRegistros = totalRegistros,
                TamanoPagina = TamanoPagina,
                TituloAlcance = alcance.EsAdministrador
                    ? "Todas las tareas"
                    : alcance.EsJefeArea
                        ? (alcance.Area.HasValue
                            ? $"Tareas del área de {NombresVisibles.Area(alcance.Area.Value)}"
                            : "Sin área asignada")
                        : "Mis tareas asignadas"
            };

            return View(modelo);
        }

        // GET: Tareas/Details/5
        [HttpGet]
        public async Task<IActionResult> Details(int id)
        {
            var tarea = await _context.Tareas
                .AsNoTracking()
                .Include(t => t.Proyecto)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tarea == null)
            {
                return NotFound();
            }

            var alcance = await _alcanceService.ObtenerAsync(User);

            if (!alcance.PuedeVer(tarea))
            {
                return Forbid();
            }

            var avances = await _context.TareaAvances
                .AsNoTracking()
                .Where(a => a.TareaId == id)
                .OrderByDescending(a => a.Fecha)
                .ThenByDescending(a => a.Id)
                .ToListAsync();

            var nombres = await _alcanceService.NombresUsuariosAsync(
                tarea.ResponsableId != null
                    ? new[] { tarea.ResponsableId }
                    : Array.Empty<string>());

            var modelo = new TareaDetalleViewModel
            {
                Tarea = tarea,
                Prediccion = _prediccion.PredecirUna(tarea),
                NombreResponsable = tarea.ResponsableId != null &&
                    nombres.TryGetValue(tarea.ResponsableId, out var nombre)
                        ? nombre
                        : "Sin asignar",
                Avances = avances,
                PuedeGestionar = alcance.PuedeGestionar(tarea),
                PuedeActualizarAvance = alcance.PuedeVer(tarea),
                UmbralRiesgoPorcentaje = (int)Math.Round(_prediccion.UmbralRiesgoAlto * 100)
            };

            return View(modelo);
        }

        // GET: Tareas/Create
        [HttpGet]
        [Authorize(Roles = Roles.GestoresTareas)]
        public async Task<IActionResult> Create()
        {
            var alcance = await _alcanceService.ObtenerAsync(User);

            await CargarListasAsync(alcance);

            return View(new Tarea
            {
                FechaInicio = DateTime.Today
            });
        }

        // POST: Tareas/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = Roles.GestoresTareas)]
        public async Task<IActionResult> Create(
            [Bind(CamposFormulario)] Tarea tarea)
        {
            var alcance = await _alcanceService.ObtenerAsync(User);

            await ValidarTareaAsync(tarea, alcance, idActual: null);

            if (!ModelState.IsValid)
            {
                await CargarListasAsync(alcance);
                return View(tarea);
            }

            tarea.Id = 0;
            tarea.Titulo = tarea.Titulo.Trim();
            tarea.Descripcion = tarea.Descripcion?.Trim();
            tarea.FechaInicio = tarea.FechaInicio?.Date;
            tarea.FechaLimite = tarea.FechaLimite?.Date;
            tarea.FechaRegistro = DateTime.UtcNow;
            AplicarReglasDeEstado(tarea);

            // Primer registro del historial de avance (se guarda junto con la tarea)
            await RegistrarAvanceAsync(tarea);

            _context.Tareas.Add(tarea);
            await _context.SaveChangesAsync();

            TempData["MensajeExito"] = $"La tarea {tarea.Codigo} se registró correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // GET: Tareas/Edit/5
        [HttpGet]
        [Authorize(Roles = Roles.GestoresTareas)]
        public async Task<IActionResult> Edit(int id)
        {
            var tarea = await _context.Tareas
                .AsNoTracking()
                .Include(t => t.Proyecto)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tarea == null)
            {
                return NotFound();
            }

            var alcance = await _alcanceService.ObtenerAsync(User);

            if (!alcance.PuedeGestionar(tarea))
            {
                return Forbid();
            }

            await CargarListasAsync(alcance, tarea.ResponsableId);

            return View(tarea);
        }

        // POST: Tareas/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = Roles.GestoresTareas)]
        public async Task<IActionResult> Edit(
            int id,
            [Bind(CamposFormulario)] Tarea datos)
        {
            if (id != datos.Id)
            {
                return BadRequest();
            }

            var tarea = await _context.Tareas
                .Include(t => t.Proyecto)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tarea == null)
            {
                return NotFound();
            }

            var alcance = await _alcanceService.ObtenerAsync(User);

            if (!alcance.PuedeGestionar(tarea))
            {
                return Forbid();
            }

            await ValidarTareaAsync(datos, alcance, idActual: id,
                responsableActual: tarea.ResponsableId);

            if (!ModelState.IsValid)
            {
                await CargarListasAsync(alcance, tarea.ResponsableId);
                return View(datos);
            }

            bool cambioSeguimiento =
                tarea.PorcentajeAvance != datos.PorcentajeAvance ||
                tarea.Estado != datos.Estado;

            tarea.Codigo = datos.Codigo;
            tarea.Titulo = datos.Titulo.Trim();
            tarea.Descripcion = datos.Descripcion?.Trim();
            tarea.ProyectoId = datos.ProyectoId;
            tarea.ResponsableId = datos.ResponsableId;
            tarea.Estado = datos.Estado;
            tarea.Prioridad = datos.Prioridad;
            tarea.FechaInicio = datos.FechaInicio?.Date;
            tarea.FechaLimite = datos.FechaLimite?.Date;
            tarea.FechaFinalizacion = datos.FechaFinalizacion?.Date;
            tarea.PorcentajeAvance = datos.PorcentajeAvance;

            AplicarReglasDeEstado(tarea);

            if (cambioSeguimiento)
            {
                await RegistrarAvanceAsync(tarea);
            }

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Error al actualizar la tarea {TareaId}.", id);

                ModelState.AddModelError("",
                    "No se pudieron guardar los cambios. Verifique que el código no esté duplicado.");

                await CargarListasAsync(alcance, tarea.ResponsableId);
                return View(datos);
            }

            TempData["MensajeExito"] = "La tarea se actualizó correctamente.";

            return RedirectToAction(nameof(Details), new { id });
        }

        // POST: Tareas/ActualizarAvance (responsable, jefe de área o administrador)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ActualizarAvance(ActualizarAvanceViewModel modelo)
        {
            var tarea = await _context.Tareas
                .Include(t => t.Proyecto)
                .FirstOrDefaultAsync(t => t.Id == modelo.Id);

            if (tarea == null)
            {
                return NotFound();
            }

            var alcance = await _alcanceService.ObtenerAsync(User);

            if (!alcance.PuedeVer(tarea))
            {
                return Forbid();
            }

            if (!ModelState.IsValid ||
                modelo.PorcentajeAvance < 0 || modelo.PorcentajeAvance > 100)
            {
                TempData["MensajeError"] = "El avance debe ser un número entre 0 y 100.";
                return RedirectToAction(nameof(Details), new { id = modelo.Id });
            }

            if (!Enum.IsDefined(typeof(EstadoTarea), modelo.Estado))
            {
                TempData["MensajeError"] = "Seleccione un estado válido.";
                return RedirectToAction(nameof(Details), new { id = modelo.Id });
            }

            // Reabrir una tarea finalizada borra su fecha real de cierre
            // (etiqueta histórica del modelo ML): solo jefe de área o administrador.
            if (tarea.Estado == EstadoTarea.Finalizada &&
                modelo.Estado != EstadoTarea.Finalizada &&
                !alcance.PuedeGestionar(tarea))
            {
                TempData["MensajeError"] =
                    "Solo el jefe de área o un administrador puede reabrir una tarea finalizada.";
                return RedirectToAction(nameof(Details), new { id = modelo.Id });
            }

            if (tarea.PorcentajeAvance == modelo.PorcentajeAvance &&
                tarea.Estado == modelo.Estado)
            {
                TempData["MensajeExito"] = "No hubo cambios en el avance de la tarea.";
                return RedirectToAction(nameof(Details), new { id = modelo.Id });
            }

            tarea.PorcentajeAvance = modelo.PorcentajeAvance;
            tarea.Estado = modelo.Estado;

            AplicarReglasDeEstado(tarea);
            await RegistrarAvanceAsync(tarea);
            await _context.SaveChangesAsync();

            TempData["MensajeExito"] = "El avance de la tarea se actualizó correctamente.";

            return RedirectToAction(nameof(Details), new { id = modelo.Id });
        }

        // POST: Tareas/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = Roles.GestoresTareas)]
        public async Task<IActionResult> Delete(int id)
        {
            var tarea = await _context.Tareas
                .Include(t => t.Proyecto)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tarea == null)
            {
                return NotFound();
            }

            var alcance = await _alcanceService.ObtenerAsync(User);

            if (!alcance.PuedeGestionar(tarea))
            {
                return Forbid();
            }

            _context.Tareas.Remove(tarea);
            await _context.SaveChangesAsync();

            TempData["MensajeExito"] = $"La tarea {tarea.Codigo} se eliminó correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // ===================== Reglas de negocio =====================

        private async Task ValidarTareaAsync(
            Tarea tarea,
            AlcanceUsuario alcance,
            int? idActual,
            string? responsableActual = null)
        {
            // Proyecto
            var proyecto = await _context.Proyectos
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == tarea.ProyectoId);

            if (proyecto == null)
            {
                ModelState.AddModelError(nameof(Tarea.ProyectoId),
                    "Seleccione un proyecto válido.");
            }
            else if (!alcance.PuedeUsarProyecto(proyecto))
            {
                ModelState.AddModelError(nameof(Tarea.ProyectoId),
                    "Solo puede registrar tareas en proyectos de su área.");
            }

            // Responsable: usuario con rol Trabajador (se conserva el actual si no cambia)
            if (string.IsNullOrWhiteSpace(tarea.ResponsableId))
            {
                ModelState.AddModelError(nameof(Tarea.ResponsableId),
                    "Seleccione un responsable.");
            }
            else if (tarea.ResponsableId != responsableActual)
            {
                var responsable = await _userManager.Users
                    .Include(u => u.Trabajador)
                    .FirstOrDefaultAsync(u => u.Id == tarea.ResponsableId);

                if (responsable == null ||
                    !await _userManager.IsInRoleAsync(responsable, Roles.Trabajador))
                {
                    ModelState.AddModelError(nameof(Tarea.ResponsableId),
                        "Seleccione un trabajador válido.");
                }
                else if (alcance.EsJefeArea &&
                         responsable.Trabajador?.Area != alcance.Area)
                {
                    ModelState.AddModelError(nameof(Tarea.ResponsableId),
                        "El responsable debe pertenecer a su área.");
                }
            }

            // Código único (normalizado)
            if (!string.IsNullOrWhiteSpace(tarea.Codigo))
            {
                tarea.Codigo = tarea.Codigo.Trim().ToUpperInvariant();

                int id = idActual ?? 0;

                bool codigoExiste = await _context.Tareas
                    .AnyAsync(t => t.Codigo == tarea.Codigo && t.Id != id);

                if (codigoExiste)
                {
                    ModelState.AddModelError(nameof(Tarea.Codigo),
                        "Ya existe una tarea con este código.");
                }
            }

            // Fechas (necesarias para el seguimiento y la predicción)
            if (!tarea.FechaInicio.HasValue)
            {
                ModelState.AddModelError(nameof(Tarea.FechaInicio),
                    "Ingrese la fecha de inicio.");
            }

            if (!tarea.FechaLimite.HasValue)
            {
                ModelState.AddModelError(nameof(Tarea.FechaLimite),
                    "Ingrese la fecha límite.");
            }

            if (tarea.FechaInicio.HasValue &&
                tarea.FechaLimite.HasValue &&
                tarea.FechaLimite.Value.Date < tarea.FechaInicio.Value.Date)
            {
                ModelState.AddModelError(nameof(Tarea.FechaLimite),
                    "La fecha límite no puede ser anterior a la fecha de inicio.");
            }

            if (tarea.Estado == EstadoTarea.Finalizada && tarea.FechaFinalizacion.HasValue)
            {
                if (tarea.FechaFinalizacion.Value.Date > DateTime.Today)
                {
                    ModelState.AddModelError(nameof(Tarea.FechaFinalizacion),
                        "La fecha de finalización no puede ser futura.");
                }

                if (tarea.FechaInicio.HasValue &&
                    tarea.FechaFinalizacion.Value.Date < tarea.FechaInicio.Value.Date)
                {
                    ModelState.AddModelError(nameof(Tarea.FechaFinalizacion),
                        "La fecha de finalización no puede ser anterior al inicio.");
                }
            }

            // Estado y prioridad
            if (!Enum.IsDefined(typeof(EstadoTarea), tarea.Estado))
            {
                ModelState.AddModelError(nameof(Tarea.Estado),
                    "Seleccione un estado válido.");
            }

            if (!Enum.IsDefined(typeof(PrioridadTarea), tarea.Prioridad))
            {
                ModelState.AddModelError(nameof(Tarea.Prioridad),
                    "Seleccione una prioridad válida.");
            }
        }

        /// <summary>
        /// Una tarea finalizada queda al 100 % y con su fecha real de finalización;
        /// si se reabre, se limpia la fecha de finalización.
        /// </summary>
        private static void AplicarReglasDeEstado(Tarea tarea)
        {
            if (tarea.Estado == EstadoTarea.Finalizada)
            {
                tarea.PorcentajeAvance = 100;
                tarea.FechaFinalizacion = (tarea.FechaFinalizacion ?? DateTime.Today).Date;
            }
            else
            {
                tarea.FechaFinalizacion = null;
            }
        }

        /// <summary>
        /// Guarda el avance del día en el historial (un registro por tarea y día).
        /// Este historial es el que usa ML.NET para entrenar sin data leakage.
        /// </summary>
        private async Task RegistrarAvanceAsync(Tarea tarea)
        {
            var hoy = DateTime.Today;
            var usuarioId = _userManager.GetUserId(User);

            var existente = tarea.Id == 0
                ? null
                : await _context.TareaAvances
                    .FirstOrDefaultAsync(a => a.TareaId == tarea.Id && a.Fecha == hoy);

            var registro = existente ?? new TareaAvance { Fecha = hoy };

            registro.PorcentajeAvance = tarea.PorcentajeAvance;
            registro.Estado = tarea.Estado;
            registro.Prioridad = tarea.Prioridad;
            registro.FechaInicioPlan = tarea.FechaInicio?.Date;
            registro.FechaLimitePlan = tarea.FechaLimite?.Date;
            registro.RegistradoPorId = usuarioId;

            if (existente == null)
            {
                tarea.Avances.Add(registro);
            }
        }

        // Cargar proyectos y trabajadores disponibles según el alcance
        private async Task CargarListasAsync(
            AlcanceUsuario alcance,
            string? responsableActual = null)
        {
            var proyectos = _context.Proyectos.AsNoTracking();

            if (!alcance.EsAdministrador)
            {
                proyectos = alcance.Area.HasValue
                    ? proyectos.Where(p => p.Area == alcance.Area.Value)
                    : proyectos.Where(p => false);
            }

            ViewBag.Proyectos = await proyectos
                .OrderBy(p => p.Codigo)
                .ToListAsync();

            var idsTrabajadores = (await _userManager.GetUsersInRoleAsync(Roles.Trabajador))
                .Select(u => u.Id)
                .ToList();

            var usuarios = await _context.Users
                .AsNoTracking()
                .Include(u => u.Trabajador)
                .Where(u => idsTrabajadores.Contains(u.Id) || u.Id == responsableActual)
                .ToListAsync();

            if (alcance.EsJefeArea)
            {
                usuarios = usuarios
                    .Where(u => u.Trabajador?.Area == alcance.Area || u.Id == responsableActual)
                    .ToList();
            }

            ViewBag.Trabajadores = usuarios
                .OrderBy(u => u.Trabajador?.Apellidos ?? u.UserName)
                .ToList();
        }
    }
}
