# Preparación para producción

> **Estado real:** el sistema está **listo para ejecutarse localmente** (Visual Studio 2022, F5).
> La compilación Release y la publicación se **verificaron en este equipo**, incluida la ejecución del paquete
> publicado en modo *Production* sobre la base local. **No se ha desplegado en ningún servidor** ni se han
> configurado HTTPS con certificado real, la cuenta de base de datos dedicada, el correo ni el monitoreo.
> Esos pasos (sección 5) son necesarios antes de considerarlo en producción.

## 1. Compilación Release (verificada)

```
dotnet build GestionFTTH.sln -c Release
```

Resultado del 19/11/2026: **0 errores, 0 advertencias**.

## 2. Publicación (verificada localmente)

```
dotnet publish GestionFTTH.Web/GestionFTTH.Web.csproj -c Release -o <carpeta_de_publicacion>
```

Contenido verificado del paquete (394 archivos, ~86 MB, *framework-dependent*: requiere el runtime de ASP.NET Core 8 en el servidor):

| Elemento | Incluido |
|---|---|
| `GestionFTTH.Web.dll` / `.exe`, dependencias (EF Core, Identity, ML.NET y bibliotecas nativas) | ✔ |
| `wwwroot/` (CSS, JS, Bootstrap, jQuery Validation) | ✔ |
| `MLModels/` (`DatosEntrenamiento.csv`, `ModeloRetraso.zip`, `ModeloRetraso.json`, LEEME) | ✔ (configurado en el `.csproj`) |
| `appsettings.json`, `appsettings.Production.json` | ✔ |
| `appsettings.Development.json` | Se publica pero solo se usa si `ASPNETCORE_ENVIRONMENT=Development` |

**Prueba del paquete publicado en modo Production (local, puerto 5299):**
- Arranca y carga el modelo ML.NET desde la carpeta publicada.
- Sirve el login y los archivos estáticos (200).
- `/Tareas` sin sesión redirige al login; el registro público está bloqueado.
- Las rutas inexistentes devuelven 404 con página en español.
- No se expone la página de excepciones de desarrollo.
- **No modificó ningún dato** (usuarios, tareas, proyectos y migraciones idénticos antes y después).
- Advertencia esperada: "Failed to determine the https port for redirect", porque la prueba fue solo HTTP. En el servidor se resuelve con un enlace HTTPS.

## 3. Comportamiento según el entorno

| Aspecto | Development (F5) | Production |
|---|---|---|
| Migraciones | Automáticas al iniciar | **No automáticas**: ejecutar `Despliegue/GestionFTTH_migraciones_idempotente.sql` o `dotnet ef database update` |
| Administrador inicial | Obligatorio desde *user secrets* | Opcional: solo si se definen `AdminInicial__Email` y `AdminInicial__Password`; eliminarlas tras el primer arranque |
| Errores | Página detallada de desarrollo | Página genérica `/Home/Error` (sin detalles técnicos) y HSTS |
| Logs | Information | `appsettings.Production.json`: Warning (Information para `GestionFTTH.Web`) |
| Entrenamiento ML inicial | Si falta el modelo | Igual (si falta `ModeloRetraso.zip`) |

El entorno lo define la variable `ASPNETCORE_ENVIRONMENT`. Si no existe, es **Production**.

## 4. Logs y excepciones

- **Proveedores de log:** consola y, en Windows, el **Registro de eventos** (*Visor de eventos → Aplicación*, origen ".NET Runtime" / ASP.NET Core), que añade el host por defecto.
- Con **IIS**, para capturar la salida de consola, active en `web.config` `stdoutLogEnabled="true"` y `stdoutLogFile=".\logs\stdout"` (cree la carpeta `logs` con permiso de escritura para el AppPool). No lo deje activo indefinidamente.
- La aplicación registra con `ILogger`:
  - errores de entrenamiento y de carga del modelo,
  - errores al guardar (`DbUpdateException`),
  - modelos descartados por baja calidad,
  - bloqueos de cuenta,
  - el procesamiento del administrador inicial.
- Excepciones no controladas: `UseExceptionHandler("/Home/Error")` muestra un código de referencia (Request ID) para buscarlo en los logs.

## 5. Lista de verificación antes de producción

| # | Paso | Estado |
|---|---|---|
| 1 | Servidor con **ASP.NET Core Runtime 8 Hosting Bundle** (IIS) o un servicio Windows/Kestrel detrás de un proxy | Pendiente |
| 2 | **HTTPS** con un certificado válido y enlace en IIS; quitar `TrustServerCertificate=True` si SQL tiene certificado válido | Pendiente |
| 3 | `ASPNETCORE_ENVIRONMENT=Production` (o sin definir) | Pendiente |
| 4 | Cadena de conexión del servidor en la variable `ConnectionStrings__DefaultConnection` | Pendiente |
| 5 | Cuenta de BD con **permisos mínimos** (`Despliegue/crear_login_aplicacion.sql`; hoy la app usa una cuenta **sysadmin** de desarrollo) | Pendiente |
| 6 | Aplicar migraciones con una cuenta administradora (`Despliegue/GestionFTTH_migraciones_idempotente.sql`, 9 migraciones, sin `DROP TABLE`) | Pendiente |
| 7 | Crear el administrador inicial (variables `AdminInicial__*` en el primer arranque y eliminarlas después). Recuperación de acceso: `docs/ACCESO_ADMINISTRADOR.md` | Pendiente |
| 8 | Permiso de **escritura** del AppPool sobre `MLModels/` (reentrenamiento) y `logs/` (si se usa stdout) | Pendiente |
| 9 | **Respaldos programados** de la base (Programador de tareas; Express no tiene Agente SQL) y de `MLModels/` | Pendiente |
| 10 | Servicio de correo, si se necesita recuperación de contraseña | Pendiente (sección 7) |
| 11 | Revisión de las protecciones de **Data Protection** si hay varias instancias (claves compartidas) | Pendiente / no aplica con una instancia |

## 6. Persistencia del modelo ML.NET

- El modelo vive en `<carpeta de la aplicación>/MLModels/ModeloRetraso.zip` (+ `.json`). La ruta es configurable en `MachineLearning:RutaModelo` (relativa a la carpeta de la aplicación).
- **Al republicar**, el paquete trae el `ModeloRetraso.zip` del proyecto, que es el **demostrativo**. Si en el servidor ya se entrenó un modelo **real**, respalde `MLModels/ModeloRetraso.*` antes de publicar y restáurelo después, o excluya esa carpeta de la copia.
- El reentrenamiento escribe primero un archivo temporal, verifica que cargue y luego reemplaza. Si falla, el modelo anterior queda intacto.

## 7. Mejoras pendientes

| Mejora | Detalle | Por qué no se implementó |
|---|---|---|
| **Servicio de correo** (recuperación de contraseña, confirmación de correo) | Implementar `IEmailSender` con un proveedor SMTP | Requiere un servidor SMTP y credenciales que deben configurarse y autorizarse. Mientras tanto, un administrador cambia contraseñas desde *Usuarios → Editar* |
| **Control de concurrencia** | Agregar columnas `rowversion` (concurrencia optimista) a Proyectos, Tareas y Trabajadores y manejar `DbUpdateConcurrencyException` | Hoy, si dos usuarios editan el mismo registro, gana el último en guardar. Cambia el esquema y los formularios; se dejó para una iteración controlada |
| **Traducción de Identity** | Páginas de *Administrar cuenta* (perfil, correo, contraseña, 2FA, datos personales) | Login, bloqueo, acceso denegado y errores ya están en español |
| **Pruebas en Firefox y Safari** | Las pruebas visuales se hicieron con Edge (Chromium) en escritorio (1366 px) y móvil (390 px) | No disponibles en el equipo de pruebas |
| **ML.NET con datos reales** | Reentrenar cuando haya ≥ 60 registros históricos de tareas finalizadas (ver `MANUAL_MLNET.md`) | La base aún no tiene historial real; el modelo funciona en modo **demostrativo** |
