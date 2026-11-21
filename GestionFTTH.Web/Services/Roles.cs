namespace GestionFTTH.Web.Services
{
    /// <summary>
    /// Nombres de roles y políticas centralizados (evita cadenas repetidas).
    /// </summary>
    public static class Roles
    {
        public const string AdministradorPrincipal = "AdministradorPrincipal";
        public const string AdministradorGerencia = "AdministradorGerencia";
        public const string JefeArea = "JefeArea";
        public const string Trabajador = "Trabajador";

        // Para [Authorize(Roles = ...)]
        public const string Administradores = AdministradorPrincipal + "," + AdministradorGerencia;
        public const string GestoresTareas = Administradores + "," + JefeArea;
        public const string Todos = GestoresTareas + "," + Trabajador;

        public const string PoliticaAdministradores = "Administradores";
        public const string PoliticaDeshabilitado = "Deshabilitado";

        public static readonly string[] Lista =
        {
            AdministradorPrincipal,
            AdministradorGerencia,
            JefeArea,
            Trabajador
        };

        public static string NombreVisible(string? rol) => rol switch
        {
            AdministradorPrincipal => "Administrador principal",
            AdministradorGerencia => "Gerente de operaciones",
            JefeArea => "Jefe de área",
            Trabajador => "Trabajador",
            _ => "Sin rol"
        };

        // Roles que requieren un trabajador vinculado
        public static bool RequiereTrabajador(string? rol) =>
            rol == JefeArea || rol == Trabajador;
    }
}
