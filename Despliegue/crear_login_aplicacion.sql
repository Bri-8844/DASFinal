/*
  PLANTILLA (no ejecutada): cuenta de base de datos con permisos mínimos para GestiónFTTH en producción.

  Hoy, en el equipo de desarrollo, la aplicación se conecta con la cuenta de Windows del desarrollador,
  que es sysadmin del servidor. En producción la aplicación debe usar una cuenta dedicada SIN
  privilegios de administración.

  Opción recomendada: identidad del grupo de aplicaciones de IIS (autenticación de Windows, sin contraseñas).
  Reemplace <NOMBRE_DEL_APPPOOL> por el nombre del grupo de aplicaciones.
  Las migraciones se aplican aparte, con una cuenta administradora
  (script GestionFTTH_migraciones_idempotente.sql), por lo que la aplicación NO necesita permisos DDL.
*/

USE [master];
GO
CREATE LOGIN [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>] FROM WINDOWS WITH DEFAULT_DATABASE = [GestionFTTH];
GO

USE [GestionFTTH];
GO
CREATE USER [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>] FOR LOGIN [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>];
GO
-- Lectura y escritura de datos únicamente (sin crear ni modificar tablas)
ALTER ROLE [db_datareader] ADD MEMBER [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>];
ALTER ROLE [db_datawriter] ADD MEMBER [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>];
GO

/*
  Si se usa una cuenta de dominio de servicio en lugar del AppPool, reemplace
  [IIS APPPOOL\<NOMBRE_DEL_APPPOOL>] por [DOMINIO\cuenta_servicio].

  Si fuera imprescindible usar autenticación SQL (usuario y contraseña), cree el login con
  CREATE LOGIN ... WITH PASSWORD = '<definida por el DBA>', CHECK_POLICY = ON
  y guarde la cadena de conexión en una variable de entorno del servidor
  (ConnectionStrings__DefaultConnection), NUNCA en appsettings.json ni en el repositorio.
*/
