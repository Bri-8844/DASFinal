# Acceso del administrador

> Este documento **no contiene contraseñas**. Explica dónde están las credenciales y cómo recuperar el acceso de forma segura.

## 1. Cómo se creó el administrador

| Elemento | Detalle |
|---|---|
| Mecanismo | `Services/IdentitySeeder.cs` → `CrearAdminInicialAsync`, invocado desde `Program.cs` al iniciar la aplicación |
| Origen de las credenciales (desarrollo) | **User secrets** del usuario de Windows: claves `AdminInicial:Email` y `AdminInicial:Password` |
| Origen de las credenciales (producción) | Variables de entorno `AdminInicial__Email` y `AdminInicial__Password`, solo en el primer arranque |
| Archivos que **no** contienen credenciales (verificado) | `appsettings*.json`, migraciones, scripts SQL de `Despliegue/`, documentación e informes |
| Comportamiento | Si la cuenta no existe, la crea con el rol **AdministradorPrincipal** y el correo confirmado. Si ya existe, **no la modifica** (no cambia su contraseña) |

## 2. Cuenta existente (verificada en SQL Server el 19/11/2026)

| Campo | Valor |
|---|---|
| Correo / usuario | `admin@gestionftth.local` |
| Rol | AdministradorPrincipal |
| Estado | Confirmada, sin bloqueo, 0 intentos fallidos, con contraseña cifrada por Identity |
| Contraseña | **No se documenta.** Está en los *user secrets* de este equipo y **se comprobó que es válida**: el inicio de sesión con ella funciona |

## 3. Cómo consultar la contraseña actual (solo en este equipo)

La contraseña inicial se guardó en los *user secrets* del usuario de Windows que desarrolla el proyecto:

- **Visual Studio:** clic derecho en el proyecto `GestionFTTH.Web` → **Administrar secretos de usuario** → valor de `AdminInicial:Password`.
- **Terminal**, en la carpeta `GestionFTTH.Web`:
  ```
  dotnet user-secrets list
  ```
- **Archivo:** `%APPDATA%\Microsoft\UserSecrets\aspnet-GestionFTTH.Web-0325aa81-8359-4558-bf48-d63ddd21d7bd\secrets.json`

Ese archivo está **fuera de la carpeta del proyecto** y no forma parte del código ni de las copias de seguridad del proyecto.

> ⚠️ Esta contraseña se mostró en una conversación de soporte durante el desarrollo. **Considérela expuesta y cámbiela**
> (sección 4). Si la cambia desde la aplicación, el valor guardado en *user secrets* queda **desactualizado**: solo
> se usa para crear la cuenta la primera vez, no para iniciar sesión. Puede actualizarlo o eliminarlo; la cuenta ya existe.

## 4. Cambiar la contraseña (con acceso)

1. Iniciar sesión.
2. Menú superior (su correo) → **Administrar cuenta** → **Password**.
3. Ingresar la contraseña actual y la nueva: mínimo 6 caracteres, con mayúscula, minúscula, número y símbolo. Se recomiendan 12 o más.

El cambio renueva el *security stamp* y cierra las demás sesiones abiertas de esa cuenta.

## 5. Recuperar el acceso si se perdió la contraseña

Elija la primera opción disponible:

### Opción A: otro Administrador principal
*Usuarios → Editar* la cuenta → **Nueva contraseña**. Use *Desbloquear* si la cuenta está bloqueada.
(Un Gerente de operaciones no puede modificar Administradores principales.)

### Opción B: cuenta bloqueada (pero se conoce la contraseña)
Espere **5 minutos**, o pida a otro administrador que use **Desbloquear** en el módulo Usuarios.

### Opción C: herramienta de recuperación (sin otro administrador ni correo)
Restablece la contraseña de un **Administrador principal** con el mecanismo estándar de ASP.NET Core Identity
(token de restablecimiento). Requiere **acceso a la consola del equipo o servidor** y a la base de datos, por lo que
no está disponible desde la web.

**Desarrollo** (en la carpeta de la solución; detenga antes la depuración):
```
dotnet run --project GestionFTTH.Web -- --restablecer-admin admin@gestionftth.local --confirmar
```

**Servidor publicado** (en la carpeta de publicación, con la misma configuración de conexión que la aplicación):
```
GestionFTTH.Web.exe --restablecer-admin <correo del administrador> --confirmar
```

Qué hace:
1. Verifica que la cuenta exista y sea **Administrador principal**. Las demás cuentas se restablecen desde el módulo Usuarios.
2. Sin `--confirmar` solo informa lo que haría y **no cambia nada**.
3. Genera una **contraseña temporal aleatoria** de 20 caracteres con `RandomNumberGenerator` que cumple la política.
4. La aplica con `GeneratePasswordResetTokenAsync` + `ResetPasswordAsync`, desbloquea la cuenta y cierra sus sesiones abiertas.
5. **Muestra la contraseña temporal una sola vez en la consola.** No la guarda en archivos ni en los logs (el log de auditoría registra solo el correo y el hecho).
6. No inicia la aplicación web.

Después: inicie sesión con la contraseña temporal y **cámbiela de inmediato** (sección 4).

| Código de salida | Significado |
|---|---|
| 0 | Contraseña restablecida |
| 2 | Falta el correo (muestra el uso) |
| 3 | No existe una cuenta con ese correo |
| 4 | La cuenta no es Administrador principal |
| 5 | Falta `--confirmar` (no se hizo ningún cambio) |
| 6 | Identity rechazó el cambio (se muestran los motivos) |

> No ejecute la herramienta con la salida redirigida a un archivo ni con el registro *stdout* de IIS activo:
> la contraseña temporal se escribe en la consola.

**Verificación (19/11/2026)**: ejecutando el ensamblado compilado (`dotnet GestionFTTH.Web.dll --restablecer-admin …`, equivalente a las dos formas anteriores) sobre cuentas QA desechables y **sin tocar la cuenta real**: sin `--confirmar` no
cambia nada; rechaza correos inexistentes y cuentas que no son Administrador principal; con `--confirmar` la
contraseña temporal permite iniciar sesión y la anterior deja de funcionar; el log de auditoría no contiene la
contraseña; la contraseña del administrador real no se modificó (13/13 comprobaciones).

### Opción D: crear un nuevo Administrador principal (último recurso)
Si la cuenta se eliminó, defina nuevas credenciales de administrador inicial (*user secrets* en desarrollo o
variables `AdminInicial__*` en producción, con **otro correo**) e inicie la aplicación: se creará la cuenta.

## 6. Buenas prácticas
- Mantenga **al menos dos** Administradores principales, para poder restablecerse mutuamente.
- No comparta cuentas: cree una por persona en el módulo Usuarios.
- Active la autenticación en dos pasos (*Administrar cuenta → Two-factor authentication*) en las cuentas administrativas.
- No guarde contraseñas en `appsettings.json`, en scripts ni en documentos del proyecto.
