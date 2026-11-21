namespace GestionFTTH.Web.Models.MachineLearning
{
    /// <summary>
    /// Metadatos del último modelo entrenado. Se guardan junto al .zip
    /// (MLModels/ModeloRetraso.json) para mostrarlos en la pantalla del modelo.
    /// </summary>
    public class ModeloInfo
    {
        public DateTime FechaEntrenamiento { get; set; }

        // "Demostrativo (CSV)" o "Histórico real (SQL Server)"
        public string OrigenDatos { get; set; } = string.Empty;

        public bool ModoDemostrativo { get; set; }

        public string Algoritmo { get; set; } = string.Empty;

        public int RegistrosTotales { get; set; }
        public int RegistrosEntrenamiento { get; set; }
        public int RegistrosEvaluacion { get; set; }
        public int RegistrosRetrasados { get; set; }
        public int RegistrosNoRetrasados { get; set; }

        // Cómo se separaron entrenamiento y evaluación
        public string TipoDivision { get; set; } = string.Empty;

        // Tareas distintas en cada conjunto (solo histórico real)
        public int? TareasEntrenamiento { get; set; }
        public int? TareasEvaluacion { get; set; }

        // Accuracy de un clasificador trivial (siempre la clase mayoritaria
        // del conjunto de evaluación): referencia para interpretar Accuracy
        public double AccuracyLineaBase { get; set; }

        public double Accuracy { get; set; }
        public double Precision { get; set; }
        public double Recall { get; set; }
        public double F1Score { get; set; }
        public double? Auc { get; set; }

        public bool MetricasConfiables { get; set; }

        public List<string> Advertencias { get; set; } = new();
    }

    /// <summary>
    /// Resultado de un intento de entrenamiento.
    /// </summary>
    public class ResultadoEntrenamiento
    {
        public bool Exito { get; set; }

        public bool ModeloGuardado { get; set; }

        public string Mensaje { get; set; } = string.Empty;

        public ModeloInfo? Info { get; set; }
    }
}
