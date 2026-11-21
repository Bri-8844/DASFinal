# INFORME DE AUDITORÍA FINAL — GestiónFTTH

**Fecha:** 19/11/2026
**Alcance:**
- **Primera fase:** auditoría, reparación y finalización de los CRUD, conexión a SQL Server Express e implementación de ML.NET.
- **Segunda fase:** auditoría independiente de mi propio trabajo (funcional, seguridad, base de datos, ML.NET, visual y rendimiento), con corrección y nueva prueba de cada hallazgo.
- **Fase final:** cierre técnico, documentación, verificación de seguridad, preparación para producción, copias de seguridad y compilación Release (sección 0).
- **Normalización y acceso:** recuperación y documentación de las credenciales del administrador, herramienta segura de restablecimiento y nomenclatura en español de las tablas de Identity (sección A).

**Copias de seguridad** (todas se conservan; ver `docs/RESPALDO_Y_RESTAURACION.md`):
- Código original: `C:\GestionFTTH\Backup_GestionFTTH_20261119_012609`
- Antes de la segunda auditoría: `C:\GestionFTTH\Backup_GestionFTTH_Auditoria2_20261119_100601`
- Estado final: `C:\GestionFTTH\Backup_GestionFTTH_Final_20261119_124033` (verificado: compila en Release desde la copia)
- Base de datos: `C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\GestionFTTH_20261119_124033.bak` (verificado con restauración de prueba)

- Antes del renombrado de tablas: `C:\GestionFTTH\Backup_GestionFTTH_AntesRenombrado_20261119_130110` (código) y `…\MSSQL\Backup\GestionFTTH_AntesRenombrado_20261119_130110.bak` (base de datos, verificado con restauración de prueba)

---

## A. Normalización de la base de datos y acceso del administrador

### A.1 Credenciales del administrador
| Comprobación | Resultado |
|---|---|
| Cómo se creó | `IdentitySeeder.CrearAdminInicialAsync`, llamado desde `Program.cs`, con `AdminInicial:Email` y `AdminInicial:Password` de los **user secrets** del usuario de Windows (fuera del proyecto) |
| ¿Credenciales en `appsettings`, migraciones, scripts, variables de entorno o documentación? | **No** (verificado) |
| Cuenta en SQL Server | `admin@gestionftth.local`, rol AdministradorPrincipal, confirmada, sin bloqueo, con contraseña cifrada |
| ¿La contraseña original es recuperable? | **Sí**: está en los *user secrets* de este equipo y **se verificó que permite iniciar sesión**. **No se modificó** |
| Procedimiento de recuperación | Herramienta de consola `--restablecer-admin <correo> --confirmar` (`Services/RecuperacionAdministrador.cs`): token estándar de Identity, contraseña temporal aleatoria de 20 caracteres mostrada **una sola vez** en la consola, sin registrarla en logs. **Probada 13/13** con cuentas QA desechables |
| Documentación | `docs/ACCESO_ADMINISTRADOR.md` (sin contraseñas) |

### A.2 Nomenclatura de tablas
**Análisis previo:**
- 12 tablas, 12 PK, 10 FK y 14 índices.
- **0** procedimientos almacenados, vistas, funciones, triggers o sinónimos.
- El código C# no usaba los nombres `AspNet*` (todo pasa por EF Core). Solo los usaban scripts de prueba y el script SQL de despliegue, que se actualizaron.

**Decisión:** personalizar los nombres con la configuración oficial de EF Core Identity (`ToTable` en `ApplicationDbContext`) y una migración controlada.

| Antes | Después |
|---|---|
| AspNetUsers | **Usuarios** |
| AspNetRoles | **Roles** |
| AspNetUserRoles | **UsuarioRoles** |
| AspNetUserClaims | **UsuarioClaims** |
| AspNetRoleClaims | **RolClaims** |
| AspNetUserLogins | **UsuarioLogins** |
| AspNetUserTokens | **UsuarioTokens** |
| Proyectos, Tareas, TareaAvances, Trabajadores | Sin cambios (ya eran coherentes) |
| `__EFMigrationsHistory` | Sin cambios (infraestructura de EF Core) |

Las **columnas** de Identity conservan sus nombres estándar (`UserName`, `PasswordHash`…). La justificación está en `docs/DICCIONARIO_DE_DATOS.md` §1.

**Migración `20261119180159_NomenclaturaTablasIdentity`** (revisada antes de aplicarla):
- 7 `RenameTable` (`sp_rename`) y 5 `RenameIndex`.
- 7 PK y 8 FK eliminadas y vueltas a crear, solo para que sus nombres sigan la nueva nomenclatura.
- **0** `DropTable`, `CreateTable`, `DropColumn`, `AlterColumn` u operaciones sobre datos.
- Las migraciones históricas no se modificaron.

**Verificación después del cambio:**
| Comprobación | Resultado |
|---|---|
| Respaldo previo (`COPY_ONLY`, `CHECKSUM`) y restauración de prueba | Válido e idéntico |
| Huella SHA-256 de usuarios (Id, UserName, **PasswordHash**, SecurityStamp) antes y después | **Idéntica** (sin mostrar hashes) |
| Conteos (tablas, FK, CHECK, usuarios, roles, asignaciones) | Idénticos: 12 / 10 / 10 / 1 / 4 / 1 |
| Reglas de borrado de las 10 FK | Idénticas |
| Tablas `AspNet*` restantes | 0 |
| FK no confiables / violaciones (`DBCC CHECKCONSTRAINTS`) | 0 / 0 |
| Login del administrador real después del cambio | OK |
| Restaurar un respaldo anterior al cambio y migrar | Probado en una base temporal: la migración se aplica de nuevo con la huella de usuarios idéntica |
| Regresión completa | Sección A.3 |

### A.3 Pruebas tras el renombrado
Corrida completa sobre la base renombrada (19/11/2026), con todas las baterías de `Pruebas/`:

| Prueba obligatoria | Batería / evidencia | Resultado |
|---|---|---|
| Login del administrador | Funcional, visual (login real en Edge) y prueba directa con la contraseña de *user secrets* | **OK** |
| Login de los demás usuarios (Gerencia, Jefe de área, Trabajador) | Seguridad y visual | **OK** |
| Asignación de roles y autorización por rol (URL y POST directos) | Seguridad | **62/62 OK** |
| Creación, edición y eliminación de usuarios (con reglas: último principal, propia cuenta, tareas activas, jerarquía) | Funcional y seguridad | **OK** |
| CRUD de proyectos, trabajadores y tareas | Funcional | **61/61 OK** |
| Pantallas de los 3 roles (escritorio y móvil) | Visual | **82/82 OK** |
| ML.NET (entrenamiento demo y real, división temporal, protección, recarga) | ML | **19/19 OK** |
| Rendimiento con 500 tareas | `/Tareas` mediana 238 ms | Sin cambios respecto a la fase anterior |
| Herramienta de recuperación del administrador | Prueba específica con cuentas QA | **13/13 OK** |
| Integridad referencial | `DBCC CHECKCONSTRAINTS`, FK confiables | **0 violaciones, 0 FK no confiables** |
| Compilación | `dotnet build` Debug y Release | **0 errores** en ambas (Debug en su carpeta normal `bin\Debug`) |

Hallazgo durante las pruebas (corregido): la primera corrida visual falló en el login de Jefe y Trabajador. La causa
estaba en el **arnés de pruebas**, no en la aplicación: tras hacer aleatoria la contraseña QA, el script visual seguía
usando la antigua. Se corrigió (la contraseña QA se pasa como parámetro) y la corrida completa pasó.

Estado final: datos QA eliminados; la base contiene 1 usuario (el administrador, **sin cambios**: huella SHA-256 idéntica
a la del inicio de esta tarea), 4 roles, 0 registros de negocio y 9 migraciones.

### A.4 Archivos
| Archivo | Cambio |
|---|---|
| `Data/ApplicationDbContext.cs` | `ToTable(...)` para las 7 entidades de Identity |
| `Data/Migrations/20261119180159_NomenclaturaTablasIdentity*.cs` + snapshot | Nueva migración de renombrado |
| `Services/RecuperacionAdministrador.cs` (nuevo) | Herramienta de recuperación del Administrador principal |
| `Program.cs` | Atiende `--restablecer-admin` antes de iniciar la web |
| `Despliegue/GestionFTTH_migraciones_idempotente.sql` | Regenerado (9 migraciones, sin `DROP TABLE`) |
| `Pruebas/pruebas_seguridad.ps1` | Nombres de tabla nuevos en las consultas SQL; contraseña QA como parámetro opcional |
| `docs/ACCESO_ADMINISTRADOR.md`, `docs/DICCIONARIO_DE_DATOS.md` (nuevos) | Acceso y diccionario de datos |
| `README.md`, `docs/INSTALACION.md`, `docs/PRODUCCION.md`, `docs/RESPALDO_Y_RESTAURACION.md` | Referencias actualizadas |

---

## 0. Cierre técnico: estado de entrega

> **Conclusión:** GestiónFTTH está **listo para ejecutarse localmente** en Visual Studio 2022 (F5) contra
> `localhost\SQLEXPRESS`. **No está desplegado ni verificado en un servidor de producción**: los pasos pendientes
> están en `docs/PRODUCCION.md` (sección 5).

| Aspecto | Estado verificado (19/11/2026) |
|---|---|
| **Compilación Debug** | **0 errores, 0 advertencias** (compilado en una carpeta alternativa porque `bin\Debug` estaba en uso por la sesión de depuración abierta en VS 2022, iniciada por el usuario a las 12:37, lo que confirma que F5 funciona). |
| **Compilación Release** | **0 errores, 0 advertencias** (`dotnet build -c Release`). |
| **Publicación Release** | Correcta, en una carpeta local de verificación (394 archivos, ~86 MB, incluye `MLModels/` y `web.config` para IIS). **No se desplegó en ningún servidor.** |
| **Prueba del paquete publicado en Production (local)** | Arranca; carga el modelo; login 200; estáticos 200; rutas protegidas → login; registro bloqueado; 404 en español; **sin página de excepciones de desarrollo**; **sin cambios en los datos**. |
| **SQL Server** | SQL Server 2019 Express 15.0, instancia `SQLEXPRESS`, servicio en ejecución, autenticación de Windows. |
| **Base de datos** | `GestionFTTH`: 12 tablas (con nombres en español desde la sección A), 9 migraciones, 10 FK confiables, 10 CHECK, `DBCC CHECKCONSTRAINTS` sin violaciones. **Contenido: 1 usuario (Administrador principal), 4 roles, 0 proyectos, 0 tareas, 0 trabajadores.** No contiene datos ni usuarios de prueba. |
| **CRUD** | Proyectos, Tareas (y avance), Trabajadores y Usuarios: completos y probados (sección 4). |
| **Seguridad** | Sin contraseñas ni credenciales en archivos del proyecto (escaneo completo; la contraseña de pruebas fija se sustituyó por una aleatoria por ejecución). Cadena de conexión sin credenciales. Roles verificados en los endpoints (62 pruebas). **Observación:** la app usa en desarrollo una cuenta **sysadmin**; para producción hay una plantilla de cuenta con permisos mínimos (`Despliegue/crear_login_aplicacion.sql`, **no ejecutada**). |
| **ML.NET** | Funcional, en **modo DEMOSTRATIVO** (sección 6). Pasa a modo real al reentrenar con ≥ 60 registros históricos de tareas finalizadas. |
| **Regresión tras la fase final** | Funcional **61/61**, seguridad **61/61** (sin la prueba de sesión de 70 s, que pasó en la corrida completa anterior: 62/62). Datos QA eliminados después. |

### 0.1 Cambios de la fase final
| Archivo | Cambio |
|---|---|
| `Program.cs` | En entornos que no son Development, el administrador inicial se crea **solo si** se definen `AdminInicial__Email` y `AdminInicial__Password` (idempotente; registra una advertencia para retirarlas). Development no cambia. **Verificado** con la cuenta existente: sin cambios en usuario, hash, stamp ni rol. |
| `appsettings.Production.json` (nuevo) | Niveles de log para producción (Warning; Information para la aplicación). |
| `Pruebas/pruebas_e2e.ps1`, `pruebas_seguridad.ps1` | Contraseña de cuentas QA **aleatoria por ejecución** (antes era un literal fijo en el archivo). |
| `README.md`, `docs/*.md` (nuevos) | Instalación, SQL Server, cadena de conexión, migraciones, administrador inicial, manual por rol, manual ML.NET, producción, respaldo y restauración. |
| `Despliegue/GestionFTTH_migraciones_idempotente.sql` (nuevo) | Script idempotente de las 8 migraciones (sin `DROP`) para servidores sin SDK. |
| `Despliegue/crear_login_aplicacion.sql` (nuevo) | Plantilla de login con permisos mínimos (no ejecutada). |
| `.gitignore` (nuevo) | Excluye `bin/obj/.vs`, `*.user`, secretos, logs y capturas. |
| `C:\GestionFTTH\Backups_BD\LEEME.txt` (nuevo) | Ubicación y verificación del respaldo de la base. |

### 0.2 Procedimiento para iniciar el sistema
1. Comprobar que el servicio **SQL Server (SQLEXPRESS)** esté en ejecución.
2. Abrir `C:\GestionFTTH\GestionFTTH\GestionFTTH.sln` con **Visual Studio 2022**.
3. Si hay una sesión de depuración anterior abierta, detenerla (**Shift+F5**) para que se compilen los cambios de esta fase.
4. Pulsar **F5** (perfil `https` o `http`).
5. Iniciar sesión con el administrador inicial (credenciales en *user secrets*; ver `docs/INSTALACION.md`) y **cambiar la contraseña temporal**.
6. Seguir los "Primeros pasos" de `docs/MANUAL_DE_USUARIO.md`.

---

## 1. Resumen ejecutivo

| Indicador | Resultado real (última corrida) |
|---|---|
| Compilación | **0 errores, 0 advertencias** |
| Base de datos | `GestionFTTH` en `localhost\SQLEXPRESS` (autenticación de Windows y TrustServerCertificate): **9 migraciones**, 10 FK confiables, 10 restricciones CHECK, `DBCC CHECKCONSTRAINTS` sin violaciones |
| Pruebas funcionales (HTTP real) | **61 / 61 OK** |
| Pruebas de seguridad y casos negativos | **62 / 62 OK** |
| Pruebas visuales en navegador real (Edge headless + CDP), 3 roles, escritorio y móvil | **82 / 82 OK (Administrador 48, Jefe de área 17, Trabajador 17)** |
| Pruebas de ML.NET | **19 / 19 OK** |
| Rendimiento con 500 tareas | `/Tareas` **235 ms y 103 KB** (antes de la corrección: 3.364 ms y 1.881 KB) |
| Errores del servidor | Solo el error **provocado a propósito** por la prueba "fallo de entrenamiento" (archivo CSV renombrado) |

**Estado general:** no quedan errores críticos conocidos. Los pendientes son de riesgo bajo o medio y están listados en la sección 8. **El ML.NET funciona en modo DEMOSTRATIVO** hasta que haya historial real suficiente (sección 6).

---

## 2. Segunda auditoría: errores encontrados y corregidos

La primera fase había pasado sus pruebas, pero la segunda revisión encontró **20 problemas reales**. Todos se corrigieron y se volvieron a probar.

### 2.1 Seguridad
| # | Sev. | Error encontrado | Corrección | Prueba que lo verifica |
|---|---|---|---|---|
| S1 | **Crítica** | Cualquier usuario podía **eliminar su propia cuenta** en *Administrar cuenta → Personal data → Delete*, incluido el **único Administrador principal**, saltándose las reglas del módulo Usuarios. | Página `Manage/DeletePersonalData` bloqueada para todos con una política de denegación; botón eliminado de la vista. | "Eliminar propia cuenta deshabilitado", "Datos personales sin botón Eliminar" |
| S2 | Alta | Sin **bloqueo por intentos fallidos** (`lockoutOnFailure: false`): fuerza bruta posible. | Bloqueo de 5 minutos tras 5 intentos; página de bloqueo en español; nueva acción **Desbloquear** en Usuarios con indicador "Bloqueada". | "Bloqueo tras 5 intentos", "Desbloquear permite volver a iniciar sesión" |
| S3 | Alta | Al cambiar el rol de un usuario o eliminarlo, **su sesión mantenía los permisos anteriores hasta 30 minutos**. | Validación del *security stamp* cada 1 minuto y actualización del stamp al cambiar rol, correo o trabajador vinculado. | "Sesión de un usuario eliminado se invalida (≤ 1 min)" (prueba real con espera de 70 s) |
| S4 | Media | CSRF protegido solo con atributos por acción (frágil ante acciones futuras). | Filtro global `AutoValidateAntiforgeryToken`. | "POST sin token antifalsificación rechazado (400)" |
| S5 | Media | El registro de Identity seguía disponible para administradores y creaba cuentas **sin rol**, fuera de las reglas del módulo Usuarios. | Registro deshabilitado para todos. | "Registro público deshabilitado incluso para administradores" |
| S6 | Media | Un Trabajador podía **reabrir una tarea finalizada** y borrar su fecha real de cierre (la etiqueta histórica del ML). | Solo el jefe de área o un administrador puede reabrir una tarea. | "Trabajador: no puede reabrir una tarea finalizada" |
| S7 | Media | Se podía quitar el rol Trabajador a un usuario con **tareas activas**, que quedaban asignadas a alguien que ya no las ve. | Se exige reasignar las tareas primero. | "No se quita el rol Trabajador a quien tiene tareas activas" |
| S8 | Baja | Correos duplicados permitidos a nivel de Identity. | `RequireUniqueEmail = true`. | "Duplicado: correo de usuario" |
| S9 | Baja | Cookie de sesión sin política explícita. | HttpOnly, SameSite=Lax y expiración deslizante de 8 h. | Revisión de configuración |

### 2.2 Base de datos
| # | Sev. | Error encontrado | Corrección |
|---|---|---|---|
| D1 | Media | **Sin restricciones CHECK**: avance 0–100, valores de enums y orden de fechas solo se validaban en la app (un INSERT directo aceptaba avance = 150). | Migración `RestriccionesCheck` con 10 CHECK. Verificado: un INSERT con avance 150 es **rechazado por SQL Server** (error 547). Antes de crearlas se comprobó que los datos existentes las cumplían. |

### 2.3 Machine Learning
| # | Sev. | Error encontrado | Corrección |
|---|---|---|---|
| M1 | **Alta** | La evaluación dividía las **filas** al azar. Con datos reales, una misma tarea aporta varias instantáneas y podía quedar **a la vez en entrenamiento y en evaluación** (fuga entre conjuntos), y la división **no era temporal**. Esto infló las métricas de la primera fase (AUC = 1,0). | **División temporal y agrupada por tarea**: el 20 % de las *tareas* que finalizaron más recientemente va a evaluación y ninguna tarea aparece en ambos conjuntos. El CSV demo, que no tiene fechas, usa una división estratificada y lo declara. |
| M2 | Media | Las instantáneas históricas usaban la prioridad y las fechas **actuales** de la tarea. Si el plazo se amplió después, eso es información futura. | `TareaAvances` guarda **el plan vigente en esa fecha** (prioridad, inicio y límite; migración `PlanVigenteEnAvances`) y el entrenamiento usa esos valores. |
| M3 | Media | Si el historial real bajaba del mínimo, un reentrenamiento **reemplazaba en silencio un modelo real por uno demostrativo**. | Protección real→demo: solo se reemplaza si se marca la opción explícita. |
| M4 | Baja | La validación solo exigía accuracy ≥ 0,60, sin compararla con la clase mayoritaria. | Se agregó **AUC mínimo 0,60** y se informa la **accuracy de línea base**. |

### 2.4 Interfaz, usabilidad y rendimiento
| # | Sev. | Error encontrado | Corrección |
|---|---|---|---|
| U1 | **Alta** | **Rendimiento:** `/Tareas` con 500 tareas tardaba **3,4 s** y generaba **1,9 MB** de HTML. | **Paginación** de 25 por página, que conserva el filtro: **235 ms y 103 KB**. |
| U2 | Media | En móvil, el menú lateral ocupaba **toda la primera pantalla**. | Menú **plegable** con botón "☰ Menú" en pantallas ≤ 768 px. |
| U3 | Media | A 1366 px, las tablas de Tareas (+81 px) y Proyectos (+18 px) **no cabían**: la última columna quedaba oculta tras el scroll. | Tablas compactadas; verificado "exceso 0 px" en todas las pantallas. |
| U4 | Baja | Badge "Demo" del Dashboard como barra amarilla de ancho completo (selector CSS demasiado amplio). | Selector restringido a `.ftth-stat-card > span`. |
| U5 | Baja | Un registro inexistente devolvía **404 sin página** (pantalla en blanco). | Páginas de estado en español ("Registro no encontrado"). |
| U6 | Baja | Mensajes en inglés: errores de Identity ("Username is already taken"), errores de enlace de datos ("The value '' is invalid"), página de error, bloqueo y acceso denegado. | Traducidos al español. |

---

## 3. Arquitectura y tecnologías (verificadas)
- **ASP.NET Core 8.0 MVC** (`net8.0`), proyecto único `GestionFTTH.Web`; Razor Views, Bootstrap 5 y jQuery Validation.
- **EF Core 8.0.34** sobre SQL Server (code-first). No hay procedimientos almacenados ni SQL dinámico: todas las consultas son LINQ parametrizado.
- **ASP.NET Core Identity** con 4 roles: AdministradorPrincipal, AdministradorGerencia, JefeArea y Trabajador.
- **ML.NET 6.0.0**: clasificación binaria con SdcaLogisticRegression.
- Sin capa de repositorios: los controladores usan `ApplicationDbContext`. Se respetó esa arquitectura y la lógica compartida se llevó a servicios (`AlcanceUsuarioService`, servicios ML).

---

## 4. Estado de cada módulo

| Módulo | Listar | Crear | Ver | Editar | Eliminar | Estado |
|---|---|---|---|---|---|---|
| Login / sesión | — | — | — | — | — | **COMPLETADO Y PROBADO** (bloqueo, invalidación, páginas en español) |
| Usuarios | ✔ | ✔ | ✔ (listado) | ✔ | ✔ | **COMPLETADO Y PROBADO** (más Desbloquear y jerarquía de roles) |
| Roles y permisos | — | — | — | — | — | **COMPLETADO Y PROBADO** (62 pruebas de seguridad, incluidas URL y POST directos) |
| Proyectos | ✔ | ✔ | ✔ | ✔ | ✔ | **COMPLETADO Y PROBADO** |
| Trabajadores | ✔ | ✔ | ✔ | ✔ | ✔ | **COMPLETADO Y PROBADO** |
| Tareas | ✔ (paginado) | ✔ | ✔ | ✔ | ✔ | **COMPLETADO Y PROBADO** |
| Actualización de avances | — | — | — | ✔ | — | **COMPLETADO Y PROBADO** (responsable, jefe, admin) |
| Panel Administrador | Dashboard y todos los módulos | | | | | **COMPLETADO Y PROBADO** (visual 3 roles) |
| Panel Jefe de área | Tareas de su área: crear, editar, eliminar, avance | | | | | **COMPLETADO Y PROBADO** |
| Panel Trabajador | "Mis tareas", detalle, avance | | | | | **COMPLETADO Y PROBADO** |
| Modelo ML.NET | — | Entrenar | Métricas | — | — | **COMPLETADO Y PROBADO** en **modo demostrativo** |

### 4.1 Matriz de permisos verificada (endpoints, no solo botones)
| Recurso | Admin. principal | Gerencia | Jefe de área | Trabajador |
|---|---|---|---|---|
| Dashboard, Proyectos, Trabajadores, Modelo ML | ✔ | ✔ | ✘ | ✘ |
| Usuarios | ✔ | ✔ (sin tocar a los principales) | ✘ | ✘ |
| Tareas: ver | todas | todas | solo su área | solo las suyas |
| Tareas: crear, editar, eliminar | ✔ | ✔ | solo su área y responsables de su área | ✘ |
| Tareas: actualizar avance | ✔ | ✔ | su área | las suyas (sin reabrir finalizadas) |

---

## 5. Base de datos (auditoría)
- **Migraciones (9):** CreateIdentitySchema, CrearTablaProyectos, AgregarTablaTareas, AgregarTablaTrabajadores, AgregarTrabajadorIdAUsuarios, AuditoriaYMachineLearning, **PlanVigenteEnAvances**, **RestriccionesCheck**, **NomenclaturaTablasIdentity**. Ninguna elimina datos.
- **Claves foráneas (10, todas confiables):**
  - `Tareas.ProyectoId → Proyectos` (NO ACTION: no se elimina un proyecto con tareas)
  - `Tareas.ResponsableId → Usuarios` (SET NULL)
  - `TareaAvances.TareaId → Tareas` (CASCADE)
  - `Usuarios.TrabajadorId → Trabajadores` (NO ACTION) más las 6 de Identity
- **Índices únicos:** `Proyectos.Codigo`, `Tareas.Codigo`, `Trabajadores.Codigo` y `Usuarios.TrabajadorId` (filtrado).
- **Detalle completo** de tablas, columnas y relaciones: `docs/DICCIONARIO_DE_DATOS.md`. Índices de FK en `Tareas.ProyectoId`, `Tareas.ResponsableId` y `TareaAvances(TareaId, Fecha)`.
- **CHECK (10):** áreas, estados y prioridades en 1–3; avance 0–100; entrega ≥ inicio; límite ≥ inicio.
- **Integridad:** `DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS` sin violaciones.
- **Eliminaciones restringidas probadas:** proyecto con tareas, trabajador con cuenta, último Administrador principal, propia cuenta.
- **Rendimiento:** ver la tabla de la sección 7.4.
- No se borró información real. Solo se crearon y eliminaron registros de prueba con prefijo `QA`.

---

## 6. Estado real de ML.NET

### 6.1 Qué hace
Predice si una tarea **activa** terminará después de su fecha límite. Muestra **ALTO/BAJO** con un umbral configurable de 60 % y la probabilidad, en la columna "Riesgo de retraso (ML.NET)", en el modal y en el detalle de la tarea. **No modifica** ningún dato de las tareas.

### 6.2 Características y fuga de información
- **Entradas:** prioridad (OneHotEncoding), duración planificada, % de avance y días transcurridos, más dos variables **derivadas solo de ellas** (proporción del plazo consumido y brecha entre el avance esperado y el real).
- **Etiqueta:** `FechaFinalizacion > FechaLimite` (oficial). **Nunca** es una entrada.
- **Sin fuga temporal:** cada ejemplo real es una instantánea diaria de `TareaAvances` con el avance y el **plan vigente en esa fecha**. Se excluyen las instantáneas en o después del cierre. Las instantáneas anteriores a esta corrección, sin plan guardado, usan el plan actual como respaldo (hoy no existe ninguna).
- **Sin fuga entre conjuntos:** división **temporal y por tarea** (sección 2.3, M1).

### 6.3 Resultados verificados (19 / 19 OK)
| Comprobación | Resultado |
|---|---|
| CSV: 900 filas, todas marcadas `Origen=DEMO`, ambas clases, sin columnas de información futura | OK |
| Modelo demo: marcado demostrativo, división estratificada declarada, métricas marcadas "no confiables" | OK |
| Métricas demo: accuracy **0,756** frente a línea base **0,556**; AUC **0,825**; F1 coherente con P y R (2PR/(P+R)) | OK |
| Reproducibilidad (misma semilla → mismas métricas) | OK |
| Con historial real (80 tareas QA con 20 % de ruido) usa SQL Server con división temporal: **64 tareas para entrenar / 16 para evaluar** | OK |
| Métricas con historial real QA: accuracy **0,75** frente a línea base **0,6875**; AUC **0,73** (no perfectas, como corresponde a datos con ruido) | OK |
| Sin historial suficiente **no** reemplaza el modelo real por el demo | OK |
| Un entrenamiento fallido conserva el modelo vigente (mismo hash) y el listado sigue funcionando | OK |
| El modelo nuevo se carga sin reiniciar; la interfaz distingue el modo demo del real | OK |
| Reemplazo explícito por el modelo demo (opción marcada) | OK |

### 6.4 Interpretación honesta
- **El modelo entregado es DEMOSTRATIVO.** Sus métricas (0,756 / 0,825) miden su desempeño sobre datos **simulados** y **no** son evidencia del rendimiento real. La interfaz lo indica en el listado, el modal, el detalle, el Dashboard y la pantalla del modelo.
- Con historial real QA, el modelo superó la línea base por **6 puntos** de accuracy (AUC 0,73): discrimina, pero con fuerza moderada. Con datos reales de la empresa el resultado puede ser mejor o peor; se sabrá al reentrenar.
- Las probabilidades extremas (0 % y 100 %) aparecen en casos muy separados. No están calibradas con datos reales.

---

## 7. Pruebas ejecutadas (resultados reales)
Todas las baterías están en `C:\GestionFTTH\GestionFTTH\Pruebas\` y se ejecutan contra la aplicación en funcionamiento. Los resultados de la última corrida están en los archivos `resultados_*.csv` y las capturas en `Pruebas\capturas\`.

| Batería | Archivo | Qué cubre | Resultado |
|---|---|---|---|
| Funcional | `pruebas_e2e.ps1` | CRUD de todos los módulos, Editar proyecto (9 puntos), predicción, filtros, roles básicos y eliminaciones | **61 / 61 OK** |
| Seguridad | `pruebas_seguridad.ps1` | Acceso por URL y POST directo por rol, jefe de otra área, Gerencia frente a Principal, CSRF, asignación masiva, campos vacíos, duplicados, contraseñas débiles, 404, Identity, bloqueo, invalidación de sesión | **62 / 62 OK** |
| Visual | `pruebas_visuales.ps1` | Edge real: login en el navegador; 8 pantallas (admin) y 2 por rol (jefe, trabajador) en escritorio 1366 px y móvil 390 px; errores JS, desbordamientos, tablas completas, modal (clic real), validación en cliente, menú plegable y opciones por rol | **82 / 82 OK (Administrador 48, Jefe de área 17, Trabajador 17)** |
| ML.NET | `pruebas_ml.ps1` | Sección 6.3 | **19 / 19 OK** |
| Rendimiento | `pruebas_rendimiento.ps1` | Tiempos con 500 tareas | Sección 7.4 |

### 7.1 Funcional
Login · CRUD de trabajadores, usuarios, proyectos y tareas · Editar proyecto (botón, ID, carga de datos y combos, validaciones, guardado en SQL, confirmación, cambios en el listado, 404) · columna y modal ML · "No disponible" para tareas no iniciadas y finalizadas · la predicción cambia con el avance · actualizar avance y finalizar · filtros · paneles por rol · eliminaciones con sus reglas.

### 7.2 Seguridad (62 pruebas, todas OK)
- **Trabajador:** sin acceso a tareas ajenas por URL ni por POST (verificado en BD); sin Edit, Create ni Delete; sin acceso a Dashboard, Proyectos, Trabajadores, Usuarios ni Modelo; no puede reabrir tareas finalizadas.
- **Jefe de área:** no ve, edita, elimina ni actualiza tareas de otra área; no crea ni mueve tareas a proyectos de otra área; no asigna responsables de otra área.
- **Gerencia:** no edita, elimina ni crea Administradores principales, tampoco por POST directo, y no puede autopromoverse.
- **CSRF:** sin token → 400.
- **Asignación masiva:** se ignoran `Id`, `FechaRegistro` y `FechaFinalizacion`, y `TrabajadorId` en roles de administrador.
- **Validaciones en servidor:** campos vacíos, avance 150, duplicados y contraseña débil, con mensajes en español.
- **404 con página** en 7 rutas inexistentes.
- Registro y borrado de la propia cuenta deshabilitados.
- **Bloqueo y desbloqueo** de cuentas.
- **Invalidación de sesión** de un usuario eliminado en ≤ 1 minuto.

### 7.3 Visual
Se comprobó en un navegador real (Edge 157 *headless* controlado con DevTools Protocol) y se revisaron las capturas a ojo.
- **Sin errores de consola JavaScript** en ninguna pantalla.
- **Sin desbordamiento horizontal** en escritorio ni en móvil.
- **Tablas completas a 1366 px.**
- Al hacer clic real en el indicador de riesgo, **el modal se abre con los datos** y se cierra.
- La **validación en cliente** bloquea el envío vacío.
- **Menú móvil** plegado al cargar y desplegable.
- El menú muestra solo las opciones de cada rol:
  - Administrador: Dashboard, Proyectos, Tareas, Trabajadores, Usuarios y Modelo ML.NET.
  - Jefe de área: Tareas.
  - Trabajador: Mis tareas.

### 7.4 Rendimiento (500 tareas QA, mediana de 5 peticiones locales)
| Página | Mediana | Máximo | Tamaño |
|---|---|---|---|
| /Dashboard | 61 ms | 66 ms | 10 KB |
| /Tareas (paginado, 25 por página) | 235 ms | 281 ms | 103 KB |
| /Tareas?filtro=riesgo-alto | 250 ms | 258 ms | 107 KB |
| /Proyectos | 79 ms | 91 ms | 20 KB |
| /Usuarios | 84 ms | 91 ms | 26 KB |
| /Trabajadores | 63 ms | 69 ms | 17 KB |

Antes de la paginación, /Tareas con el mismo volumen tardaba **3.364 ms y pesaba 1.881 KB**. La predicción ML no era el cuello de botella: el Dashboard calcula las predicciones de todas las tareas activas en unos 60 ms.

---

## 8. Riesgos pendientes (no críticos)
| Riesgo | Nivel | Detalle / recomendación |
|---|---|---|
| Modelo ML en modo demostrativo | Medio | Reentrenar en **Modelo ML.NET** cuando `TareaAvances` tenga ≥ 60 instantáneas de tareas finalizadas, con y sin retraso. |
| Ediciones simultáneas | Medio | Si dos usuarios editan el mismo registro a la vez, gana el último en guardar (no hay control de concurrencia optimista con `rowversion`). |
| Sin servidor de correo | Medio | "¿Olvidó su contraseña?" no envía correos. Un administrador puede cambiar la contraseña en Usuarios → Editar. |
| Páginas de "Administrar cuenta" de Identity en inglés | Bajo | Perfil, correo, contraseña y 2FA conservan los textos originales en inglés (login, bloqueo, acceso denegado y errores ya están en español). |
| Despliegue en producción **no realizado** | Medio | Pendiente: servidor con Hosting Bundle, HTTPS con certificado válido, cuenta de BD con permisos mínimos (hoy es **sysadmin** en desarrollo), migraciones con el script idempotente, administrador inicial por variables, permisos de escritura en `MLModels/` y respaldos programados. Lista completa en `docs/PRODUCCION.md` §5. |
| Contraseña temporal del administrador | Medio | La cuenta de desarrollo se creó con una contraseña temporal; cambiarla antes de cargar datos reales. |
| Republicar sobrescribe el modelo ML | Bajo | El paquete trae el modelo **demo**; si en el servidor hay un modelo **real**, respaldar `MLModels/ModeloRetraso.*` antes de publicar (`docs/PRODUCCION.md` §6). |
| Navegadores | Bajo | Verificado en Edge (Chromium). No se probó en Firefox ni Safari. |

Mejoras pendientes documentadas (no implementadas porque requieren servicios externos, configuración o autorización): servicio de correo, control de concurrencia (`rowversion`), traducción de Identity, pruebas en Firefox y Safari, y entrenamiento de ML.NET con datos reales. Detalle en `docs/PRODUCCION.md` §7.

---

## 9. Archivos de la segunda auditoría

**Nuevos:**
- `Services/IdentityErroresEspanol.cs`
- `Views/Home/Estado.cshtml`
- Migraciones `…_PlanVigenteEnAvances` y `…_RestriccionesCheck`
- En `Pruebas/`: `pruebas_seguridad.ps1`, `pruebas_ml.ps1`, `pruebas_visuales.ps1`, `pruebas_rendimiento.ps1`, los `resultados_*.csv` y `capturas/`

**Modificados:**
- `Program.cs`: bloqueo, cookie, security stamp, CSRF global, políticas, páginas de estado, mensajes y errores en español.
- `Controllers/UsuariosController.cs`: security stamp, Desbloquear y regla de tareas activas.
- `Controllers/TareasController.cs`: no reabrir finalizadas, plan vigente en el historial, paginación.
- `Controllers/HomeController.cs`: páginas de estado.
- `Controllers/ModeloRiesgoController.cs`: opción de reemplazo explícito.
- `Services/Roles.cs`
- `Services/MachineLearning/TaskModelTrainer.cs` (reescrito: división temporal por tarea, plan vigente, protección real→demo, AUC y línea base), `MachineLearningOptions.cs`, `ModeloInicializador.cs`
- `Models/TareaAvance.cs`, `Models/TareasViewModels.cs`, `Models/MachineLearning/ModeloInfo.cs`
- `Data/ApplicationDbContext.cs` (CHECK) y su snapshot de migraciones
- Vistas: `Shared/_Layout.cshtml` (menú plegable), `Shared/Error.cshtml`, `Tareas/Index.cshtml` (paginación y tabla compacta), `Usuarios/Index.cshtml` (bloqueo), `ModeloRiesgo/Index.cshtml` (división, línea base, opción)
- `Areas/Identity/Pages/Account/Login.cshtml.cs` (bloqueo y mensaje), `Lockout.cshtml`, `AccessDenied.cshtml`, `Manage/PersonalData.cshtml`
- `wwwroot/css/site.css`, `wwwroot/css/dashboard.css`

(Los archivos de la primera fase están detallados en la sección 11.)

---

## 10. Instrucciones para ejecutar
Ver la sección **0.2** y `README.md`. Documentación completa: `docs/INSTALACION.md`, `docs/MANUAL_DE_USUARIO.md`,
`docs/MANUAL_MLNET.md`, `docs/PRODUCCION.md` y `docs/RESPALDO_Y_RESTAURACION.md`.

1. Abrir `C:\GestionFTTH\GestionFTTH\GestionFTTH.sln` con **Visual Studio 2022** (no con 2019) y pulsar **F5**. En Development se aplican solas las migraciones pendientes, se crean los roles y el administrador inicial (desde *user secrets*) y se carga el modelo ML.
2. Requisitos: servicio **SQL Server (SQLEXPRESS)** iniciado y SDK de .NET 8.
3. Para repetir las pruebas, con la app en `http://localhost:5199`:
   ```
   powershell -File Pruebas\pruebas_e2e.ps1        -AdminEmail <correo> -AdminPass <clave>
   powershell -File Pruebas\pruebas_seguridad.ps1  -AdminEmail <correo> -AdminPass <clave> [-IncluirSesion]
   powershell -File Pruebas\pruebas_ml.ps1         -AdminEmail <correo> -AdminPass <clave>
   powershell -File Pruebas\pruebas_visuales.ps1   -Email <correo> -Clave <clave>
   powershell -File Pruebas\pruebas_rendimiento.ps1 -AdminEmail <correo> -AdminPass <clave>
   ```
   Las baterías funcional y de seguridad crean registros con prefijo `QA` y no los eliminan. Las de ML y rendimiento sí limpian sus propios datos.

---

## 11. Resumen de la primera fase
- **Errores críticos corregidos:** base de datos inexistente y conexión a `localhost\SQLEXPRESS`; usuarios creados sin poder iniciar sesión; roles Jefe y Trabajador sin pantallas; escalada de privilegios de Gerencia; registro público abierto; FK faltantes; confirmación de Editar proyecto no visible.
- **CRUD completados:** Proyectos (Eliminar y acciones en el listado), Tareas (Ver, Editar, Eliminar, Actualizar avance), Trabajadores (Ver y eliminación segura), Usuarios (Editar y Eliminar).
- **ML.NET implementado:** entrenador, servicio de predicción seguro para concurrencia, CSV demostrativo, columna, modal y pantalla administrativa.
- **Eliminados:** 10 `.cshtml.cs` vacíos de `Views/` (código muerto, respaldados).
