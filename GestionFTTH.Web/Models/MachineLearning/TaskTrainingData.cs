using Microsoft.ML.Data;

namespace GestionFTTH.Web.Models.MachineLearning
{
    /// <summary>
    /// Fila de entrenamiento / entrada de predicción del modelo de riesgo de retraso.
    ///
    /// Características (información disponible EN EL MOMENTO de la predicción):
    ///   Prioridad, DuracionPlanificada, PorcentajeAvance, DiasTranscurridos.
    /// Características derivadas (calculadas solo a partir de las anteriores):
    ///   ProporcionTiempo y BrechaAvance.
    /// Etiqueta: Label = la tarea terminó después de su fecha límite.
    /// </summary>
    public class TaskTrainingData
    {
        public string Prioridad { get; set; } = string.Empty;

        public float DuracionPlanificada { get; set; }

        public float PorcentajeAvance { get; set; }

        public float DiasTranscurridos { get; set; }

        public bool Label { get; set; }

        // Fracción del plazo consumida (días transcurridos / duración planificada)
        public float ProporcionTiempo { get; set; }

        // Diferencia (en puntos porcentuales) entre el avance esperado
        // según el tiempo consumido y el avance real
        public float BrechaAvance { get; set; }

        /// <summary>
        /// Única forma de construir una fila: garantiza que entrenamiento y
        /// predicción calculen las características derivadas de la misma manera.
        /// </summary>
        public static TaskTrainingData Crear(
            string prioridad,
            float duracionPlanificada,
            float porcentajeAvance,
            float diasTranscurridos,
            bool label = false)
        {
            var fila = new TaskTrainingData
            {
                Prioridad = prioridad,
                DuracionPlanificada = duracionPlanificada,
                PorcentajeAvance = porcentajeAvance,
                DiasTranscurridos = diasTranscurridos,
                Label = label
            };

            fila.CalcularDerivadas();
            return fila;
        }

        public void CalcularDerivadas()
        {
            ProporcionTiempo = DuracionPlanificada > 0
                ? DiasTranscurridos / DuracionPlanificada
                : 0f;

            BrechaAvance = ProporcionTiempo * 100f - PorcentajeAvance;
        }
    }

    /// <summary>
    /// Estructura de MLModels/DatosEntrenamiento.csv
    /// (Prioridad,DuracionPlanificada,PorcentajeAvance,DiasTranscurridos,SeRetraso,Origen).
    /// </summary>
    public class TaskCsvRow
    {
        [LoadColumn(0)]
        public string Prioridad { get; set; } = string.Empty;

        [LoadColumn(1)]
        public float DuracionPlanificada { get; set; }

        [LoadColumn(2)]
        public float PorcentajeAvance { get; set; }

        [LoadColumn(3)]
        public float DiasTranscurridos { get; set; }

        [LoadColumn(4)]
        public bool SeRetraso { get; set; }

        // "DEMO": identifica que el registro es simulado
        [LoadColumn(5)]
        public string Origen { get; set; } = string.Empty;
    }
}
