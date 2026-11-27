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
    [Authorize(Roles = Roles.Administradores + "," + Roles.JefeArea)]
    public class ReportesController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly AlcanceUsuarioService _alcance;
        private readonly TaskPredictionService _prediccion;

        public ReportesController(ApplicationDbContext context,
            AlcanceUsuarioService alcance, TaskPredictionService prediccion)
        {
            _context = context;
            _alcance = alcance;
            _prediccion = prediccion;
        }

        public async Task<IActionResult> Index(AreaProyecto? area, EstadoProyecto? estadoProyecto,
            EstadoTarea? estadoTarea)
        {
            var alcance = await _alcance.ObtenerAsync(User);
            if (!alcance.EsAdministrador && !alcance.Area.HasValue) return Forbid();

            // Un jefe siempre consulta exclusivamente su área.
            if (alcance.EsJefeArea) area = alcance.Area;
            if (area.HasValue && !Enum.IsDefined(typeof(AreaProyecto), area.Value)) return BadRequest();
            if (estadoProyecto.HasValue && !Enum.IsDefined(typeof(EstadoProyecto), estadoProyecto.Value)) return BadRequest();
            if (estadoTarea.HasValue && !Enum.IsDefined(typeof(EstadoTarea), estadoTarea.Value)) return BadRequest();

            var proyectosConsulta = _context.Proyectos.AsNoTracking().AsQueryable();
            if (area.HasValue) proyectosConsulta = proyectosConsulta.Where(p => p.Area == area.Value);
            if (estadoProyecto.HasValue) proyectosConsulta = proyectosConsulta.Where(p => p.Estado == estadoProyecto.Value);
            var proyectos = await proyectosConsulta.OrderBy(p => p.Nombre).ToListAsync();

            var tareasConsulta = _context.Tareas.AsNoTracking().Include(t => t.Proyecto).AsQueryable();
            if (area.HasValue) tareasConsulta = tareasConsulta.Where(t => t.Proyecto != null && t.Proyecto.Area == area.Value);
            if (estadoProyecto.HasValue) tareasConsulta = tareasConsulta.Where(t => t.Proyecto != null && t.Proyecto.Estado == estadoProyecto.Value);
            if (estadoTarea.HasValue) tareasConsulta = tareasConsulta.Where(t => t.Estado == estadoTarea.Value);
            var tareas = await tareasConsulta.OrderBy(t => t.ProyectoId).ThenBy(t => t.Codigo).ToListAsync();

            var activas = tareas.Where(t => t.Estado != EstadoTarea.Finalizada).ToList();
            var predicciones = _prediccion.Predecir(activas);
            var riesgos = activas.Where(t => predicciones.TryGetValue(t.Id, out var p) &&
                p.Riesgo == NivelRiesgo.Alto).ToList();

            ViewBag.Area = area;
            ViewBag.EstadoProyecto = estadoProyecto;
            ViewBag.EstadoTarea = estadoTarea;
            ViewBag.EsAdministrador = alcance.EsAdministrador;
            ViewBag.Proyectos = proyectos;
            ViewBag.Tareas = tareas;
            ViewBag.Riesgos = riesgos;
            ViewBag.TotalProyectos = proyectos.Count;
            ViewBag.ProyectosPendientes = proyectos.Count(p => p.Estado == EstadoProyecto.Pendiente);
            ViewBag.ProyectosEnEjecucion = proyectos.Count(p => p.Estado == EstadoProyecto.EnEjecucion);
            ViewBag.ProyectosFinalizados = proyectos.Count(p => p.Estado == EstadoProyecto.Finalizado);
            ViewBag.TareasPendientes = tareas.Count(t => t.Estado == EstadoTarea.Pendiente);
            ViewBag.TareasEnEjecucion = tareas.Count(t => t.Estado == EstadoTarea.EnEjecucion);
            ViewBag.TareasFinalizadas = tareas.Count(t => t.Estado == EstadoTarea.Finalizada);
            ViewBag.ModeloDemostrativo = _prediccion.ModoDemostrativo;
            return View();
        }
    }
}
