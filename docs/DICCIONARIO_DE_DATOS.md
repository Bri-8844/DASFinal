# Diccionario de datos — GestiónFTTH

**Base de datos:** `GestionFTTH` · **Servidor:** `localhost\SQLEXPRESS` · **Motor:** SQL Server 2019 Express
**Generado a partir de los metadatos reales** (`sys.tables`, `sys.columns`, `sys.foreign_keys`, `sys.indexes`, `sys.check_constraints`) el 19/11/2026, después de la migración `NomenclaturaTablasIdentity`.

## 1. Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Tablas | Español, PascalCase, plural para entidades y *EntidadRelación* para tablas de relación o detalle | `Usuarios`, `Tareas`, `UsuarioRoles`, `TareaAvances` |
| Clave primaria | `PK_<Tabla>` | `PK_Usuarios` |
| Clave foránea | `FK_<TablaOrigen>_<TablaDestino>_<Columna>` | `FK_Tareas_Usuarios_ResponsableId` |
| Índice | `IX_<Tabla>_<Columnas>` | `IX_Tareas_Codigo` |
| Restricción CHECK | `CK_<Tabla>_<Regla>` | `CK_Tareas_PorcentajeAvance` |
| Columnas de negocio | Español, PascalCase | `FechaLimite`, `PorcentajeAvance` |
| Columnas de seguridad (Identity) | Nombres estándar de ASP.NET Core Identity, en inglés | `UserName`, `PasswordHash` |

**Por qué las columnas de Identity conservan sus nombres en inglés:** sus tablas tienen nombres en español
(configurados con `ToTable` en `ApplicationDbContext`). Las columnas, en cambio, son las del esquema estándar de
ASP.NET Core Identity, y renombrarlas obligaría a reconfigurar cada propiedad y a apartarse del esquema que conoce
cualquier desarrollador .NET, con más riesgo y sin ganancia funcional. `__EFMigrationsHistory` es la tabla de control
de versiones de Entity Framework Core y conserva su nombre estándar.

**Historial:** hasta la migración `20261119180159_NomenclaturaTablasIdentity`, las tablas de Identity se llamaban
`AspNetUsers`, `AspNetRoles`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetRoleClaims`, `AspNetUserLogins` y
`AspNetUserTokens`. Se renombraron con `sp_rename`, conservando todos los datos e identificadores.

## 2. Modelo de relaciones

```
Proyectos 1 ──< Tareas >── 0..1 Usuarios (Responsable)
                   │
                   └──< TareaAvances

Trabajadores 1 ── 0..1 Usuarios (cuenta vinculada)

Usuarios 1 ──< UsuarioRoles >── 1 Roles ──< RolClaims
Usuarios 1 ──< UsuarioClaims
Usuarios 1 ──< UsuarioLogins
Usuarios 1 ──< UsuarioTokens
```

| Relación | Cardinalidad | Al eliminar el registro padre |
|---|---|---|
| Proyectos → Tareas | 1 : N | **Restringido**: no se puede eliminar un proyecto con tareas |
| Usuarios → Tareas (responsable) | 1 : N | Las tareas quedan **sin asignar** (`SET NULL`) |
| Tareas → TareaAvances | 1 : N | El historial se elimina con la tarea (`CASCADE`) |
| Trabajadores → Usuarios | 1 : 0..1 | **Restringido**: no se puede eliminar un trabajador con cuenta. Índice único: un trabajador, como máximo una cuenta |
| Usuarios → UsuarioRoles / UsuarioClaims / UsuarioLogins / UsuarioTokens | 1 : N | `CASCADE` |
| Roles → UsuarioRoles / RolClaims | 1 : N | `CASCADE` |

## 3. Tablas de negocio

### 3.1 Proyectos
Proyectos FTTH: unidad de trabajo que agrupa tareas, clasificada por área.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| Codigo | nvarchar(30) | No | Único (`IX_Proyectos_Codigo`) | Código del proyecto (se guarda en mayúsculas) |
| Nombre | nvarchar(150) | No | | Nombre |
| Descripcion | nvarchar(1000) | Sí | | Descripción |
| Area | int | No | | 1 = Prediseño, 2 = Diseño, 3 = Construcción (`CK_Proyectos_Area`) |
| Estado | int | No | | 1 = Pendiente, 2 = En ejecución, 3 = Finalizado (`CK_Proyectos_Estado`) |
| FechaInicio | datetime2 | Sí | | Inicio previsto |
| FechaEntrega | datetime2 | Sí | | Entrega prevista; ≥ FechaInicio (`CK_Proyectos_Fechas`) |
| FechaRegistro | datetime2 | No | | Fecha de registro (UTC) |

**Referenciada por:** `Tareas.ProyectoId`.

### 3.2 Tareas
Actividades de un proyecto asignadas a un trabajador. Objeto de la predicción de riesgo ML.NET.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| Codigo | nvarchar(30) | No | Único (`IX_Tareas_Codigo`) | Código de la tarea |
| Titulo | nvarchar(150) | No | | Título |
| Descripcion | nvarchar(1000) | Sí | | Descripción |
| ProyectoId | int | No | **FK → Proyectos.Id** (NO ACTION) | Proyecto al que pertenece |
| ResponsableId | nvarchar(450) | Sí | **FK → Usuarios.Id** (SET NULL) | Usuario responsable (rol Trabajador) |
| Estado | int | No | | 1 = Pendiente, 2 = En ejecución, 3 = Finalizada (`CK_Tareas_Estado`) |
| Prioridad | int | No | | 1 = Baja, 2 = Media, 3 = Alta (`CK_Tareas_Prioridad`) |
| FechaInicio | datetime2 | Sí | | Inicio planificado (obligatoria en la aplicación) |
| FechaLimite | datetime2 | Sí | | Fecha límite; ≥ FechaInicio (`CK_Tareas_Fechas`) |
| PorcentajeAvance | int | No | | 0–100 (`CK_Tareas_PorcentajeAvance`) |
| FechaRegistro | datetime2 | No | | Fecha de registro (UTC) |
| FechaFinalizacion | datetime2 | Sí | | Fecha real de cierre. **Etiqueta** del modelo ML (retraso = FechaFinalizacion > FechaLimite) |

**Índices adicionales:** `IX_Tareas_ProyectoId`, `IX_Tareas_ResponsableId`. **Referenciada por:** `TareaAvances.TareaId`.

### 3.3 TareaAvances
Historial diario del avance de cada tarea (un registro por tarea y día). Es la fuente de datos **sin fuga de
información futura** para entrenar ML.NET.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| TareaId | int | No | **FK → Tareas.Id** (CASCADE) | Tarea |
| Fecha | datetime2 | No | | Día del registro |
| PorcentajeAvance | int | No | | Avance en ese día, 0–100 (`CK_TareaAvances_PorcentajeAvance`) |
| Estado | int | No | | Estado en ese día, 1–3 (`CK_TareaAvances_Estado`) |
| RegistradoPorId | nvarchar(450) | Sí | | Usuario que registró el avance (referencia informativa, sin FK, para conservar el historial aunque se elimine el usuario) |
| FechaInicioPlan | datetime2 | Sí | | Fecha de inicio **vigente ese día** |
| FechaLimitePlan | datetime2 | Sí | | Fecha límite **vigente ese día** |
| Prioridad | int | Sí | | Prioridad **vigente ese día** |

**Índice:** `IX_TareaAvances_TareaId_Fecha` (TareaId, Fecha).

### 3.4 Trabajadores
Personal de la empresa. Puede tener como máximo una cuenta de usuario.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| Codigo | nvarchar(20) | No | Único (`IX_Trabajadores_Codigo`) | Código generado: `TRB0001`… |
| Nombres | nvarchar(100) | No | | Nombres |
| Apellidos | nvarchar(100) | No | | Apellidos |
| Area | int | No | | 1 = Prediseño, 2 = Diseño, 3 = Construcción (`CK_Trabajadores_Area`). Define el alcance de un Jefe de área |
| Cargo | nvarchar(100) | No | | Cargo |

**Referenciada por:** `Usuarios.TrabajadorId`.

## 4. Tablas de seguridad (ASP.NET Core Identity)

### 4.1 Usuarios
Cuentas de acceso al sistema.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | nvarchar(450) | No | **PK** | Identificador (GUID en texto) |
| UserName | nvarchar(256) | Sí | | Nombre de usuario (igual al correo) |
| NormalizedUserName | nvarchar(256) | Sí | Único (`UserNameIndex`) | Nombre de usuario normalizado (búsqueda) |
| Email | nvarchar(256) | Sí | | Correo |
| NormalizedEmail | nvarchar(256) | Sí | `EmailIndex` | Correo normalizado (único a nivel de aplicación: `RequireUniqueEmail`) |
| EmailConfirmed | bit | No | | Cuenta confirmada (obligatorio para iniciar sesión) |
| PasswordHash | nvarchar(max) | Sí | | Contraseña **cifrada** por Identity (PBKDF2). Nunca se almacena en texto plano |
| SecurityStamp | nvarchar(max) | Sí | | Cambia con la contraseña o el rol; invalida las sesiones abiertas |
| ConcurrencyStamp | nvarchar(max) | Sí | | Control de concurrencia de Identity |
| PhoneNumber | nvarchar(max) | Sí | | Teléfono |
| PhoneNumberConfirmed | bit | No | | Teléfono confirmado |
| TwoFactorEnabled | bit | No | | Autenticación en dos pasos activa |
| LockoutEnd | datetimeoffset | Sí | | Fin del bloqueo por intentos fallidos |
| LockoutEnabled | bit | No | | La cuenta admite bloqueo |
| AccessFailedCount | int | No | | Intentos fallidos consecutivos (bloqueo a los 5) |
| TrabajadorId | int | Sí | **FK → Trabajadores.Id** (NO ACTION); único filtrado (`IX_Usuarios_TrabajadorId`) | Trabajador vinculado (obligatorio para Jefe de área y Trabajador) |

**Referenciada por:** `Tareas.ResponsableId`, `UsuarioRoles`, `UsuarioClaims`, `UsuarioLogins`, `UsuarioTokens`.

### 4.2 Roles
Roles del sistema: `AdministradorPrincipal`, `AdministradorGerencia`, `JefeArea` y `Trabajador`. Los crea el seeder al iniciar.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | nvarchar(450) | No | **PK** | Identificador |
| Name | nvarchar(256) | Sí | | Nombre del rol |
| NormalizedName | nvarchar(256) | Sí | Único filtrado (`RoleNameIndex`) | Nombre normalizado |
| ConcurrencyStamp | nvarchar(max) | Sí | | Control de concurrencia |

### 4.3 UsuarioRoles
Asignación de roles a usuarios (relación N:M; en GestiónFTTH, un rol por usuario).

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| UserId | nvarchar(450) | No | **PK** · **FK → Usuarios.Id** (CASCADE) | Usuario |
| RoleId | nvarchar(450) | No | **PK** · **FK → Roles.Id** (CASCADE); `IX_UsuarioRoles_RoleId` | Rol |

### 4.4 UsuarioClaims
Atributos adicionales (*claims*) de un usuario. Reservada por Identity; sin uso actual.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| UserId | nvarchar(450) | No | **FK → Usuarios.Id** (CASCADE); `IX_UsuarioClaims_UserId` | Usuario |
| ClaimType | nvarchar(max) | Sí | | Tipo de claim |
| ClaimValue | nvarchar(max) | Sí | | Valor |

### 4.5 RolClaims
Atributos (*claims*) asociados a un rol. Reservada por Identity; sin uso actual.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| Id | int (identidad) | No | **PK** | Identificador |
| RoleId | nvarchar(450) | No | **FK → Roles.Id** (CASCADE); `IX_RolClaims_RoleId` | Rol |
| ClaimType | nvarchar(max) | Sí | | Tipo de claim |
| ClaimValue | nvarchar(max) | Sí | | Valor |

### 4.6 UsuarioLogins
Inicios de sesión externos (Google, Microsoft…). Reservada por Identity; sin proveedores externos configurados.

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| LoginProvider | nvarchar(128) | No | **PK** | Proveedor |
| ProviderKey | nvarchar(128) | No | **PK** | Identificador del usuario en el proveedor |
| ProviderDisplayName | nvarchar(max) | Sí | | Nombre visible del proveedor |
| UserId | nvarchar(450) | No | **FK → Usuarios.Id** (CASCADE); `IX_UsuarioLogins_UserId` | Usuario |

### 4.7 UsuarioTokens
Tokens de autenticación de Identity (por ejemplo, la clave del autenticador de 2FA).

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| UserId | nvarchar(450) | No | **PK** · **FK → Usuarios.Id** (CASCADE) | Usuario |
| LoginProvider | nvarchar(128) | No | **PK** | Proveedor del token |
| Name | nvarchar(128) | No | **PK** | Nombre del token |
| Value | nvarchar(max) | Sí | | Valor |

## 5. Tabla técnica

### __EFMigrationsHistory
Control de versiones del esquema de Entity Framework Core (una fila por migración aplicada). **No editar manualmente.**

| Columna | Tipo | Nulo | Clave | Descripción |
|---|---|---|---|---|
| MigrationId | nvarchar(150) | No | **PK** | Migración aplicada |
| ProductVersion | nvarchar(32) | No | | Versión de EF Core |

**Migraciones aplicadas (9):** CreateIdentitySchema · CrearTablaProyectos · AgregarTablaTareas · AgregarTablaTrabajadores ·
AgregarTrabajadorIdAUsuarios · AuditoriaYMachineLearning · PlanVigenteEnAvances · RestriccionesCheck · NomenclaturaTablasIdentity.

## 6. Resumen de restricciones

| Tipo | Cantidad | Detalle |
|---|---|---|
| Claves primarias | 12 | Una por tabla |
| Claves foráneas | 10 | Todas confiables (`is_not_trusted = 0`) |
| Índices únicos (sin PK) | 6 | Códigos de Proyectos, Tareas y Trabajadores; `NormalizedUserName` (Usuarios) y `NormalizedName` (Roles); un trabajador por cuenta (`IX_Usuarios_TrabajadorId`) |
| Índices no únicos | 8 | `EmailIndex` y los índices de columnas FK (`IX_Tareas_ProyectoId`, `IX_Tareas_ResponsableId`, `IX_TareaAvances_TareaId_Fecha`, `IX_UsuarioRoles_RoleId`, `IX_UsuarioClaims_UserId`, `IX_UsuarioLogins_UserId`, `IX_RolClaims_RoleId`) |
| CHECK | 10 | Áreas, estados y prioridades 1–3; avances 0–100; orden de fechas |
| Procedimientos, vistas, funciones, triggers | 0 | Todo el acceso a datos se hace con EF Core (consultas parametrizadas) |
