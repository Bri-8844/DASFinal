namespace GestionFTTH.Web.Models.MachineLearning
{
    public enum NivelRiesgo
    {
        NoDisponible = 0,
        Bajo = 1,
        Alto = 2
    }

    /// <summary>
    /// Resultado de predicción listo para la interfaz.
    /// </summary>
    public class TaskPredictionResult
    {
        public int TareaId { get; set; }

        // false cuando no se pudo predecir (faltan datos, tarea finalizada,
        // modelo no entrenado, etc.). En ese caso se muestra "No disponible".
        public bool Disponible { get; set; }

        public bool PredictedLabel { get; set; }

        // Probabilidad de retraso entre 0 y 1 (null si no es válida)
        public float? Probability { get; set; }

        public float? Score { get; set; }

        public NivelRiesgo Riesgo { get; set; } = NivelRiesgo.NoDisponible;

        public string Mensaje { get; set; } = string.Empty;

        // Datos de entrada usados (se muestran en el detalle)
        public string? Prioridad { get; set; }
        public int? DuracionPlanificada { get; set; }
        public int? DiasTranscurridos { get; set; }
        public int? PorcentajeAvance { get; set; }

        // true si el modelo se entrenó con datos demostrativos
        public bool ModoDemostrativo { get; set; }

        public int? ProbabilidadPorcentaje =>
            Probability.HasValue
                ? (int)Math.Round(Probability.Value * 100, MidpointRounding.AwayFromZero)
                : null;

        public string RiesgoTexto => Riesgo switch
        {
            NivelRiesgo.Alto => "ALTO",
            NivelRiesgo.Bajo => "BAJO",
            _ => "No disponible"
        };

        public static TaskPredictionResult NoDisponible(int tareaId, string motivo) =>
            new()
            {
                TareaId = tareaId,
                Disponible = false,
                Riesgo = NivelRiesgo.NoDisponible,
                Mensaje = motivo
            };
    }
}
