namespace GestionFTTH.Web.Services.MachineLearning
{
    /// <summary>
    /// Configuración del módulo ML.NET (sección "MachineLearning" de appsettings.json).
    /// El umbral de riesgo se define SOLO aquí.
    /// </summary>
    public class MachineLearningOptions
    {
        public const string Seccion = "MachineLearning";

        // Probabilidad a partir de la cual el riesgo es ALTO (0.60 = 60 %)
        public float UmbralRiesgoAlto { get; set; } = 0.60f;

        // Rutas relativas al ContentRoot de la aplicación
        public string RutaModelo { get; set; } = "MLModels/ModeloRetraso.zip";

        public string RutaDatosDemo { get; set; } = "MLModels/DatosEntrenamiento.csv";

        // Mínimo de registros históricos reales (con ambas clases) para
        // entrenar con SQL Server en lugar del CSV demostrativo
        public int MinimoRegistrosReales { get; set; } = 60;

        // Validaciones mínimas que debe superar un modelo antes de reemplazar al actual
        public int MinimoRegistrosEntrenamiento { get; set; } = 30;

        public double AccuracyMinima { get; set; } = 0.60;

        // AUC mínimo (capacidad de discriminación); 0.5 = azar
        public double AucMinimo { get; set; } = 0.60;

        // Fracción de TAREAS (las más recientes) reservadas para evaluación
        public double FraccionEvaluacion { get; set; } = 0.20;

        // Si no existe un modelo al iniciar, entrenar uno automáticamente
        public bool EntrenarAlIniciarSiNoExiste { get; set; } = true;

        public int SemillaAleatoria { get; set; } = 2026;
    }
}
