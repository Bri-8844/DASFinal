using GestionFTTH.Web.Services;
using GestionFTTH.Web.Services.MachineLearning;
using GestionFTTH.Web.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.WebEncoders;
using System.Text.Encodings.Web;
using System.Text.Unicode;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();

// Agregamos .AddRoles<IdentityRole>(), que habilita la administración de roles en ASP.NET Core Identity.
builder.Services.AddDefaultIdentity<ApplicationUser>(options =>
{
    options.SignIn.RequireConfirmedAccount = true;

    // Bloqueo temporal tras intentos fallidos (protección contra fuerza bruta)
    options.Lockout.AllowedForNewUsers = true;
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);

    options.User.RequireUniqueEmail = true;
})
.AddRoles<IdentityRole>()
.AddErrorDescriber<IdentityErroresEspanol>()
.AddEntityFrameworkStores<ApplicationDbContext>();

// Sesión: cookie HttpOnly con expiración deslizante de 8 horas
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;
});

// Los cambios de rol, contraseña o la eliminación de una cuenta invalidan
// las sesiones abiertas en como máximo 1 minuto (por defecto: 30 minutos).
builder.Services.Configure<SecurityStampValidatorOptions>(options =>
    options.ValidationInterval = TimeSpan.FromMinutes(1));

// Políticas de autorización reutilizables
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(Roles.PoliticaAdministradores, policy =>
        policy.RequireRole(Roles.AdministradorPrincipal, Roles.AdministradorGerencia));

    // Páginas de Identity deshabilitadas para todos los usuarios
    options.AddPolicy(Roles.PoliticaDeshabilitado, policy =>
        policy.RequireAssertion(_ => false));
});

// Antifalsificación (CSRF) obligatoria en TODAS las peticiones POST de MVC,
// además de los [ValidateAntiForgeryToken] de cada acción.
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());

    // Mensajes de enlace de datos en español (servidor y validación en cliente)
    var m = options.ModelBindingMessageProvider;
    m.SetValueIsInvalidAccessor(v => $"El valor '{v}' no es válido.");
    m.SetAttemptedValueIsInvalidAccessor((v, campo) => $"El valor '{v}' no es válido para {campo}.");
    m.SetMissingBindRequiredValueAccessor(campo => $"Falta el valor de {campo}.");
    m.SetMissingKeyOrValueAccessor(() => "El valor es obligatorio.");
    m.SetMissingRequestBodyRequiredValueAccessor(() => "El cuerpo de la solicitud es obligatorio.");
    m.SetNonPropertyAttemptedValueIsInvalidAccessor(v => $"El valor '{v}' no es válido.");
    m.SetNonPropertyUnknownValueIsInvalidAccessor(() => "El valor indicado no es válido.");
    m.SetNonPropertyValueMustBeANumberAccessor(() => "El campo debe ser un número.");
    m.SetUnknownValueIsInvalidAccessor(campo => $"El valor indicado para {campo} no es válido.");
    m.SetValueMustBeANumberAccessor(campo => $"El campo {campo} debe ser un número.");
    m.SetValueMustNotBeNullAccessor(campo => $"El campo {campo} es obligatorio.");
});

// Emitir acentos y "ñ" tal cual en el HTML (sin entidades &#x..;); el contenido sigue codificado contra XSS.
builder.Services.Configure<WebEncoderOptions>(options =>
    options.TextEncoderSettings = new TextEncoderSettings(UnicodeRanges.All));

// Las cuentas solo se crean, modifican y eliminan desde el módulo Usuarios
// (con sus reglas de roles). Se deshabilitan las páginas de Identity que
// permitirían saltarse esas reglas:
//  - Register / RegisterConfirmation: crearían cuentas sin rol.
//  - Manage/DeletePersonalData: permitiría que un usuario (incluido el único
//    administrador principal) elimine su propia cuenta.
builder.Services.AddRazorPages(options =>
{
    options.Conventions.AuthorizeAreaPage("Identity", "/Account/Register", Roles.PoliticaDeshabilitado);
    options.Conventions.AuthorizeAreaPage("Identity", "/Account/RegisterConfirmation", Roles.PoliticaDeshabilitado);
    options.Conventions.AuthorizeAreaPage("Identity", "/Account/Manage/DeletePersonalData", Roles.PoliticaDeshabilitado);
});

// Alcance de datos por rol (qué tareas ve/gestiona cada usuario)
builder.Services.AddScoped<AlcanceUsuarioService>();

// ===== Machine Learning (ML.NET) =====
builder.Services.Configure<MachineLearningOptions>(
    builder.Configuration.GetSection(MachineLearningOptions.Seccion));

// Singleton: el modelo se carga una sola vez y se comparte (ITransformer es thread-safe);
// cada solicitud crea su propio PredictionEngine.
builder.Services.AddSingleton<TaskPredictionService>();
builder.Services.AddSingleton<TaskModelTrainer>();

// Entrena el modelo una única vez al iniciar si todavía no existe
builder.Services.AddHostedService<ModeloInicializador>();

var app = builder.Build();

// Herramienta de recuperación del Administrador principal (no inicia la web):
//   GestionFTTH.Web --restablecer-admin <correo> --confirmar
if (RecuperacionAdministrador.Solicitado(args))
{
    Environment.ExitCode = await RecuperacionAdministrador.EjecutarAsync(app.Services, args);
    return;
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// Página amigable para 404/400/... (solo para respuestas sin contenido)
app.UseStatusCodePagesWithReExecute("/Home/Estado", "?codigo={0}");

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// La autenticación identifica quién está ingresando al sistema, mientras que la autorización determina qué operaciones puede realizar
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
app.MapRazorPages();

using (var scope = app.Services.CreateScope())
{
    if (app.Environment.IsDevelopment())
    {
        // En desarrollo se aplican automáticamente las migraciones pendientes
        // (solo agregan estructura; no eliminan datos).
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await db.Database.MigrateAsync();
    }

    await IdentitySeeder.CrearRolesAsync(
        scope.ServiceProvider);

    if (app.Environment.IsDevelopment())
    {
        // Desarrollo: credenciales obligatorias en user secrets
        await IdentitySeeder.CrearAdminInicialAsync(
            scope.ServiceProvider,
            app.Configuration);
    }
    else if (!string.IsNullOrWhiteSpace(app.Configuration["AdminInicial:Email"]) &&
             !string.IsNullOrWhiteSpace(app.Configuration["AdminInicial:Password"]))
    {
        // Producción: solo si se configuraron explícitamente (variables de entorno
        // AdminInicial__Email / AdminInicial__Password) para el primer arranque.
        // Es idempotente: si la cuenta ya existe no la modifica.
        await IdentitySeeder.CrearAdminInicialAsync(
            scope.ServiceProvider,
            app.Configuration);

        app.Logger.LogWarning(
            "Se procesó el administrador inicial desde la configuración. " +
            "Elimine las variables AdminInicial__Email y AdminInicial__Password del servidor.");
    }
}

// Ejecutar una sola vez y solo en desarrollo: dotnet run -- --sembrar-demo
if (args.Contains("--sembrar-demo"))
{
    if (!app.Environment.IsDevelopment())
        throw new InvalidOperationException("Los datos demo solo se permiten en desarrollo.");

    using var scopeDemo = app.Services.CreateScope();
    await DatosDemoSeeder.EjecutarAsync(scopeDemo.ServiceProvider, app.Configuration);
    return; // No iniciar el servidor al terminar la carga.
}

app.Run();
