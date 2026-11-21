# Respaldo y restauración

## 1. Copias existentes (verificadas el 19/11/2026)

### Código fuente (`C:\GestionFTTH\`)
| Carpeta | Contenido |
|---|---|
| `Backup_GestionFTTH_20261119_012609` | Código **original**, antes de cualquier cambio (198 archivos) |
| `Backup_GestionFTTH_Auditoria2_20261119_100601` | Estado antes de la segunda auditoría (222 archivos) |
| `Backup_GestionFTTH_Final_20261119_124033` | Estado al cierre técnico (272 archivos). **Verificado: compila en Release sin errores desde la propia copia** |
| `Backup_GestionFTTH_AntesRenombrado_20261119_130110` | Estado justo antes de renombrar las tablas de Identity (281 archivos) |

Las copias excluyen `bin`, `obj` y `.vs`, que se regeneran al compilar.

### Base de datos
| Archivo | Verificación |
|---|---|
| **`C:\GestionFTTH\Backups_BD\GestionFTTH_FULL_20261119_133502.bak`** (más reciente, 4,59 MB) | Respaldo completo con `CHECKSUM`. `DBCC CHECKDB` previo sin errores; `VERIFYONLY` válido; restauración de prueba en `GestionFTTH_BackupTest` **idéntica** (12 tablas, filas por tabla, 10 FK, 10 CHECK, 26 índices, 9 migraciones, huella de usuarios y roles) con `CHECKDB` y `CHECKCONSTRAINTS` sin errores; la base temporal se eliminó después. Detalle e instrucciones: `C:\GestionFTTH\Backups_BD\INFORME_BACKUP.md` |
| `C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\GestionFTTH_20261119_124033.bak` | `RESTORE VERIFYONLY … WITH CHECKSUM` válido. **Restauración de prueba** en una base temporal con contenido idéntico (12 tablas, 10 FK, 10 CHECK, 8 migraciones, usuarios y roles); la base temporal se eliminó después. |
| `C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\GestionFTTH_AntesRenombrado_20261119_130110.bak` | Tomado **justo antes** del renombrado de tablas de Identity (contiene los nombres `AspNet*`). Verificado igual: `VERIFYONLY` válido y restauración de prueba idéntica (estructura, conteos y huella SHA-256 de usuarios, contraseñas cifradas y *security stamps*). |

> Si restaura un respaldo **anterior** al renombrado, la base volverá a tener las tablas `AspNet*` y la migración
> `NomenclaturaTablasIdentity` figurará como pendiente. Al iniciar la aplicación en Development (o con
> `dotnet ef database update`), se aplica de nuevo y los nombres vuelven a ser los actuales, sin pérdida de datos.

Los dos respaldos anteriores se hicieron con `COPY_ONLY` en el directorio de respaldos de SQL Server. **Corrección:**
en su momento se indicó que la cuenta de servicio no podía escribir en `C:\GestionFTTH\Backups_BD`. Era incorrecto:
el respaldo del 19/11/2026 13:35 se escribió allí directamente. El problema de entonces fue *copiar* con la cuenta del
usuario un `.bak` desde el directorio interno de SQL Server, donde ese usuario no tiene permiso de lectura.
**Ubicación recomendada para nuevos respaldos: `C:\GestionFTTH\Backups_BD\`.**

## 2. Crear un nuevo respaldo de la base

Recomendado, en la carpeta del proyecto, con un nombre nuevo en cada ejecución (SQL Server Express **no** admite `COMPRESSION`):

```
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "BACKUP DATABASE [GestionFTTH] TO DISK = N'C:\GestionFTTH\Backups_BD\GestionFTTH_FULL_AAAAMMDD_HHmmss.bak' WITH CHECKSUM, INIT, FORMAT"
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "RESTORE VERIFYONLY FROM DISK = N'C:\GestionFTTH\Backups_BD\GestionFTTH_FULL_AAAAMMDD_HHmmss.bak' WITH CHECKSUM"
```

Alternativa en el directorio de respaldos de SQL Server:

```
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "BACKUP DATABASE [GestionFTTH] TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\GestionFTTH_AAAAMMDD.bak' WITH COPY_ONLY, CHECKSUM, INIT"
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "RESTORE VERIFYONLY FROM DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\GestionFTTH_AAAAMMDD.bak' WITH CHECKSUM"
```

También desde **SSMS**: clic derecho en `GestionFTTH` → *Tareas → Copia de seguridad*.

Recomendación: copiar los `.bak` a otro disco o equipo. SQL Server **Express no tiene Agente SQL**, así que para
respaldos automáticos use el Programador de tareas de Windows con el comando anterior.

## 3. Restaurar la base de datos

> ⚠️ Restaurar **sobre** `GestionFTTH` reemplaza todos sus datos actuales. Primero haga un respaldo del estado actual.

**Opción A: probar el respaldo sin tocar la base actual** (restaurar con otro nombre):

```sql
RESTORE FILELISTONLY FROM DISK = N'...\GestionFTTH_AAAAMMDD.bak';   -- nombres lógicos: GestionFTTH / GestionFTTH_log

RESTORE DATABASE [GestionFTTH_Restaurada]
FROM DISK = N'...\GestionFTTH_AAAAMMDD.bak'
WITH MOVE N'GestionFTTH'     TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\GestionFTTH_Restaurada.mdf',
     MOVE N'GestionFTTH_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\GestionFTTH_Restaurada_log.ldf',
     CHECKSUM, RECOVERY;
```

**Opción B: reemplazar la base actual** (detenga antes la aplicación):

```sql
ALTER DATABASE [GestionFTTH] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [GestionFTTH] FROM DISK = N'...\GestionFTTH_AAAAMMDD.bak' WITH REPLACE, CHECKSUM, RECOVERY;
ALTER DATABASE [GestionFTTH] SET MULTI_USER;
```

Después de restaurar, si el código es más nuevo que el respaldo, aplique las migraciones pendientes
(ver [INSTALACION.md](INSTALACION.md#5-migraciones-estructura-de-la-base-de-datos)).

## 4. Restaurar el código

1. Copie la carpeta de respaldo deseada a una ubicación nueva, por ejemplo `C:\GestionFTTH\GestionFTTH_Restaurado`.
   No sobrescriba la carpeta actual sin respaldarla antes.
2. Abra `GestionFTTH.sln` con Visual Studio 2022 y compile: los paquetes NuGet se restauran solos.
3. Los *user secrets* no forman parte del código: siguen en `%APPDATA%\Microsoft\UserSecrets\` del usuario.

## 5. Modelo ML.NET

`MLModels/ModeloRetraso.zip` y `.json` están incluidos en las copias de código. Para conservar un modelo concreto,
copie ambos archivos antes de reentrenar y restáurelos copiándolos de nuevo a `MLModels/` (se cargan al reiniciar la aplicación).
