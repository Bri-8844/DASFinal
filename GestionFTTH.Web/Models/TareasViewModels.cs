using GestionFTTH.Web.Models.MachineLearning;

namespace GestionFTTH.Web.Models
{
    /// <summary>
    /// Listado de tareas + predicciones ML.NET.
    /// </summary>
    public class TareasIndexViewModel
    {
        public List<Tarea> Tareas { get; set; } = new();

        public Dictionary<int, TaskPredictionResult> Predicciones { get; set; } = new();

        public Dictionary<string, string> NombresResponsables { get; set; } = new();

        public bool PuedeGestionar { get; set; }

        public bool ModeloDisponible { get; set; }

        public string? EstadoModelo { get; set; }

        public bool ModoDemostrativo { get; set; }

        public int UmbralRiesgoPorcentaje { get; set; }

        public string? Filtro { get; set; }

        // Paginación
        public int Pagina { get; set; } = 1;
        public int TotalPaginas { get; set; } = 1;
        public int TotalRegistros { get; set; }
        public int TamanoPagina { get; set; }

        public string TituloAlcance { get; set; } = "Todas las tareas";
    }

    /// <summary>
    /// Detalle de una tarea con su predicción e historial de avances.
    /// </summary>
    public class TareaDetalleViewModel
    {
        public Tarea Tarea { get; set; } = null!;

        public TaskPredictionResult Prediccion { get; set; } = null!;

        public string NombreResponsable { get; set; } = "Sin asignar";

        public List<TareaAvance> Avances { get; set; } = new();

        public bool PuedeGestionar { get; set; }

        public bool PuedeActualizarAvance { get; set; }

        public int UmbralRiesgoPorcentaje { get; set; }
    }

    /// <summary>
    /// Formulario de actualización rápida de avance (responsable / jefe / admin).
    /// </summary>
    public class ActualizarAvanceViewModel
    {
        public int Id { get; set; }

        [System.ComponentModel.DataAnnotations.Range(0, 100,
            ErrorMessage = "El avance debe estar entre 0 y 100")]
        public int PorcentajeAvance { get; set; }

        public EstadoTarea Estado { get; set; }
    }
}
