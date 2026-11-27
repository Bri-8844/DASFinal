-- Datos demostrativos para GestiónFTTH. Ejecutar SOLO en una BD de pruebas.
-- Idempotente por Codigo. No crea cuentas Identity ni historial ML ficticio.
-- Requiere migraciones aplicadas. Verifique respaldo antes de ejecutar.
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- 20 trabajadores: 3 jefes y 17 trabajadores
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-001')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-001',N'Lucía',N'Ramírez',1,N'Jefe de área');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-002')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-002',N'Carlos',N'Mendoza',2,N'Jefe de área');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-003')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-003',N'Andrea',N'Salazar',3,N'Jefe de área');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-004')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-004',N'Mateo',N'Rojas',1,N'Analista FTTH');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-005')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-005',N'Valeria',N'Torres',1,N'Técnico de prediseño');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-006')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-006',N'Diego',N'Castro',1,N'Analista GIS');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-007')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-007',N'Sofía',N'Vargas',1,N'Asistente técnico');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-008')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-008',N'Bruno',N'Flores',1,N'Analista FTTH');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-009')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-009',N'Daniela',N'Paredes',2,N'Diseñadora de red');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-010')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-010',N'Jorge',N'Medina',2,N'Proyectista');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-011')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-011',N'Camila',N'Núñez',2,N'Diseñadora CAD');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-012')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-012',N'Renato',N'Silva',2,N'Analista de diseño');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-013')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-013',N'Paola',N'García',2,N'Proyectista');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-014')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-014',N'Hugo',N'Reyes',2,N'Asistente de diseño');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-015')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-015',N'Mariana',N'León',3,N'Supervisora de obra');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-016')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-016',N'Luis',N'Herrera',3,N'Técnico de campo');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-017')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-017',N'Fernanda',N'Cruz',3,N'Inspectora de calidad');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-018')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-018',N'Oscar',N'Peña',3,N'Instalador FTTH');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-019')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-019',N'Elena',N'Morales',3,N'Técnica de construcción');
IF NOT EXISTS (SELECT 1 FROM dbo.Trabajadores WHERE Codigo = N'DEMO-TRB-020')
 INSERT INTO dbo.Trabajadores (Codigo,Nombres,Apellidos,Area,Cargo) VALUES (N'DEMO-TRB-020',N'Iván',N'Soto',3,N'Supervisor de campo');

-- 10 proyectos (áreas 1=Prediseño, 2=Diseño, 3=Construcción)
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-001')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-001',N'Levantamiento de red Lima Norte',N'Proyecto de demostración FTTH',1,1,DATEADD(day,-25,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-002')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-002',N'Evaluación de cobertura Callao',N'Proyecto de demostración FTTH',1,2,DATEADD(day,-28,CAST(GETDATE() AS date)),DATEADD(day,22,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-003')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-003',N'Factibilidad FTTH Huancayo',N'Proyecto de demostración FTTH',1,3,DATEADD(day,-31,CAST(GETDATE() AS date)),DATEADD(day,24,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-004')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-004',N'Prediseño de red Cusco',N'Proyecto de demostración FTTH',1,1,DATEADD(day,-34,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-005')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-005',N'Diseño de red Arequipa',N'Proyecto de demostración FTTH',2,2,DATEADD(day,-37,CAST(GETDATE() AS date)),DATEADD(day,28,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-006')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-006',N'Ingeniería FTTH Trujillo',N'Proyecto de demostración FTTH',2,3,DATEADD(day,-40,CAST(GETDATE() AS date)),DATEADD(day,30,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-007')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-007',N'Diseño de expansión Chiclayo',N'Proyecto de demostración FTTH',2,1,DATEADD(day,-43,CAST(GETDATE() AS date)),DATEADD(day,32,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-008')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-008',N'Despliegue FTTH Lima Sur',N'Proyecto de demostración FTTH',3,2,DATEADD(day,-46,CAST(GETDATE() AS date)),DATEADD(day,34,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-009')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-009',N'Construcción de red Piura',N'Proyecto de demostración FTTH',3,3,DATEADD(day,-49,CAST(GETDATE() AS date)),DATEADD(day,36,CAST(GETDATE() AS date)),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM dbo.Proyectos WHERE Codigo = N'DEMO-PRY-010')
 INSERT INTO dbo.Proyectos (Codigo,Nombre,Descripcion,Area,Estado,FechaInicio,FechaEntrega,FechaRegistro)
 VALUES (N'DEMO-PRY-010',N'Implementación FTTH Cajamarca',N'Proyecto de demostración FTTH',3,1,DATEADD(day,-52,CAST(GETDATE() AS date)),DATEADD(day,38,CAST(GETDATE() AS date)),SYSUTCDATETIME());

-- 5 tareas por proyecto; ResponsableId NULL hasta crear cuentas con UserManager.
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-001')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-001',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-001',p.Id,NULL,1,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-001';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-002')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-002',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-001',p.Id,NULL,2,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,35,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-001';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-003')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-003',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-001',p.Id,NULL,3,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-001';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-004')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-004',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-001',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-001';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-005')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-005',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-001',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-001';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-006')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-006',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-002',p.Id,NULL,2,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,35,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-002';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-007')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-007',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-002',p.Id,NULL,3,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-002';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-008')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-008',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-002',p.Id,NULL,1,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-002';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-009')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-009',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-002',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-002';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-010')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-010',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-002',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-002';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-011')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-011',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-003',p.Id,NULL,3,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-003';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-012')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-012',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-003',p.Id,NULL,1,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-003';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-013')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-013',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-003',p.Id,NULL,2,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-003';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-014')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-014',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-003',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,35,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-003';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-015')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-015',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-003',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-003';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-016')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-016',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-004',p.Id,NULL,1,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-004';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-017')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-017',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-004',p.Id,NULL,2,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-004';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-018')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-018',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-004',p.Id,NULL,3,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-004';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-019')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-019',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-004',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,50,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-004';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-020')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-020',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-004',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-004';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-021')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-021',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-005',p.Id,NULL,2,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-005';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-022')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-022',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-005',p.Id,NULL,3,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-005';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-023')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-023',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-005',p.Id,NULL,1,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-005';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-024')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-024',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-005',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-005';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-025')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-025',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-005',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-005';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-026')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-026',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-006',p.Id,NULL,3,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-006';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-027')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-027',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-006',p.Id,NULL,1,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-006';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-028')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-028',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-006',p.Id,NULL,2,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-006';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-029')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-029',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-006',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-006';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-030')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-030',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-006',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-006';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-031')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-031',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-007',p.Id,NULL,1,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-007';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-032')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-032',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-007',p.Id,NULL,2,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-007';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-033')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-033',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-007',p.Id,NULL,3,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-007';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-034')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-034',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-007',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,35,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-007';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-035')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-035',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-007',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-007';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-036')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-036',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-008',p.Id,NULL,2,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-008';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-037')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-037',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-008',p.Id,NULL,3,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-008';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-038')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-038',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-008',p.Id,NULL,1,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-008';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-039')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-039',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-008',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,50,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-008';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-040')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-040',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-008',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-008';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-041')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-041',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-009',p.Id,NULL,3,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-009';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-042')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-042',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-009',p.Id,NULL,1,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-009';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-043')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-043',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-009',p.Id,NULL,2,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),NULL,50,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-009';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-044')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-044',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-009',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,65,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-009';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-045')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-045',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-009',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-009';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-046')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-046',N'Levantamiento de información',N'Tarea demostrativa del proyecto DEMO-PRY-010',p.Id,NULL,1,1,DATEADD(day,-12,CAST(GETDATE() AS date)),DATEADD(day,14,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-010';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-047')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-047',N'Validación técnica',N'Tarea demostrativa del proyecto DEMO-PRY-010',p.Id,NULL,2,2,DATEADD(day,-13,CAST(GETDATE() AS date)),DATEADD(day,17,CAST(GETDATE() AS date)),NULL,50,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-010';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-048')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-048',N'Preparación de documentación',N'Tarea demostrativa del proyecto DEMO-PRY-010',p.Id,NULL,3,3,DATEADD(day,-14,CAST(GETDATE() AS date)),DATEADD(day,20,CAST(GETDATE() AS date)),CAST(GETDATE() AS date),100,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-010';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-049')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-049',N'Ejecución de actividades',N'Tarea demostrativa del proyecto DEMO-PRY-010',p.Id,NULL,2,1,DATEADD(day,-15,CAST(GETDATE() AS date)),DATEADD(day,23,CAST(GETDATE() AS date)),NULL,20,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-010';
IF NOT EXISTS (SELECT 1 FROM dbo.Tareas WHERE Codigo = N'DEMO-TAR-050')
 INSERT INTO dbo.Tareas (Codigo,Titulo,Descripcion,ProyectoId,ResponsableId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
 SELECT N'DEMO-TAR-050',N'Revisión y cierre',N'Tarea demostrativa del proyecto DEMO-PRY-010',p.Id,NULL,1,2,DATEADD(day,-16,CAST(GETDATE() AS date)),DATEADD(day,26,CAST(GETDATE() AS date)),NULL,0,SYSUTCDATETIME()
 FROM dbo.Proyectos p WHERE p.Codigo=N'DEMO-PRY-010';

COMMIT TRANSACTION;
-- Validar conteos por prefijo DEMO- antes de continuar.
