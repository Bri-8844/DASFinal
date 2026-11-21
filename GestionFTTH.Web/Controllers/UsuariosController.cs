
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Data;
using GestionFTTH.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GestionFTTH.Web.Controllers
{
    [Authorize(Roles = Roles.Administradores)]
    public class UsuariosController : Controller
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UsuariosController> _logger;

        public UsuariosController(
            UserManager<ApplicationUser> userManager,
            ApplicationDbContext context,
            ILogger<UsuariosController> logger)
        {
            _userManager = userManager;
            _context = context;
            _logger = logger;
        }

        private bool EsAdministradorPrincipal =>
            User.IsInRole(Roles.AdministradorPrincipal);

        // GET: Usuarios
        public async Task<IActionResult> Index()
        {
            var usuarios = await _userManager.Users
                .AsNoTracking()
                .Include(u => u.Trabajador)
                .OrderBy(u => u.UserName)
                .ToListAsync();

            // Roles de todos los usuarios en una sola consulta (evita N+1)
            var rolesUsuarios = await (
                from ur in _context.UserRoles
                join r in _context.Roles on ur.RoleId equals r.Id
                select new { ur.UserId, r.Name })
                .ToListAsync();

            ViewBag.RolesUsuarios = rolesUsuarios
                .GroupBy(x => x.UserId)
                .ToDictionary(g => g.Key, g => g.First().Name ?? "Sin rol");

            ViewBag.UsuarioActualId = _userManager.GetUserId(User);
            ViewBag.EsAdministradorPrincipal = EsAdministradorPrincipal;

            return View(usuarios);
        }

        // GET: Usuarios/Create
        [HttpGet]
        public async Task<IActionResult> Create()
        {
            await CargarListasAsync();

            return View(new CrearUsuarioViewModel());
        }

        // POST: Usuarios/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            CrearUsuarioViewModel modelo)
        {
            modelo.Email = modelo.Email?.Trim() ?? string.Empty;

            await ValidarRolYTrabajadorAsync(
                modelo.Rol, modelo.TrabajadorId, usuarioId: null);

            if (!Roles.RequiereTrabajador(modelo.Rol))
            {
                modelo.TrabajadorId = null;
            }

            if (!ModelState.IsValid)
            {
                await CargarListasAsync();
                return View(modelo);
            }

            // Las cuentas creadas por un administrador quedan confirmadas:
            // RequireConfirmedAccount = true y no hay servicio de correo.
            var usuario = new ApplicationUser
            {
                UserName = modelo.Email,
                Email = modelo.Email,
                EmailConfirmed = true,
                TrabajadorId = modelo.TrabajadorId
            };

            var resultado = await _userManager.CreateAsync(
                usuario, modelo.Password);

            if (!resultado.Succeeded)
            {
                AgregarErrores(resultado);
                await CargarListasAsync();
                return View(modelo);
            }

            var resultadoRol = await _userManager.AddToRoleAsync(
                usuario, modelo.Rol);

            if (!resultadoRol.Succeeded)
            {
                // Evitar dejar una cuenta sin rol
                await _userManager.DeleteAsync(usuario);

                AgregarErrores(resultadoRol);
                await CargarListasAsync();
                return View(modelo);
            }

            TempData["MensajeExito"] =
                $"El usuario {usuario.Email} se registró correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // GET: Usuarios/Edit/{id}
        [HttpGet]
        public async Task<IActionResult> Edit(string id)
        {
            var usuario = await _userManager.FindByIdAsync(id);

            if (usuario == null)
            {
                return NotFound();
            }

            var rolActual = (await _userManager.GetRolesAsync(usuario)).FirstOrDefault() ?? "";

            if (!PuedeAdministrar(rolActual))
            {
                return Forbid();
            }

            await CargarListasAsync(usuario.TrabajadorId);

            return View(new EditarUsuarioViewModel
            {
                Id = usuario.Id,
                Email = usuario.Email ?? "",
                Rol = rolActual,
                TrabajadorId = usuario.TrabajadorId
            });
        }

        // POST: Usuarios/Edit/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(
            string id,
            EditarUsuarioViewModel modelo)
        {
            if (id != modelo.Id)
            {
                return BadRequest();
            }

            var usuario = await _userManager.FindByIdAsync(id);

            if (usuario == null)
            {
                return NotFound();
            }

            var rolActual = (await _userManager.GetRolesAsync(usuario)).FirstOrDefault() ?? "";

            if (!PuedeAdministrar(rolActual))
            {
                return Forbid();
            }

            modelo.Email = modelo.Email?.Trim() ?? string.Empty;

            await ValidarRolYTrabajadorAsync(modelo.Rol, modelo.TrabajadorId, usuario.Id);

            if (!Roles.RequiereTrabajador(modelo.Rol))
            {
                modelo.TrabajadorId = null;
            }

            // Un responsable con tareas activas debe seguir siendo Trabajador
            if (rolActual == Roles.Trabajador && modelo.Rol != Roles.Trabajador)
            {
                int activas = await _context.Tareas.CountAsync(t =>
                    t.ResponsableId == usuario.Id && t.Estado != EstadoTarea.Finalizada);

                if (activas > 0)
                {
                    ModelState.AddModelError(nameof(modelo.Rol),
                        $"El usuario es responsable de {activas} tarea(s) activa(s). " +
                        "Reasígnelas antes de cambiar su rol.");
                }
            }

            // No dejar el sistema sin administrador principal
            if (rolActual == Roles.AdministradorPrincipal &&
                modelo.Rol != Roles.AdministradorPrincipal &&
                await ContarAdministradoresPrincipalesAsync() <= 1)
            {
                ModelState.AddModelError(nameof(modelo.Rol),
                    "No puede cambiar el rol del único administrador principal.");
            }

            if (!ModelState.IsValid)
            {
                await CargarListasAsync(usuario.TrabajadorId);
                return View(modelo);
            }

            // Datos básicos
            bool cambioCorreo = !string.Equals(usuario.Email, modelo.Email, StringComparison.OrdinalIgnoreCase);
            bool cambioTrabajador = usuario.TrabajadorId != modelo.TrabajadorId;

            if (cambioCorreo)
            {
                usuario.Email = modelo.Email;
                usuario.UserName = modelo.Email;
            }

            usuario.TrabajadorId = modelo.TrabajadorId;

            var resultado = await _userManager.UpdateAsync(usuario);

            if (!resultado.Succeeded)
            {
                AgregarErrores(resultado);
                await CargarListasAsync(usuario.TrabajadorId);
                return View(modelo);
            }

            // Rol
            if (rolActual != modelo.Rol)
            {
                if (!string.IsNullOrEmpty(rolActual))
                {
                    await _userManager.RemoveFromRoleAsync(usuario, rolActual);
                }

                var resultadoRol = await _userManager.AddToRoleAsync(usuario, modelo.Rol);

                if (!resultadoRol.Succeeded)
                {
                    // Restaurar el rol anterior
                    if (!string.IsNullOrEmpty(rolActual))
                    {
                        await _userManager.AddToRoleAsync(usuario, rolActual);
                    }

                    AgregarErrores(resultadoRol);
                    await CargarListasAsync(usuario.TrabajadorId);
                    return View(modelo);
                }
            }

            // Contraseña (opcional). ResetPasswordAsync también renueva el security stamp.
            if (!string.IsNullOrWhiteSpace(modelo.NuevaPassword))
            {
                var token = await _userManager.GeneratePasswordResetTokenAsync(usuario);
                var resultadoClave = await _userManager.ResetPasswordAsync(
                    usuario, token, modelo.NuevaPassword);

                if (!resultadoClave.Succeeded)
                {
                    AgregarErrores(resultadoClave);
                    await CargarListasAsync(usuario.TrabajadorId);
                    return View(modelo);
                }
            }
            else if (rolActual != modelo.Rol || cambioCorreo || cambioTrabajador)
            {
                // Invalida las sesiones abiertas del usuario para que los
                // nuevos permisos se apliquen de inmediato (máx. 1 minuto)
                await _userManager.UpdateSecurityStampAsync(usuario);
            }

            TempData["MensajeExito"] =
                $"El usuario {usuario.Email} se actualizó correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // POST: Usuarios/Delete/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(string id)
        {
            var usuario = await _userManager.FindByIdAsync(id);

            if (usuario == null)
            {
                return NotFound();
            }

            if (usuario.Id == _userManager.GetUserId(User))
            {
                TempData["MensajeError"] = "No puede eliminar su propia cuenta.";
                return RedirectToAction(nameof(Index));
            }

            var rolActual = (await _userManager.GetRolesAsync(usuario)).FirstOrDefault() ?? "";

            if (!PuedeAdministrar(rolActual))
            {
                return Forbid();
            }

            if (rolActual == Roles.AdministradorPrincipal &&
                await ContarAdministradoresPrincipalesAsync() <= 1)
            {
                TempData["MensajeError"] =
                    "No puede eliminar al único administrador principal.";
                return RedirectToAction(nameof(Index));
            }

            // Las tareas asignadas quedan "Sin asignar" (FK con SET NULL)
            var resultado = await _userManager.DeleteAsync(usuario);

            if (!resultado.Succeeded)
            {
                _logger.LogWarning("No se pudo eliminar el usuario {UsuarioId}.", id);

                TempData["MensajeError"] =
                    "No se pudo eliminar el usuario: " +
                    string.Join(" ", resultado.Errors.Select(e => e.Description));

                return RedirectToAction(nameof(Index));
            }

            TempData["MensajeExito"] =
                $"El usuario {usuario.Email} se eliminó correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // POST: Usuarios/Desbloquear/{id}  (cuentas bloqueadas por intentos fallidos)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Desbloquear(string id)
        {
            var usuario = await _userManager.FindByIdAsync(id);

            if (usuario == null)
            {
                return NotFound();
            }

            var rolActual = (await _userManager.GetRolesAsync(usuario)).FirstOrDefault() ?? "";

            if (!PuedeAdministrar(rolActual))
            {
                return Forbid();
            }

            await _userManager.SetLockoutEndDateAsync(usuario, null);
            await _userManager.ResetAccessFailedCountAsync(usuario);

            TempData["MensajeExito"] = $"La cuenta {usuario.Email} se desbloqueó correctamente.";

            return RedirectToAction(nameof(Index));
        }

        // ===================== Reglas =====================

        // Solo un administrador principal puede crear/gestionar administradores principales
        private bool PuedeAdministrar(string rolObjetivo) =>
            rolObjetivo != Roles.AdministradorPrincipal || EsAdministradorPrincipal;

        private async Task<int> ContarAdministradoresPrincipalesAsync() =>
            (await _userManager.GetUsersInRoleAsync(Roles.AdministradorPrincipal)).Count;

        private async Task ValidarRolYTrabajadorAsync(
            string rol, int? trabajadorId, string? usuarioId)
        {
            if (!Roles.Lista.Contains(rol))
            {
                ModelState.AddModelError("Rol", "Seleccione un rol válido.");
                return;
            }

            if (rol == Roles.AdministradorPrincipal && !EsAdministradorPrincipal)
            {
                ModelState.AddModelError("Rol",
                    "Solo un administrador principal puede asignar ese rol.");
            }

            if (!Roles.RequiereTrabajador(rol))
            {
                return;
            }

            if (trabajadorId == null)
            {
                ModelState.AddModelError("TrabajadorId",
                    "Seleccione un trabajador.");
                return;
            }

            bool existe = await _context.Trabajadores
                .AnyAsync(t => t.Id == trabajadorId.Value);

            bool ocupado = await _userManager.Users
                .AnyAsync(u => u.TrabajadorId == trabajadorId.Value &&
                               u.Id != usuarioId);

            if (!existe || ocupado)
            {
                ModelState.AddModelError("TrabajadorId",
                    "El trabajador no existe o ya tiene una cuenta.");
            }
        }

        // Trabajadores disponibles (sin cuenta) + el vinculado actualmente
        private async Task CargarListasAsync(int? trabajadorActual = null)
        {
            var idsOcupados = await _userManager.Users
                .Where(u => u.TrabajadorId != null && u.TrabajadorId != trabajadorActual)
                .Select(u => u.TrabajadorId!.Value)
                .ToListAsync();

            ViewBag.Trabajadores = await _context.Trabajadores
                .AsNoTracking()
                .Where(t => !idsOcupados.Contains(t.Id))
                .OrderBy(t => t.Apellidos)
                .ToListAsync();

            ViewBag.EsAdministradorPrincipal = EsAdministradorPrincipal;
        }

        private void AgregarErrores(IdentityResult resultado)
        {
            foreach (var error in resultado.Errors)
            {
                ModelState.AddModelError("", error.Description);
            }
        }
    }
}
