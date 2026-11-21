
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Controllers
{
    [Authorize(Roles = Roles.Administradores)]
    public class TrabajadoresController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TrabajadoresController> _logger;

        public TrabajadoresController(
            ApplicationDbContext context,
            ILogger<TrabajadoresController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: Trabajadores
        public async Task<IActionResult> Index()
        {
            var trabajadores = await _context.Trabajadores
                .AsNoTracking()
                .OrderBy(t => t.Apellidos)
                .ThenBy(t => t.Nombres)
                .ToListAsync();

            // Cuentas de usuario vinculadas (para mostrar en el listado)
            ViewBag.Cuentas = await _context.Users
                .AsNoTracking()
                .Where(u => u.TrabajadorId != null)
                .ToDictionaryAsync(u => u.TrabajadorId!.Value, u => u.Email ?? u.UserName ?? "");

            return View(trabajadores);
        }

        // GET: Trabajadores/Details/1
        [HttpGet]
        public async Task<IActionResult> Details(int id)
        {
            var trabajador = await _context.Trabajadores
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == id);

            if (trabajador == null)
            {
                return NotFound();
            }

            var cuenta = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.TrabajadorId == id);

            ViewBag.Cuenta = cuenta;

            ViewBag.Tareas = cuenta == null
                ? new List<Tarea>()
                : await _context.Tareas
                    .AsNoTracking()
                    .Include(t => t.Proyecto)
                    .Where(t => t.ResponsableId == cuenta.Id)
                    .OrderBy(t => t.FechaLimite)
                    .ToListAsync();

            return View(trabajador);
        }

        // GET: Trabajadores/Create
        [HttpGet]
        public IActionResult Create()
        {
            return View(new Trabajador());
        }

        // POST: Trabajadores/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            [Bind("Nombres,Apellidos,Area,Cargo")]
            Trabajador trabajador)
        {
            Normalizar(trabajador);

            // El código se genera en el servidor
            ModelState.Remove(nameof(Trabajador.Codigo));

            ValidarArea(trabajador);

            if (!ModelState.IsValid)
            {
                return View(trabajador);
            }

            // Transacción para guardar el trabajador
            // y generar su código definitivo
            await using var transaccion =
                await _context.Database.BeginTransactionAsync();

            try
            {
                // Código temporal único (máx. 20 caracteres) para el índice único
                trabajador.Codigo = $"TMP{Guid.NewGuid():N}"[..20];

                _context.Trabajadores.Add(trabajador);
                await _context.SaveChangesAsync();

                // Código definitivo a partir del Id
                trabajador.Codigo = $"TRB{trabajador.Id:D4}";
                await _context.SaveChangesAsync();

                await transaccion.CommitAsync();

                TempData["MensajeExito"] =
                    $"El trabajador {trabajador.Codigo} se registró correctamente.";

                return RedirectToAction(nameof(Index));
            }
            catch (DbUpdateException ex)
            {
                await transaccion.RollbackAsync();

                _logger.LogError(ex, "Error al registrar un trabajador.");

                ModelState.AddModelError(
                    "",
                    "No se pudo registrar el trabajador. Intente nuevamente.");

                return View(trabajador);
            }
        }

        // GET: Trabajadores/Edit/1
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var trabajador = await _context.Trabajadores
                .FindAsync(id);

            if (trabajador == null)
            {
                return NotFound();
            }

            return View(trabajador);
        }

        // POST: Trabajadores/Edit/1
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(
            int id,
            [Bind("Id,Nombres,Apellidos,Area,Cargo")]
            Trabajador datos)
        {
            if (id != datos.Id)
            {
                return BadRequest();
            }

            var trabajador = await _context.Trabajadores
                .FindAsync(id);

            if (trabajador == null)
            {
                return NotFound();
            }

            // El código original no se modifica
            ModelState.Remove(nameof(Trabajador.Codigo));

            Normalizar(datos);
            ValidarArea(datos);

            if (!ModelState.IsValid)
            {
                datos.Codigo = trabajador.Codigo;
                return View(datos);
            }

            trabajador.Nombres = datos.Nombres;
            trabajador.Apellidos = datos.Apellidos;
            trabajador.Area = datos.Area;
            trabajador.Cargo = datos.Cargo;

            await _context.SaveChangesAsync();

            TempData["MensajeExito"] =
                "Los datos del trabajador se actualizaron correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // POST: Trabajadores/Delete/1
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var trabajador = await _context.Trabajadores
                .FindAsync(id);

            if (trabajador == null)
            {
                return NotFound();
            }

            // Integridad: no eliminar si tiene una cuenta de usuario vinculada
            var cuenta = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.TrabajadorId == id);

            if (cuenta != null)
            {
                TempData["MensajeError"] =
                    $"No se puede eliminar a {trabajador.Nombres} {trabajador.Apellidos} " +
                    $"porque tiene la cuenta de usuario {cuenta.Email} vinculada. " +
                    "Elimine o desvincule primero la cuenta en el módulo Usuarios.";

                return RedirectToAction(nameof(Index));
            }

            _context.Trabajadores.Remove(trabajador);

            await _context.SaveChangesAsync();

            TempData["MensajeExito"] =
                "El trabajador se eliminó correctamente.";

            return RedirectToAction(nameof(Index));
        }

        private static void Normalizar(Trabajador trabajador)
        {
            trabajador.Nombres = trabajador.Nombres?.Trim() ?? "";
            trabajador.Apellidos = trabajador.Apellidos?.Trim() ?? "";
            trabajador.Cargo = trabajador.Cargo?.Trim() ?? "";
        }

        private void ValidarArea(Trabajador trabajador)
        {
            if (!Enum.IsDefined(typeof(AreaProyecto), trabajador.Area))
            {
                ModelState.AddModelError(
                    nameof(Trabajador.Area),
                    "Seleccione un área válida.");
            }
        }
    }
}
