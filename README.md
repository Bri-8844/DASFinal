# GestiónFTTH

Sistema web para gestionar proyectos FTTH: proyectos, tareas, trabajadores, usuarios con roles y
**predicción del riesgo de retraso de tareas con ML.NET**.

| | |
|---|---|
| Tecnología | ASP.NET Core 8 MVC · EF Core 8 · SQL Server Express · ASP.NET Core Identity · ML.NET 6 · Bootstrap 5 |
| Base de datos | `GestionFTTH` en `localhost\SQLEXPRESS` (autenticación de Windows) |
| Estado | **Listo para ejecutarse localmente con Visual Studio 2022 (F5).** La publicación Release se verificó solo en este equipo: **no se ha desplegado en un servidor de producción** (ver [docs/PRODUCCION.md](docs/PRODUCCION.md)). |

## Inicio rápido (equipo de desarrollo)

1. Requisitos: **Visual Studio 2022** (17.8 o superior) con la carga "Desarrollo web y ASP.NET", **SDK de .NET 8** y **SQL Server Express** (instancia `SQLEXPRESS`).
2. Configurar las credenciales del administrador inicial en *user secrets*. Están fuera del repositorio; ver [docs/INSTALACION.md](docs/INSTALACION.md#4-administrador-inicial).
3. Abrir `GestionFTTH.sln` con **Visual Studio 2022** y pulsar **F5**.
   Al iniciar en Development, la aplicación:
   - aplica las migraciones pendientes en `localhost\SQLEXPRESS`,
   - crea los roles y el administrador inicial,
   - carga el modelo ML.NET (o lo entrena una sola vez si no existe).
4. Iniciar sesión con el administrador inicial y **cambiar su contraseña** en *Administrar cuenta → Password*.

> No abra la solución con Visual Studio 2019: no compila .NET 8 (error MSB3971).

## Documentación

| Documento | Contenido |
|---|---|
| [docs/INSTALACION.md](docs/INSTALACION.md) | Instalación, SQL Server Express, cadena de conexión, migraciones, administrador inicial |
| [docs/ACCESO_ADMINISTRADOR.md](docs/ACCESO_ADMINISTRADOR.md) | Dónde están las credenciales del administrador, cómo cambiarlas y cómo recuperar el acceso (sin contraseñas en el documento) |
| [docs/DICCIONARIO_DE_DATOS.md](docs/DICCIONARIO_DE_DATOS.md) | Tablas, columnas, claves, índices, restricciones y relaciones de la base de datos |
| [docs/MANUAL_DE_USUARIO.md](docs/MANUAL_DE_USUARIO.md) | Uso del sistema por rol: Administrador principal, Gerencia, Jefe de área, Trabajador |
| [docs/MANUAL_MLNET.md](docs/MANUAL_MLNET.md) | Cómo funciona la predicción, cómo entrenar y reentrenar el modelo, cómo interpretar las métricas |
| [docs/PRODUCCION.md](docs/PRODUCCION.md) | Compilación Release, publicación, configuración del servidor, logs, lista de verificación y pendientes |
| [docs/RESPALDO_Y_RESTAURACION.md](docs/RESPALDO_Y_RESTAURACION.md) | Copias de seguridad del código y de la base de datos, y cómo restaurarlas |
| [INFORME_AUDITORIA_FINAL.md](INFORME_AUDITORIA_FINAL.md) | Auditorías, errores corregidos, pruebas y estado de cada módulo |

## Estructura

```
GestionFTTH.sln
GestionFTTH.Web/
  Controllers/        Dashboard, Proyectos, Tareas, Trabajadores, Usuarios, ModeloRiesgo, Home
  Data/               ApplicationDbContext, ApplicationUser, Migrations/
  Models/             Entidades, ViewModels y Models/MachineLearning/
  Services/           Roles, alcance por rol, seeder de Identity, Services/MachineLearning/
  Views/              Vistas Razor
  MLModels/           DatosEntrenamiento.csv (DEMO), ModeloRetraso.zip/.json
  wwwroot/            CSS, JS y librerías cliente
Despliegue/           Script SQL idempotente de migraciones y plantilla de login SQL
Pruebas/              Baterías de prueba automatizadas (PowerShell) y resultados
docs/                 Documentación
```

## Pruebas

En `Pruebas/` hay baterías automatizadas que se ejecutan contra la aplicación en funcionamiento: funcional, seguridad,
visual (Edge headless), ML.NET y rendimiento. La última corrida completa terminó sin fallos; los resultados están en
`Pruebas/resultados_*.csv` y en el informe de auditoría.

## Pendientes conocidos

- Servicio de correo (recuperación de contraseña).
- Control de concurrencia en ediciones simultáneas.
- Traducción de las páginas de "Administrar cuenta" de Identity.
- Pruebas en Firefox y Safari.
- Entrenamiento de ML.NET con datos históricos **reales**: hoy el modelo funciona en **modo demostrativo**.

El detalle está en [docs/PRODUCCION.md](docs/PRODUCCION.md#7-mejoras-pendientes).
