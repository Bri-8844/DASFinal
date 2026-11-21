using Microsoft.Extensions.Options;

namespace GestionFTTH.Web.Services.MachineLearning
{
    /// <summary>
    /// Proceso de inicialización explícito: si al iniciar la aplicación no existe
    /// un modelo entrenado, lo entrena UNA vez en segundo plano (sin bloquear el
    /// arranque ni las consultas del módulo de tareas). Nunca se entrena al abrir vistas.
    /// </summary>
    public class ModeloInicializador : BackgroundService
    {
        private readonly TaskModelTrainer _trainer;
        private readonly MachineLearningOptions _opciones;
        private readonly ILogger<ModeloInicializador> _logger;

        public ModeloInicializador(
            TaskModelTrainer trainer,
            IOptions<MachineLearningOptions> opciones,
            ILogger<ModeloInicializador> logger)
        {
            _trainer = trainer;
            _opciones = opciones.Value;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (_trainer.ExisteModelo || !_opciones.EntrenarAlIniciarSiNoExiste)
            {
                return;
            }

            try
            {
                _logger.LogInformation(
                    "No existe un modelo ML.NET entrenado. Iniciando entrenamiento inicial.");

                var resultado = await _trainer.EntrenarAsync(
                    permitirDemoSobreReal: false,
                    cancellationToken: stoppingToken);

                _logger.LogInformation(
                    "Entrenamiento inicial ML.NET: {Mensaje}", resultado.Mensaje);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Falló el entrenamiento inicial del modelo ML.NET.");
            }
        }
    }
}
