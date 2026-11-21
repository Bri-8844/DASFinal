using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GestionFTTH.Web.Data.Migrations
{
    /// <inheritdoc />
    public partial class AuditoriaYMachineLearning : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "FechaFinalizacion",
                table: "Tareas",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "TareaAvances",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TareaId = table.Column<int>(type: "int", nullable: false),
                    Fecha = table.Column<DateTime>(type: "datetime2", nullable: false),
                    PorcentajeAvance = table.Column<int>(type: "int", nullable: false),
                    Estado = table.Column<int>(type: "int", nullable: false),
                    RegistradoPorId = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TareaAvances", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TareaAvances_Tareas_TareaId",
                        column: x => x.TareaId,
                        principalTable: "Tareas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Tareas_ResponsableId",
                table: "Tareas",
                column: "ResponsableId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_TrabajadorId",
                table: "AspNetUsers",
                column: "TrabajadorId",
                unique: true,
                filter: "[TrabajadorId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_TareaAvances_TareaId_Fecha",
                table: "TareaAvances",
                columns: new[] { "TareaId", "Fecha" });

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Trabajadores_TrabajadorId",
                table: "AspNetUsers",
                column: "TrabajadorId",
                principalTable: "Trabajadores",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Tareas_AspNetUsers_ResponsableId",
                table: "Tareas",
                column: "ResponsableId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Trabajadores_TrabajadorId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_Tareas_AspNetUsers_ResponsableId",
                table: "Tareas");

            migrationBuilder.DropTable(
                name: "TareaAvances");

            migrationBuilder.DropIndex(
                name: "IX_Tareas_ResponsableId",
                table: "Tareas");

            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_TrabajadorId",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "FechaFinalizacion",
                table: "Tareas");
        }
    }
}
