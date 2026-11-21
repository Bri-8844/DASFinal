using Microsoft.ML.Data;

namespace GestionFTTH.Web.Models.MachineLearning
{
    /// <summary>
    /// Salida cruda del clasificador binario de ML.NET
    /// (SdcaLogisticRegression produce PredictedLabel, Score y Probability).
    /// </summary>
    public class TaskPredictionOutput
    {
        [ColumnName("PredictedLabel")]
        public bool PredictedLabel { get; set; }

        public float Probability { get; set; }

        public float Score { get; set; }
    }
}
