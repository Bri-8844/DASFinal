# Instalación y configuración

## 1. Requisitos

| Componente | Versión verificada | Notas |
|---|---|---|
| Windows | 10 Pro 22H2 | |
| Visual Studio | **2022** 17.14 (Community) | Carga "Desarrollo web y ASP.NET". **No usar VS 2019.** |
| SDK de .NET | 8.0.428 | Lo instala VS 2022; también disponible en https://dotnet.microsoft.com/download/dotnet/8.0 |
| SQL Server | 2019 Express (15.0), instancia `SQLEXPRESS` | Cualquier SQL Server 2016 o superior es compatible |
| Herramienta EF (opcional) | dotnet-ef 8.0.x | `dotnet tool install --global dotnet-ef --version 8.0.*` |

## 2. SQL Server Express

1. Instalar SQL Server Express con el nombre de instancia **SQLEXPRESS** y **autenticación de Windows**.
2. Verificar que el servicio esté iniciado: `services.msc` → **SQL Server (SQLEXPRESS)** → En ejecución.
   Desde PowerShell: `Get-Service 'MSSQL$SQLEXPRESS'`
3. La cuenta de Windows con la que se ejecuta la aplicación debe tener acceso al servidor. En desarrollo se usa la
   cuenta del propio usuario.
4. **No hace falta crear la base de datos a mano**: las migraciones la crean.

Prueba de conexión:

```
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "SELECT @@VERSION"
```

## 3. Cadena de conexión

Está en `GestionFTTH.Web/appsettings.json`:

```json
"ConnectionStrings": {
  "DefaultConnection": "Server=localhost\\SQLEXPRESS;Database=GestionFTTH;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
}
```

| Parte | Significado |
|---|---|
| `Server=localhost\SQLEXPRESS` | Servidor e instancia |
| `Database=GestionFTTH` | Nombre de la base |
| `Trusted_Connection=True` | Autenticación de Windows (sin usuario ni contraseña en el archivo) |
| `TrustServerCertificate=True` | Acepta el certificado autofirmado de SQL Express. En producción, use un certificado válido y quítelo. |

**Cambiar la conexión sin editar el archivo** (recomendado en servidores): variable de entorno

```
setx ConnectionStrings__DefaultConnection "Server=MI_SERVIDOR\INSTANCIA;Database=GestionFTTH;Trusted_Connection=True;Encrypt=True"
```

> Si alguna vez se usa autenticación SQL (usuario y contraseña), **no** la escriba en `appsettings.json`.
> Use *user secrets* en desarrollo o variables de entorno en el servidor.

## 4. Administrador inicial

La primera cuenta (rol **AdministradorPrincipal**) se crea automáticamente al iniciar la aplicación con las
credenciales configuradas. **Las credenciales nunca se guardan en archivos del proyecto.**

### En desarrollo (Visual Studio): *user secrets*

Clic derecho en el proyecto `GestionFTTH.Web` → **Administrar secretos de usuario**, o en una terminal dentro de
`GestionFTTH.Web`:

```
dotnet user-secrets set "AdminInicial:Email" "admin@su-dominio.com"
dotnet user-secrets set "AdminInicial:Password" "<contraseña segura>"
```

- La contraseña debe tener al menos 6 caracteres, con mayúscula, minúscula, número y símbolo.
- Los secretos se guardan en `%APPDATA%\Microsoft\UserSecrets\aspnet-GestionFTTH.Web-0325aa81-…\secrets.json`, fuera del proyecto.
- En Development son **obligatorios**: sin ellos la aplicación no arranca y muestra
  "Faltan las credenciales del administrador inicial".
- Si la cuenta ya existe, no se modifica (no cambia la contraseña). Para cambiarla use *Administrar cuenta → Password*.

### En producción: variables de entorno solo para el primer arranque

```
AdminInicial__Email    = admin@su-dominio.com
AdminInicial__Password = <contraseña segura>
```

Inicie la aplicación una vez y **elimine las dos variables** (la aplicación registra una advertencia como recordatorio).
Si no se definen, en producción no se crea ninguna cuenta automáticamente.

> El administrador de este equipo de desarrollo se creó con una contraseña temporal. **Cámbiela** desde
> *Administrar cuenta → Password* antes de usar el sistema con datos reales. Cómo consultarla y cómo recuperar el
> acceso: [ACCESO_ADMINISTRADOR.md](ACCESO_ADMINISTRADOR.md).

## 5. Migraciones (estructura de la base de datos)

El proyecto usa EF Core code-first con **9 migraciones**, ninguna de las cuales elimina datos. La novena
(`NomenclaturaTablasIdentity`) renombra las tablas de Identity a español con `sp_rename`; ver
[DICCIONARIO_DE_DATOS.md](DICCIONARIO_DE_DATOS.md).

| Situación | Cómo aplicarlas |
|---|---|
| Desarrollo (F5 en VS) | **Automático** al iniciar en Development |
| Manualmente con la CLI | En la carpeta de la solución: `dotnet ef database update --project GestionFTTH.Web` |
| Visual Studio | *Herramientas → Administrador de paquetes NuGet → Consola*: `Update-Database` |
| Servidor sin SDK | Ejecutar `Despliegue/GestionFTTH_migraciones_idempotente.sql` en SSMS o `sqlcmd`. Es **idempotente**: solo aplica lo que falta. |

Regenerar el script idempotente tras crear nuevas migraciones:

```
dotnet ef migrations script --idempotent --project GestionFTTH.Web -o Despliegue/GestionFTTH_migraciones_idempotente.sql
```

Comprobar qué migraciones están aplicadas:

```
sqlcmd -S localhost\SQLEXPRESS -E -C -d GestionFTTH -Q "SELECT MigrationId FROM __EFMigrationsHistory"
```

## 6. Ejecutar

1. Abrir `GestionFTTH.sln` con **Visual Studio 2022**.
2. Perfil **https** o **http** (Development) → **F5**.
3. Se abre el navegador en la pantalla de inicio de sesión.

Alternativa por línea de comandos, desde la carpeta de la solución:

```
dotnet run --project GestionFTTH.Web --launch-profile https
```

## 7. Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| MSB3971 "No se han encontrado los ensamblados de referencia de .NETFramework,Version=v8.0" | Solución abierta con VS 2019 | Abrir con VS 2022 |
| "Cannot open database … Login failed" | La base no existe o no se aplicaron las migraciones | Iniciar en Development (las aplica) o ejecutar `dotnet ef database update` |
| "Faltan las credenciales del administrador inicial" | Faltan los *user secrets* | Ver la sección 4 |
| MSB3027 "No se pudo copiar … GestionFTTH.Web.exe" | La aplicación sigue en ejecución | Detener la depuración (Shift+F5) y recompilar |
| No aparece la predicción (No disponible) | Faltan fechas, la tarea no ha iniciado o está finalizada | Ver [MANUAL_MLNET.md](MANUAL_MLNET.md#4-cuando-se-muestra-no-disponible) |
