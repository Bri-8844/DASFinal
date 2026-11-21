using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GestionFTTH.Web.Data.Migrations
{
    /// <inheritdoc />
    public partial class PlanVigenteEnAvances : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "FechaInicioPlan",
                table: "TareaAvances",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FechaLimitePlan",
                table: "TareaAvances",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Prioridad",
                table: "TareaAvances",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FechaInicioPlan",
                table: "TareaAvances");

            migrationBuilder.DropColumn(
                name: "FechaLimitePlan",
                table: "TareaAvances");

            migrationBuilder.DropColumn(
                name: "Prioridad",
                table: "TareaAvances");
        }
    }
}
