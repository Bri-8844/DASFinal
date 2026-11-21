using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GestionFTTH.Web.Data.Migrations
{
    /// <inheritdoc />
    public partial class RestriccionesCheck : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddCheckConstraint(
                name: "CK_Trabajadores_Area",
                table: "Trabajadores",
                sql: "[Area] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Tareas_Estado",
                table: "Tareas",
                sql: "[Estado] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Tareas_Fechas",
                table: "Tareas",
                sql: "[FechaInicio] IS NULL OR [FechaLimite] IS NULL OR [FechaLimite] >= [FechaInicio]");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Tareas_PorcentajeAvance",
                table: "Tareas",
                sql: "[PorcentajeAvance] BETWEEN 0 AND 100");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Tareas_Prioridad",
                table: "Tareas",
                sql: "[Prioridad] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_TareaAvances_Estado",
                table: "TareaAvances",
                sql: "[Estado] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_TareaAvances_PorcentajeAvance",
                table: "TareaAvances",
                sql: "[PorcentajeAvance] BETWEEN 0 AND 100");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Proyectos_Area",
                table: "Proyectos",
                sql: "[Area] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Proyectos_Estado",
                table: "Proyectos",
                sql: "[Estado] BETWEEN 1 AND 3");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Proyectos_Fechas",
                table: "Proyectos",
                sql: "[FechaInicio] IS NULL OR [FechaEntrega] IS NULL OR [FechaEntrega] >= [FechaInicio]");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Trabajadores_Area",
                table: "Trabajadores");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Tareas_Estado",
                table: "Tareas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Tareas_Fechas",
                table: "Tareas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Tareas_PorcentajeAvance",
                table: "Tareas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Tareas_Prioridad",
                table: "Tareas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_TareaAvances_Estado",
                table: "TareaAvances");

            migrationBuilder.DropCheckConstraint(
                name: "CK_TareaAvances_PorcentajeAvance",
                table: "TareaAvances");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Proyectos_Area",
                table: "Proyectos");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Proyectos_Estado",
                table: "Proyectos");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Proyectos_Fechas",
                table: "Proyectos");
        }
    }
}
