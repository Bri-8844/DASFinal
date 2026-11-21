using GestionFTTH.Web.Services;
using GestionFTTH.Web.Services.MachineLearning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GestionFTTH.Web.Controllers
{
    /// <summary>
    /// Administración controlada del modelo ML.NET de riesgo de retraso:
    /// consulta de métricas y reentrenamiento (solo administradores).
    /// </summary>
    [Authorize(Roles = Roles.Administradores)]
    public class ModeloRiesgoController : Controller
    {
        private readonly TaskModelTrainer _trainer;
        private readonly TaskPredictionService _prediccion;

        public ModeloRiesgoController(
            TaskModelTrainer trainer,
            TaskPredictionService prediccion)
        {
            _trainer = trainer;
            _prediccion = prediccion;
        }

        // GET: ModeloRiesgo
        public IActionResult Index()
        {
            ViewBag.ModeloDisponible = _prediccion.ModeloDisponible;
            ViewBag.EstadoModelo = _prediccion.EstadoModelo;
            ViewBag.UmbralPorcentaje = (int)Math.Round(_prediccion.UmbralRiesgoAlto * 100);

            return View(_prediccion.InfoModelo);
        }

        // POST: ModeloRiesgo/Entrenar
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Entrenar(
            bool permitirDemoSobreReal,
            CancellationToken cancellationToken)
        {
            var resultado = await _trainer.EntrenarAsync(
                permitirDemoSobreReal, cancellationToken);

            TempData[resultado.Exito ? "MensajeExito" : "MensajeError"] = resultado.Mensaje;

            return RedirectToAction(nameof(Index));
        }
    }
}
