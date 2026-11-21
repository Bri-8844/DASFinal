using System.Text.Json;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Models.MachineLearning;
using Microsoft.Extensions.Options;
using Microsoft.ML;

namespace GestionFTTH.Web.Services.MachineLearning
{
    /// <summary>
    /// Carga el modelo ML.NET guardado (MLModels/ModeloRetraso.zip) y genera
    /// predicciones de riesgo de retraso para tareas activas.
    ///
    /// Concurrencia: el ITransformer (modelo) es inmutable y seguro para hilos;
    /// PredictionEngine NO lo es, por eso se crea un motor local por cada
    /// llamada (por solicitud) y nunca se comparte entre solicitudes.
    /// </summary>
    public class TaskPredictionService
    {
        private readonly MLContext _ml = new();
        private readonly IWebHostEnvironment _env;
        private readonly MachineLearningOptions _opciones;
        private readonly ILogger<TaskPredictionService> _logger;
        private readonly object _sync = new();

        private ITransformer? _modelo;
        private ModeloInfo? _info;
        private string? _errorCarga;

        public TaskPredictionService(
            IWebHostEnvironment env,
            IOptions<MachineLearningOptions> opciones,
            ILogger<TaskPredictionService> logger)
        {
            _env = env;
            _opciones = opciones.Value;
            _logger = logger;

            RecargarModelo();
        }

        public float UmbralRiesgoAlto => _opciones.UmbralRiesgoAlto;

        public bool ModeloDisponible => _modelo != null;

        public ModeloInfo? InfoModelo => _info;

        public bool ModoDemostrativo => _info?.ModoDemostrativo ?? true;

        // Mensaje controlado (sin rutas físicas) cuando no hay modelo
        public string? EstadoModelo => _modelo != null
            ? null
            : _errorCarga ?? "El modelo de predicción aún no ha sido entrenado.";

        private string RutaModelo =>
            Path.Combine(_env.ContentRootPath, _opciones.RutaModelo);

        /// <summary>
        /// Carga (o vuelve a cargar) el modelo desde disco. Si falla,
        /// conserva el modelo que estaba en memoria.
        /// </summary>
        public void RecargarModelo()
        {
            lock (_sync)
            {
                try
                {
                    if (!File.Exists(RutaModelo))
                    {
                        _errorCarga = "El modelo de predicción aún no ha sido entrenado.";
                        _logger.LogWarning("No se encontró el modelo ML.NET entrenado.");
                        return;
                    }

                    ITransformer nuevo;

                    using (var stream = File.OpenRead(RutaModelo))
                    {
                        nuevo = _ml.Model.Load(stream, out _);
                    }

                    _modelo = nuevo;
                    _info = LeerInfo();
                    _errorCarga = null;

                    _logger.LogInformation("Modelo ML.NET de riesgo de retraso cargado.");
                }
                catch (Exception ex)
                {
                    _errorCarga = "No se pudo cargar el modelo de predicción.";
                    _logger.LogError(ex, "Error al cargar el modelo ML.NET.");
                }
            }
        }

        /// <summary>
        /// Predice el riesgo de un conjunto de tareas usando la fecha actual.
        /// </summary>
        public Dictionary<int, TaskPredictionResult> Predecir(
            IEnumerable<Tarea> tareas)
        {
            return Predecir(tareas, DateTime.Today);
        }

        public Dictionary<int, TaskPredictionResult> Predecir(
            IEnumerable<Tarea> tareas, DateTime hoy)
        {
            var resultados = new Dictionary<int, TaskPredictionResult>();
            var modelo = _modelo;

            // Motor local a esta llamada: no se comparte entre hilos
            PredictionEngine<TaskTrainingData, TaskPredictionOutput>? motor = null;

            try
            {
                foreach (var tarea in tareas)
                {
                    var (entrada, motivo) = ConstruirEntrada(tarea, hoy);

                    if (entrada == null)
                    {
                        resultados[tarea.Id] =
                            TaskPredictionResult.NoDisponible(tarea.Id, motivo!);
                        continue;
                    }

                    if (modelo == null)
                    {
                        var sinModelo = TaskPredictionResult.NoDisponible(
                            tarea.Id, EstadoModelo!);
                        CopiarEntrada(sinModelo, entrada);
                        resultados[tarea.Id] = sinModelo;
                        continue;
                    }

                    motor ??= _ml.Model.CreatePredictionEngine<TaskTrainingData, TaskPredictionOutput>(modelo);

                    var salida = motor.Predict(entrada);

                    resultados[tarea.Id] = Interpretar(tarea.Id, entrada, salida);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al generar predicciones ML.NET.");

                foreach (var tarea in tareas.Where(t => !resultados.ContainsKey(t.Id)))
                {
                    resultados[tarea.Id] = TaskPredictionResult.NoDisponible(
                        tarea.Id, "No se pudo generar la predicción.");
                }
            }
            finally
            {
                motor?.Dispose();
            }

            return resultados;
        }

        public TaskPredictionResult PredecirUna(Tarea tarea) =>
            Predecir(new[] { tarea })[tarea.Id];

        /// <summary>
        /// Valida la tarea y construye la entrada del modelo con la
        /// información disponible HOY (sin información futura).
        /// </summary>
        public static (TaskTrainingData? Entrada, string? Motivo) ConstruirEntrada(
            Tarea tarea, DateTime hoy)
        {
            if (tarea.Estado == EstadoTarea.Finalizada)
            {
                return (null, "La tarea ya está finalizada; no se predice su riesgo.");
            }

            if (!tarea.FechaInicio.HasValue || !tarea.FechaLimite.HasValue)
            {
                return (null, "Faltan la fecha de inicio o la fecha límite de la tarea.");
            }

            if (!Enum.IsDefined(typeof(PrioridadTarea), tarea.Prioridad))
            {
                return (null, "La prioridad de la tarea no es válida.");
            }

            if (tarea.PorcentajeAvance < 0 || tarea.PorcentajeAvance > 100)
            {
                return (null, "El porcentaje de avance está fuera del rango 0-100.");
            }

            var inicio = tarea.FechaInicio.Value.Date;
            var limite = tarea.FechaLimite.Value.Date;

            int duracion = (limite - inicio).Days;

            if (duracion <= 0)
            {
                return (null, "La duración planificada debe ser mayor a cero días.");
            }

            int transcurridos = (hoy.Date - inicio).Days;

            if (transcurridos < 0)
            {
                return (null, "La tarea aún no ha iniciado según su fecha de inicio.");
            }

            var entrada = TaskTrainingData.Crear(
                prioridad: tarea.Prioridad.ToString(),
                duracionPlanificada: duracion,
                porcentajeAvance: tarea.PorcentajeAvance,
                diasTranscurridos: transcurridos);

            return (entrada, null);
        }

        private TaskPredictionResult Interpretar(
            int tareaId, TaskTrainingData entrada, TaskPredictionOutput salida)
        {
            bool probabilidadValida =
                float.IsFinite(salida.Probability) &&
                salida.Probability >= 0f &&
                salida.Probability <= 1f;

            NivelRiesgo riesgo = probabilidadValida
                ? (salida.Probability >= _opciones.UmbralRiesgoAlto ? NivelRiesgo.Alto : NivelRiesgo.Bajo)
                : (salida.PredictedLabel ? NivelRiesgo.Alto : NivelRiesgo.Bajo);

            var resultado = new TaskPredictionResult
            {
                TareaId = tareaId,
                Disponible = true,
                PredictedLabel = salida.PredictedLabel,
                Probability = probabilidadValida ? salida.Probability : null,
                Score = float.IsFinite(salida.Score) ? salida.Score : null,
                Riesgo = riesgo,
                ModoDemostrativo = ModoDemostrativo,
                Mensaje = riesgo == NivelRiesgo.Alto
                    ? "El modelo estima un riesgo elevado de retraso considerando los datos " +
                      "actuales de avance y de tiempo transcurrido respecto al plazo planificado. " +
                      "Se sugiere reforzar el seguimiento de esta tarea."
                    : "Con los datos actuales de avance y de tiempo transcurrido, el modelo " +
                      "estima un riesgo bajo de que la tarea termine después de su fecha límite."
            };

            CopiarEntrada(resultado, entrada);
            return resultado;
        }

        private static void CopiarEntrada(TaskPredictionResult r, TaskTrainingData e)
        {
            r.Prioridad = e.Prioridad;
            r.DuracionPlanificada = (int)e.DuracionPlanificada;
            r.DiasTranscurridos = (int)e.DiasTranscurridos;
            r.PorcentajeAvance = (int)e.PorcentajeAvance;
        }

        private ModeloInfo? LeerInfo()
        {
            var ruta = Path.ChangeExtension(RutaModelo, ".json");

            try
            {
                return File.Exists(ruta)
                    ? JsonSerializer.Deserialize<ModeloInfo>(File.ReadAllText(ruta))
                    : null;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo leer la información del modelo.");
                return null;
            }
        }
    }
}
