using System.Text.Json;
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Models.MachineLearning;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;

namespace GestionFTTH.Web.Services.MachineLearning
{
    /// <summary>
    /// Entrena, evalúa y guarda el modelo de clasificación binaria
    /// "riesgo de retraso" con ML.NET.
    ///
    /// Origen de datos:
    ///  1) Histórico real de SQL Server (TareaAvances de tareas finalizadas) cuando
    ///     hay suficientes registros y ambas clases.
    ///  2) En caso contrario, MLModels/DatosEntrenamiento.csv (DATOS DEMOSTRATIVOS).
    ///
    /// Evaluación:
    ///  - Histórico real: división TEMPORAL y AGRUPADA POR TAREA (las tareas que
    ///    finalizaron más recientemente se reservan para evaluación; ninguna tarea
    ///    aparece en ambos conjuntos).
    ///  - CSV demostrativo: cada fila es una tarea simulada independiente y sin
    ///    fecha, por lo que se usa una división aleatoria estratificada.
    ///
    /// Solo reemplaza el modelo vigente si el nuevo supera las validaciones mínimas.
    /// </summary>
    public class TaskModelTrainer
    {
        public const string NombreAlgoritmo =
            "SdcaLogisticRegression (clasificación binaria)";

        private static readonly HashSet<string> PrioridadesValidas =
            new(StringComparer.Ordinal) { "Alta", "Media", "Baja" };

        private static readonly SemaphoreSlim Candado = new(1, 1);

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IWebHostEnvironment _env;
        private readonly MachineLearningOptions _opciones;
        private readonly TaskPredictionService _prediccion;
        private readonly ILogger<TaskModelTrainer> _logger;

        public TaskModelTrainer(
            IServiceScopeFactory scopeFactory,
            IWebHostEnvironment env,
            IOptions<MachineLearningOptions> opciones,
            TaskPredictionService prediccion,
            ILogger<TaskModelTrainer> logger)
        {
            _scopeFactory = scopeFactory;
            _env = env;
            _opciones = opciones.Value;
            _prediccion = prediccion;
            _logger = logger;
        }

        public string RutaModelo =>
            Path.Combine(_env.ContentRootPath, _opciones.RutaModelo);

        public string RutaInfo =>
            Path.ChangeExtension(RutaModelo, ".json");

        public string RutaDatosDemo =>
            Path.Combine(_env.ContentRootPath, _opciones.RutaDatosDemo);

        public bool ExisteModelo => File.Exists(RutaModelo);

        /// <summary>
        /// Ejemplo de entrenamiento con su tarea de origen y fecha de referencia
        /// (para separar entrenamiento/evaluación por tarea y por tiempo).
        /// </summary>
        private sealed record Muestra(TaskTrainingData Fila, int? TareaId, DateTime? FechaCierre);

        /// <summary>
        /// Proceso controlado de entrenamiento / reentrenamiento.
        /// </summary>
        /// <param name="permitirDemoSobreReal">
        /// Si es false (por defecto), un modelo entrenado con datos reales NO se
        /// reemplaza por uno entrenado con datos demostrativos.
        /// </param>
        public async Task<ResultadoEntrenamiento> EntrenarAsync(
            bool permitirDemoSobreReal = false,
            CancellationToken cancellationToken = default)
        {
            if (!await Candado.WaitAsync(0, cancellationToken))
            {
                return Fallo("Ya hay un entrenamiento en curso. Intente nuevamente en unos segundos.");
            }

            try
            {
                var advertencias = new List<string>();

                // 1. Cargar datos (histórico real o CSV demostrativo)
                var (muestras, origen, demostrativo) =
                    await CargarDatosAsync(advertencias, cancellationToken);

                // Protección: no degradar un modelo real a uno demostrativo
                var actual = LeerInfo();

                if (demostrativo && !permitirDemoSobreReal &&
                    ExisteModelo && actual != null && !actual.ModoDemostrativo)
                {
                    return Fallo(
                        "El modelo vigente fue entrenado con datos históricos reales y los datos " +
                        "reales disponibles ahora no son suficientes. Se conserva el modelo real. " +
                        "(Puede forzar el modelo demostrativo marcando la opción correspondiente.)");
                }

                // 2. Validar y preparar
                var validas = muestras.Where(m => EsFilaValida(m.Fila)).ToList();
                int descartados = muestras.Count - validas.Count;

                if (descartados > 0)
                {
                    advertencias.Add($"Se descartaron {descartados} registros con datos inválidos.");
                }

                foreach (var m in validas)
                {
                    m.Fila.CalcularDerivadas();
                }

                int positivos = validas.Count(m => m.Fila.Label);
                int negativos = validas.Count - positivos;

                if (validas.Count < _opciones.MinimoRegistrosEntrenamiento)
                {
                    return Fallo(
                        $"Datos insuficientes: {validas.Count} registros válidos " +
                        $"(mínimo {_opciones.MinimoRegistrosEntrenamiento}). Se conserva el modelo actual.");
                }

                if (positivos == 0 || negativos == 0)
                {
                    return Fallo(
                        "Los datos contienen una sola clase (todas las tareas retrasadas " +
                        "o todas a tiempo). No es posible entrenar un clasificador. " +
                        "Se conserva el modelo actual.");
                }

                // 3. División entrenamiento / evaluación
                var division = demostrativo
                    ? DividirEstratificado(validas, _opciones.FraccionEvaluacion, _opciones.SemillaAleatoria)
                    : DividirTemporalPorTarea(validas, _opciones.FraccionEvaluacion, advertencias);

                var entrenamiento = division.Entrenamiento;
                var evaluacion = division.Evaluacion;

                bool evaluacionSeparada =
                    evaluacion.Count >= 10 &&
                    evaluacion.Any(m => m.Fila.Label) &&
                    evaluacion.Any(m => !m.Fila.Label) &&
                    entrenamiento.Any(m => m.Fila.Label) &&
                    entrenamiento.Any(m => !m.Fila.Label);

                string tipoDivision = division.Tipo;

                if (!evaluacionSeparada)
                {
                    entrenamiento = validas;
                    evaluacion = validas;
                    tipoDivision = "Sin conjunto independiente (evaluado sobre los datos de entrenamiento)";

                    advertencias.Add(
                        "ADVERTENCIA: no hay datos suficientes para un conjunto de evaluación " +
                        "independiente con ambas clases; las métricas se calcularon sobre los " +
                        "mismos datos de entrenamiento y están sobreestimadas.");
                }

                var ml = new MLContext(seed: _opciones.SemillaAleatoria);

                var dvEntrenamiento = ml.Data.LoadFromEnumerable(entrenamiento.Select(m => m.Fila));
                var dvEvaluacion = ml.Data.LoadFromEnumerable(evaluacion.Select(m => m.Fila));

                // 4. Pipeline ML.NET
                ITransformer modelo = ConstruirPipeline(ml).Fit(dvEntrenamiento);

                // 5. Evaluación
                CalibratedBinaryClassificationMetrics metricas =
                    ml.BinaryClassification.Evaluate(
                        modelo.Transform(dvEvaluacion),
                        labelColumnName: nameof(TaskTrainingData.Label));

                int positivosEval = evaluacion.Count(m => m.Fila.Label);
                double lineaBase = (double)Math.Max(positivosEval, evaluacion.Count - positivosEval)
                                   / evaluacion.Count;

                int? tareasEval = demostrativo ? null : evaluacion.Select(m => m.TareaId).Distinct().Count();

                bool confiables =
                    evaluacionSeparada &&
                    !demostrativo &&
                    evaluacion.Count >= 30 &&
                    (tareasEval ?? 0) >= 10;

                if (demostrativo)
                {
                    advertencias.Add(
                        "MODO DEMOSTRATIVO: el modelo se entrenó con datos simulados " +
                        "(DatosEntrenamiento.csv). Sus métricas NO representan el " +
                        "rendimiento real del sistema.");
                }
                else if (!confiables)
                {
                    advertencias.Add(
                        "El conjunto de evaluación es pequeño (menos de 30 registros o de 10 " +
                        "tareas); las métricas no son estadísticamente confiables.");
                }

                double? auc = double.IsNaN(metricas.AreaUnderRocCurve)
                    ? null
                    : Redondear(metricas.AreaUnderRocCurve);

                var info = new ModeloInfo
                {
                    FechaEntrenamiento = DateTime.Now,
                    OrigenDatos = origen,
                    ModoDemostrativo = demostrativo,
                    Algoritmo = NombreAlgoritmo,
                    TipoDivision = tipoDivision,
                    RegistrosTotales = validas.Count,
                    RegistrosEntrenamiento = entrenamiento.Count,
                    RegistrosEvaluacion = evaluacion.Count,
                    TareasEntrenamiento = demostrativo ? null : entrenamiento.Select(m => m.TareaId).Distinct().Count(),
                    TareasEvaluacion = tareasEval,
                    RegistrosRetrasados = positivos,
                    RegistrosNoRetrasados = negativos,
                    AccuracyLineaBase = Redondear(lineaBase),
                    Accuracy = Redondear(metricas.Accuracy),
                    Precision = Redondear(metricas.PositivePrecision),
                    Recall = Redondear(metricas.PositiveRecall),
                    F1Score = Redondear(metricas.F1Score),
                    Auc = auc,
                    MetricasConfiables = confiables,
                    Advertencias = advertencias
                };

                // 6. Validación mínima antes de reemplazar el modelo vigente
                var motivoRechazo = ValidarCalidad(metricas);

                if (motivoRechazo != null)
                {
                    _logger.LogWarning("Modelo ML.NET descartado: {Motivo}", motivoRechazo);

                    return new ResultadoEntrenamiento
                    {
                        Exito = false,
                        ModeloGuardado = false,
                        Info = info,
                        Mensaje = motivoRechazo + " Se conserva el modelo anterior."
                    };
                }

                // 7. Guardado seguro: archivo temporal, verificación y reemplazo
                GuardarModelo(ml, modelo, dvEntrenamiento.Schema, info);

                // 8. Cargar el modelo actualizado en el servicio de predicción
                _prediccion.RecargarModelo();

                _logger.LogInformation(
                    "Modelo ML.NET entrenado ({Origen}, {Division}): {Total} registros, accuracy {Accuracy:P1} (línea base {Base:P1}), AUC {Auc}.",
                    origen, tipoDivision, validas.Count, metricas.Accuracy, lineaBase, info.Auc);

                return new ResultadoEntrenamiento
                {
                    Exito = true,
                    ModeloGuardado = true,
                    Info = info,
                    Mensaje = demostrativo
                        ? "Modelo entrenado y guardado en MODO DEMOSTRATIVO (datos simulados)."
                        : "Modelo entrenado y guardado con datos históricos reales."
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error durante el entrenamiento del modelo ML.NET.");

                return Fallo(
                    "Ocurrió un error durante el entrenamiento. Se conserva el último " +
                    "modelo válido. Revise el registro de la aplicación para más detalles.");
            }
            finally
            {
                Candado.Release();
            }
        }

        private string? ValidarCalidad(CalibratedBinaryClassificationMetrics metricas)
        {
            if (double.IsNaN(metricas.Accuracy) || metricas.Accuracy < _opciones.AccuracyMinima)
            {
                return $"El nuevo modelo obtuvo accuracy {metricas.Accuracy:P1}, inferior al " +
                       $"mínimo requerido ({_opciones.AccuracyMinima:P0}).";
            }

            if (!double.IsNaN(metricas.AreaUnderRocCurve) &&
                metricas.AreaUnderRocCurve < _opciones.AucMinimo)
            {
                return $"El nuevo modelo obtuvo AUC {metricas.AreaUnderRocCurve:0.000}, inferior al " +
                       $"mínimo requerido ({_opciones.AucMinimo:0.00}).";
            }

            return null;
        }

        /// <summary>
        /// Pipeline: OneHotEncoding(Prioridad) + Concatenate(numéricas) +
        /// normalización + SdcaLogisticRegression.
        /// </summary>
        private static IEstimator<ITransformer> ConstruirPipeline(MLContext ml)
        {
            return ml.Transforms.Categorical
                    .OneHotEncoding(
                        outputColumnName: "PrioridadCodificada",
                        inputColumnName: nameof(TaskTrainingData.Prioridad))
                .Append(ml.Transforms.Concatenate(
                    "NumericasSinNormalizar",
                    nameof(TaskTrainingData.DuracionPlanificada),
                    nameof(TaskTrainingData.PorcentajeAvance),
                    nameof(TaskTrainingData.DiasTranscurridos),
                    nameof(TaskTrainingData.ProporcionTiempo),
                    nameof(TaskTrainingData.BrechaAvance)))
                .Append(ml.Transforms.NormalizeMeanVariance(
                    "NumericasNormalizadas",
                    "NumericasSinNormalizar"))
                .Append(ml.Transforms.Concatenate(
                    "Features",
                    "PrioridadCodificada",
                    "NumericasNormalizadas"))
                .Append(ml.BinaryClassification.Trainers.SdcaLogisticRegression(
                    new SdcaLogisticRegressionBinaryTrainer.Options
                    {
                        LabelColumnName = nameof(TaskTrainingData.Label),
                        FeatureColumnName = "Features",
                        // Un solo hilo: resultados reproducibles con la misma semilla
                        NumberOfThreads = 1
                    }));
        }

        private void GuardarModelo(
            MLContext ml,
            ITransformer modelo,
            DataViewSchema esquema,
            ModeloInfo info)
        {
            var carpeta = Path.GetDirectoryName(RutaModelo)!;
            Directory.CreateDirectory(carpeta);

            var temporal = RutaModelo + ".tmp";

            ml.Model.Save(modelo, esquema, temporal);

            // Verificar que el archivo temporal se puede volver a cargar
            using (var stream = File.OpenRead(temporal))
            {
                ml.Model.Load(stream, out _);
            }

            File.Move(temporal, RutaModelo, overwrite: true);

            File.WriteAllText(
                RutaInfo,
                JsonSerializer.Serialize(info, new JsonSerializerOptions { WriteIndented = true }));
        }

        private async Task<(List<Muestra> Datos, string Origen, bool Demostrativo)>
            CargarDatosAsync(List<string> advertencias, CancellationToken ct)
        {
            var reales = await CargarHistoricoRealAsync(ct);

            bool realesSuficientes =
                reales.Count >= _opciones.MinimoRegistrosReales &&
                reales.Any(r => r.Fila.Label) &&
                reales.Any(r => !r.Fila.Label);

            if (realesSuficientes)
            {
                return (reales, "Histórico real (SQL Server)", false);
            }

            advertencias.Add(
                $"La base de datos tiene {reales.Count} registros históricos válidos " +
                $"(se requieren al menos {_opciones.MinimoRegistrosReales} con tareas " +
                "retrasadas y a tiempo). Se usó el CSV demostrativo.");

            var demo = CargarCsvDemostrativo()
                .Select(f => new Muestra(f, null, null))
                .ToList();

            return (demo, "Demostrativo (DatosEntrenamiento.csv)", true);
        }

        /// <summary>
        /// Construye ejemplos SIN data leakage: cada registro de TareaAvances aporta
        /// el avance, la prioridad y las fechas planificadas vigentes EN ESA FECHA;
        /// la etiqueta se obtiene del resultado final de la tarea
        /// (FechaFinalizacion > FechaLimite oficial).
        /// </summary>
        private async Task<List<Muestra>> CargarHistoricoRealAsync(CancellationToken ct)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var registros = await db.TareaAvances
                .AsNoTracking()
                .Where(a =>
                    a.Tarea!.Estado == EstadoTarea.Finalizada &&
                    a.Tarea.FechaLimite != null &&
                    a.Tarea.FechaFinalizacion != null)
                .Select(a => new
                {
                    a.TareaId,
                    a.Fecha,
                    a.PorcentajeAvance,
                    // Plan vigente en la fecha del registro (o el actual si no se guardó)
                    Prioridad = a.Prioridad ?? a.Tarea!.Prioridad,
                    InicioPlan = a.FechaInicioPlan ?? a.Tarea!.FechaInicio,
                    LimitePlan = a.FechaLimitePlan ?? a.Tarea!.FechaLimite,
                    LimiteOficial = a.Tarea!.FechaLimite!.Value,
                    FechaFinalizacion = a.Tarea.FechaFinalizacion!.Value
                })
                .ToListAsync(ct);

            var muestras = new List<Muestra>();

            foreach (var r in registros)
            {
                if (!r.InicioPlan.HasValue || !r.LimitePlan.HasValue)
                {
                    continue;
                }

                var inicio = r.InicioPlan.Value.Date;

                // Solo instantes anteriores al cierre (información disponible en ese momento)
                if (r.Fecha.Date >= r.FechaFinalizacion.Date || r.Fecha.Date < inicio)
                {
                    continue;
                }

                int duracion = (r.LimitePlan.Value.Date - inicio).Days;

                if (duracion <= 0)
                {
                    continue;
                }

                var fila = TaskTrainingData.Crear(
                    prioridad: r.Prioridad.ToString(),
                    duracionPlanificada: duracion,
                    porcentajeAvance: r.PorcentajeAvance,
                    diasTranscurridos: (r.Fecha.Date - inicio).Days,
                    label: r.FechaFinalizacion.Date > r.LimiteOficial.Date);

                muestras.Add(new Muestra(fila, r.TareaId, r.FechaFinalizacion.Date));
            }

            return muestras;
        }

        public List<TaskTrainingData> CargarCsvDemostrativo()
        {
            if (!File.Exists(RutaDatosDemo))
            {
                throw new FileNotFoundException(
                    "No se encontró el archivo de datos demostrativos DatosEntrenamiento.csv.");
            }

            var ml = new MLContext(seed: _opciones.SemillaAleatoria);

            IDataView vista = ml.Data.LoadFromTextFile<TaskCsvRow>(
                RutaDatosDemo,
                hasHeader: true,
                separatorChar: ',');

            return ml.Data
                .CreateEnumerable<TaskCsvRow>(vista, reuseRowObject: false)
                .Select(r => TaskTrainingData.Crear(
                    r.Prioridad?.Trim() ?? string.Empty,
                    r.DuracionPlanificada,
                    r.PorcentajeAvance,
                    r.DiasTranscurridos,
                    r.SeRetraso))
                .ToList();
        }

        private static bool EsFilaValida(TaskTrainingData f) =>
            PrioridadesValidas.Contains(f.Prioridad ?? string.Empty) &&
            float.IsFinite(f.DuracionPlanificada) && f.DuracionPlanificada > 0 &&
            float.IsFinite(f.PorcentajeAvance) && f.PorcentajeAvance >= 0 && f.PorcentajeAvance <= 100 &&
            float.IsFinite(f.DiasTranscurridos) && f.DiasTranscurridos >= 0;

        private sealed record Division(List<Muestra> Entrenamiento, List<Muestra> Evaluacion, string Tipo);

        /// <summary>
        /// Histórico real: las tareas que finalizaron más recientemente van a
        /// evaluación. Todas las instantáneas de una misma tarea quedan en el mismo
        /// conjunto (sin fuga entre entrenamiento y evaluación).
        /// </summary>
        private static Division DividirTemporalPorTarea(
            List<Muestra> datos, double fraccion, List<string> advertencias)
        {
            var tareas = datos
                .GroupBy(m => m.TareaId)
                .Select(g => new { TareaId = g.Key, Cierre = g.First().FechaCierre ?? DateTime.MinValue })
                .OrderBy(t => t.Cierre)
                .ThenBy(t => t.TareaId)
                .ToList();

            int nEval = Math.Max(1, (int)Math.Round(tareas.Count * fraccion));
            var idsEval = tareas.Skip(tareas.Count - nEval).Select(t => t.TareaId).ToHashSet();

            var evaluacion = datos.Where(m => idsEval.Contains(m.TareaId)).ToList();
            var entrenamiento = datos.Where(m => !idsEval.Contains(m.TareaId)).ToList();

            var corte = tareas[tareas.Count - nEval].Cierre;

            advertencias.Add(
                $"Evaluación temporal: {nEval} de {tareas.Count} tareas (finalizadas desde " +
                $"{corte:dd/MM/yyyy}) se reservaron para evaluación; ninguna tarea aparece en ambos conjuntos.");

            return new Division(entrenamiento, evaluacion,
                "Temporal y agrupada por tarea (tareas más recientes en evaluación)");
        }

        /// <summary>
        /// CSV demostrativo: filas independientes y sin fecha -> aleatoria estratificada.
        /// </summary>
        private static Division DividirEstratificado(
            List<Muestra> datos, double fraccion, int semilla)
        {
            var azar = new Random(semilla);
            var entrenamiento = new List<Muestra>();
            var evaluacion = new List<Muestra>();

            foreach (var grupo in datos.GroupBy(d => d.Fila.Label))
            {
                var mezclados = grupo.OrderBy(_ => azar.Next()).ToList();
                int nEval = (int)Math.Round(mezclados.Count * fraccion);

                evaluacion.AddRange(mezclados.Take(nEval));
                entrenamiento.AddRange(mezclados.Skip(nEval));
            }

            return new Division(entrenamiento, evaluacion,
                "Aleatoria estratificada (datos simulados sin dimensión temporal)");
        }

        private static double Redondear(double valor) =>
            double.IsNaN(valor) ? 0 : Math.Round(valor, 4);

        private static ResultadoEntrenamiento Fallo(string mensaje) =>
            new() { Exito = false, ModeloGuardado = false, Mensaje = mensaje };

        public ModeloInfo? LeerInfo()
        {
            try
            {
                return File.Exists(RutaInfo)
                    ? JsonSerializer.Deserialize<ModeloInfo>(File.ReadAllText(RutaInfo))
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
