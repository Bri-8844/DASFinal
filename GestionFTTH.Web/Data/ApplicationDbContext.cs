
using GestionFTTH.Web.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Data
{
    public class ApplicationDbContext
        : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(
            DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // Tabla de proyectos
        public DbSet<Proyecto> Proyectos { get; set; }
            = null!;

        // Tabla de tareas
        public DbSet<Tarea> Tareas { get; set; }
            = null!;

        // Historial de avances de tareas (datos para ML.NET)
        public DbSet<TareaAvance> TareaAvances { get; set; }
            = null!;

        // Tabla de trabajadores
        public DbSet<Trabajador> Trabajadores { get; set; }
            = null!;

        protected override void OnModelCreating(
            ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // ===== Nombres de tablas de ASP.NET Core Identity =====
            // Se reemplazan los nombres por defecto (AspNet*) por una nomenclatura en
            // español coherente con el resto de la base. Solo cambia el nombre de la
            // tabla: columnas, claves, tipos y datos se conservan (la migración usa
            // sp_rename, no recrea tablas).
            builder.Entity<ApplicationUser>().ToTable("Usuarios");
            builder.Entity<IdentityRole>().ToTable("Roles");
            builder.Entity<IdentityUserRole<string>>().ToTable("UsuarioRoles");
            builder.Entity<IdentityUserClaim<string>>().ToTable("UsuarioClaims");
            builder.Entity<IdentityRoleClaim<string>>().ToTable("RolClaims");
            builder.Entity<IdentityUserLogin<string>>().ToTable("UsuarioLogins");
            builder.Entity<IdentityUserToken<string>>().ToTable("UsuarioTokens");

            // Evitar códigos de proyecto duplicados
            builder.Entity<Proyecto>()
                .HasIndex(p => p.Codigo)
                .IsUnique();

            // Evitar códigos de tarea duplicados
            builder.Entity<Tarea>()
                .HasIndex(t => t.Codigo)
                .IsUnique();

            // Relación Proyecto (1) - Tareas (N)
            builder.Entity<Tarea>()
                .HasOne(t => t.Proyecto)
                .WithMany()
                .HasForeignKey(t => t.ProyectoId)
                .OnDelete(DeleteBehavior.Restrict);

            // Relación Usuario responsable (1) - Tareas (N).
            // Si se elimina el usuario, la tarea queda sin asignar.
            builder.Entity<Tarea>()
                .HasOne(t => t.Responsable)
                .WithMany()
                .HasForeignKey(t => t.ResponsableId)
                .OnDelete(DeleteBehavior.SetNull);

            // Historial de avances: se elimina junto con la tarea
            builder.Entity<TareaAvance>()
                .HasOne(a => a.Tarea)
                .WithMany(t => t.Avances)
                .HasForeignKey(a => a.TareaId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<TareaAvance>()
                .HasIndex(a => new { a.TareaId, a.Fecha });

            // Evitar códigos de trabajador duplicados
            builder.Entity<Trabajador>()
                .HasIndex(t => t.Codigo)
                .IsUnique();

            // Usuario (0..1) - Trabajador (0..1):
            // un trabajador solo puede tener una cuenta y no puede
            // eliminarse mientras tenga una cuenta vinculada.
            builder.Entity<ApplicationUser>()
                .HasOne(u => u.Trabajador)
                .WithMany()
                .HasForeignKey(u => u.TrabajadorId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<ApplicationUser>()
                .HasIndex(u => u.TrabajadorId)
                .IsUnique()
                .HasFilter("[TrabajadorId] IS NOT NULL");

            // ===== Restricciones CHECK (defensa en profundidad: las reglas
            // también se cumplen si los datos se modifican fuera de la aplicación)
            builder.Entity<Proyecto>().ToTable(t =>
            {
                t.HasCheckConstraint("CK_Proyectos_Area", "[Area] BETWEEN 1 AND 3");
                t.HasCheckConstraint("CK_Proyectos_Estado", "[Estado] BETWEEN 1 AND 3");
                t.HasCheckConstraint("CK_Proyectos_Fechas",
                    "[FechaInicio] IS NULL OR [FechaEntrega] IS NULL OR [FechaEntrega] >= [FechaInicio]");
            });

            builder.Entity<Tarea>().ToTable(t =>
            {
                t.HasCheckConstraint("CK_Tareas_PorcentajeAvance", "[PorcentajeAvance] BETWEEN 0 AND 100");
                t.HasCheckConstraint("CK_Tareas_Estado", "[Estado] BETWEEN 1 AND 3");
                t.HasCheckConstraint("CK_Tareas_Prioridad", "[Prioridad] BETWEEN 1 AND 3");
                t.HasCheckConstraint("CK_Tareas_Fechas",
                    "[FechaInicio] IS NULL OR [FechaLimite] IS NULL OR [FechaLimite] >= [FechaInicio]");
            });

            builder.Entity<TareaAvance>().ToTable(t =>
            {
                t.HasCheckConstraint("CK_TareaAvances_PorcentajeAvance", "[PorcentajeAvance] BETWEEN 0 AND 100");
                t.HasCheckConstraint("CK_TareaAvances_Estado", "[Estado] BETWEEN 1 AND 3");
            });

            builder.Entity<Trabajador>().ToTable(t =>
                t.HasCheckConstraint("CK_Trabajadores_Area", "[Area] BETWEEN 1 AND 3"));
        }
    }
}
