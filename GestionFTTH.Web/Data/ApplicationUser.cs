
using GestionFTTH.Web.Models;
using Microsoft.AspNetCore.Identity;

namespace GestionFTTH.Web.Data
{
    public class ApplicationUser : IdentityUser
    {
        // Trabajador vinculado (obligatorio para JefeArea y Trabajador)
        public int? TrabajadorId { get; set; }

        public Trabajador? Trabajador { get; set; }
    }
}
