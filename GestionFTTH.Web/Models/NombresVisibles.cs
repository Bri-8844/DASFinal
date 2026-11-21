namespace GestionFTTH.Web.Models
{
    /// <summary>
    /// Textos visibles de los enums (centralizados para vistas y controladores).
    /// </summary>
    public static class NombresVisibles
    {
        public static string Area(AreaProyecto area) => area switch
        {
            AreaProyecto.Prediseño => "Prediseño",
            AreaProyecto.Diseño => "Diseño",
            AreaProyecto.Construccion => "Construcción",
            _ => "No definida"
        };

        public static string EstadoProyecto(EstadoProyecto estado) => estado switch
        {
            Models.EstadoProyecto.Pendiente => "Pendiente",
            Models.EstadoProyecto.EnEjecucion => "En ejecución",
            Models.EstadoProyecto.Finalizado => "Finalizado",
            _ => "No definido"
        };

        public static string EstadoTarea(EstadoTarea estado) => estado switch
        {
            Models.EstadoTarea.Pendiente => "Pendiente",
            Models.EstadoTarea.EnEjecucion => "En ejecución",
            Models.EstadoTarea.Finalizada => "Finalizada",
            _ => "No definido"
        };

        public static string Prioridad(PrioridadTarea prioridad) => prioridad switch
        {
            PrioridadTarea.Alta => "Alta",
            PrioridadTarea.Media => "Media",
            PrioridadTarea.Baja => "Baja",
            _ => "No definida"
        };
    }
}
