
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Models.MachineLearning;
using GestionFTTH.Web.Services;
using GestionFTTH.Web.Services.MachineLearning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Controllers
{
    [Authorize(Roles = Roles.Administradores)]
    public class DashboardController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly TaskPredictionService _prediccion;

        public DashboardController(
            ApplicationDbContext context,
            TaskPredictionService prediccion)
        {
            _context = context;
            _prediccion = prediccion;
        }

        public async Task<IActionResult> Index()
        {
            // Indicadores de proyectos en una sola consulta
            var proyectos = await _context.Proyectos
                .AsNoTracking()
                .Select(p => new { p.Estado, p.Area })
                .ToListAsync();

            ViewBag.TotalProyectos = proyectos.Count;
            ViewBag.EnEjecucion = proyectos.Count(p => p.Estado == EstadoProyecto.EnEjecucion);
            ViewBag.Finalizados = proyectos.Count(p => p.Estado == EstadoProyecto.Finalizado);
            ViewBag.Pendientes = proyectos.Count(p => p.Estado == EstadoProyecto.Pendiente);

            ViewBag.TotalPrediseno = proyectos.Count(p => p.Area == AreaProyecto.Prediseño);
            ViewBag.TotalDiseno = proyectos.Count(p => p.Area == AreaProyecto.Diseño);
            ViewBag.TotalConstruccion = proyectos.Count(p => p.Area == AreaProyecto.Construccion);

            // Indicadores de tareas + riesgo estimado por ML.NET
            var tareasActivas = await _context.Tareas
                .AsNoTracking()
                .Where(t => t.Estado != EstadoTarea.Finalizada)
                .ToListAsync();

            var predicciones = _prediccion.Predecir(tareasActivas);

            ViewBag.TareasActivas = tareasActivas.Count;
            ViewBag.TareasVencidas = tareasActivas.Count(t =>
                t.FechaLimite.HasValue && t.FechaLimite.Value.Date < DateTime.Today);
            ViewBag.TareasRiesgoAlto = predicciones.Values.Count(p => p.Riesgo == NivelRiesgo.Alto);
            ViewBag.TareasSinPrediccion = predicciones.Values.Count(p => !p.Disponible);
            ViewBag.ModeloDisponible = _prediccion.ModeloDisponible;
            ViewBag.ModoDemostrativo = _prediccion.ModoDemostrativo;

            return View();
        }
    }
}
