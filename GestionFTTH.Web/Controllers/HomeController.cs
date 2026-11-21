using System.Diagnostics;
using GestionFTTH.Web.Models;
using GestionFTTH.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace GestionFTTH.Web.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            if (!User.Identity?.IsAuthenticated ?? true)
            {
                return RedirectToPage(
                    "/Account/Login",
                    new { area = "Identity" });
            }

            // Cada rol entra a la pantalla que le corresponde
            if (User.IsInRole(Roles.AdministradorPrincipal) ||
                User.IsInRole(Roles.AdministradorGerencia))
            {
                return RedirectToAction("Index", "Dashboard");
            }

            if (User.IsInRole(Roles.JefeArea) ||
                User.IsInRole(Roles.Trabajador))
            {
                return RedirectToAction("Index", "Tareas");
            }

            // Usuario autenticado sin rol asignado
            return View("SinRol");
        }

        public IActionResult Privacy()
        {
            return View();
        }

        // Páginas de estado HTTP (404, 400, ...) en lugar de una respuesta vacía
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Estado(int codigo)
        {
            ViewBag.Codigo = codigo;
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
