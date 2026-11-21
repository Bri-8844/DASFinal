using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GestionFTTH.Web.Models
{
    /// <summary>
    /// Registro histórico del avance de una tarea en una fecha concreta.
    /// Permite entrenar el modelo ML.NET con la información que existía
    /// en cada momento (sin usar el avance final: evita data leakage).
    /// </summary>
    public class TareaAvance
    {
        [Key]
        public int Id { get; set; }

        public int TareaId { get; set; }

        [ForeignKey(nameof(TareaId))]
        public Tarea? Tarea { get; set; }

        // Fecha (local, sin hora) en la que se registró el avance
        [DataType(DataType.Date)]
        public DateTime Fecha { get; set; }

        [Range(0, 100)]
        public int PorcentajeAvance { get; set; }

        public EstadoTarea Estado { get; set; }

        // Plan vigente EN ESA FECHA (prioridad y fechas pueden cambiar después).
        // ML.NET usa estos valores como características para no filtrar
        // información futura. Son NULL en registros anteriores a esta columna.
        public PrioridadTarea? Prioridad { get; set; }

        [DataType(DataType.Date)]
        public DateTime? FechaInicioPlan { get; set; }

        [DataType(DataType.Date)]
        public DateTime? FechaLimitePlan { get; set; }

        [StringLength(450)]
        public string? RegistradoPorId { get; set; }
    }
}
