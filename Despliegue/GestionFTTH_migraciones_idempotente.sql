IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetRoles] (
        [Id] nvarchar(450) NOT NULL,
        [Name] nvarchar(256) NULL,
        [NormalizedName] nvarchar(256) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetUsers] (
        [Id] nvarchar(450) NOT NULL,
        [UserName] nvarchar(256) NULL,
        [NormalizedUserName] nvarchar(256) NULL,
        [Email] nvarchar(256) NULL,
        [NormalizedEmail] nvarchar(256) NULL,
        [EmailConfirmed] bit NOT NULL,
        [PasswordHash] nvarchar(max) NULL,
        [SecurityStamp] nvarchar(max) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        [PhoneNumber] nvarchar(max) NULL,
        [PhoneNumberConfirmed] bit NOT NULL,
        [TwoFactorEnabled] bit NOT NULL,
        [LockoutEnd] datetimeoffset NULL,
        [LockoutEnabled] bit NOT NULL,
        [AccessFailedCount] int NOT NULL,
        CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetRoleClaims] (
        [Id] int NOT NULL IDENTITY,
        [RoleId] nvarchar(450) NOT NULL,
        [ClaimType] nvarchar(max) NULL,
        [ClaimValue] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetUserClaims] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [ClaimType] nvarchar(max) NULL,
        [ClaimValue] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetUserLogins] (
        [LoginProvider] nvarchar(128) NOT NULL,
        [ProviderKey] nvarchar(128) NOT NULL,
        [ProviderDisplayName] nvarchar(max) NULL,
        [UserId] nvarchar(450) NOT NULL,
        CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
        CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetUserRoles] (
        [UserId] nvarchar(450) NOT NULL,
        [RoleId] nvarchar(450) NOT NULL,
        CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
        CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE TABLE [AspNetUserTokens] (
        [UserId] nvarchar(450) NOT NULL,
        [LoginProvider] nvarchar(128) NOT NULL,
        [Name] nvarchar(128) NOT NULL,
        [Value] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
        CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [AspNetRoleClaims] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [RoleNameIndex] ON [AspNetRoles] ([NormalizedName]) WHERE [NormalizedName] IS NOT NULL');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [AspNetUserClaims] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE INDEX [IX_AspNetUserLogins_UserId] ON [AspNetUserLogins] ([UserId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [AspNetUserRoles] ([RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    CREATE INDEX [EmailIndex] ON [AspNetUsers] ([NormalizedEmail]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [UserNameIndex] ON [AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'00000000000000_CreateIdentitySchema'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'00000000000000_CreateIdentitySchema', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261118010058_CrearTablaProyectos'
)
BEGIN
    CREATE TABLE [Proyectos] (
        [Id] int NOT NULL IDENTITY,
        [Codigo] nvarchar(30) NOT NULL,
        [Nombre] nvarchar(150) NOT NULL,
        [Descripcion] nvarchar(1000) NULL,
        [Area] int NOT NULL,
        [Estado] int NOT NULL,
        [FechaInicio] datetime2 NULL,
        [FechaEntrega] datetime2 NULL,
        [FechaRegistro] datetime2 NOT NULL,
        CONSTRAINT [PK_Proyectos] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261118010058_CrearTablaProyectos'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Proyectos_Codigo] ON [Proyectos] ([Codigo]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261118010058_CrearTablaProyectos'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261118010058_CrearTablaProyectos', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119010429_AgregarTablaTareas'
)
BEGIN
    CREATE TABLE [Tareas] (
        [Id] int NOT NULL IDENTITY,
        [Codigo] nvarchar(30) NOT NULL,
        [Titulo] nvarchar(150) NOT NULL,
        [Descripcion] nvarchar(1000) NULL,
        [ProyectoId] int NOT NULL,
        [ResponsableId] nvarchar(450) NULL,
        [Estado] int NOT NULL,
        [Prioridad] int NOT NULL,
        [FechaInicio] datetime2 NULL,
        [FechaLimite] datetime2 NULL,
        [PorcentajeAvance] int NOT NULL,
        [FechaRegistro] datetime2 NOT NULL,
        CONSTRAINT [PK_Tareas] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Tareas_Proyectos_ProyectoId] FOREIGN KEY ([ProyectoId]) REFERENCES [Proyectos] ([Id]) ON DELETE NO ACTION
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119010429_AgregarTablaTareas'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Tareas_Codigo] ON [Tareas] ([Codigo]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119010429_AgregarTablaTareas'
)
BEGIN
    CREATE INDEX [IX_Tareas_ProyectoId] ON [Tareas] ([ProyectoId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119010429_AgregarTablaTareas'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119010429_AgregarTablaTareas', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119020539_AgregarTablaTrabajadores'
)
BEGIN
    CREATE TABLE [Trabajadores] (
        [Id] int NOT NULL IDENTITY,
        [Codigo] nvarchar(20) NOT NULL,
        [Nombres] nvarchar(100) NOT NULL,
        [Apellidos] nvarchar(100) NOT NULL,
        [Area] int NOT NULL,
        [Cargo] nvarchar(100) NOT NULL,
        CONSTRAINT [PK_Trabajadores] PRIMARY KEY ([Id])
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119020539_AgregarTablaTrabajadores'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Trabajadores_Codigo] ON [Trabajadores] ([Codigo]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119020539_AgregarTablaTrabajadores'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119020539_AgregarTablaTrabajadores', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119025243_AgregarTrabajadorIdAUsuarios'
)
BEGIN
    ALTER TABLE [AspNetUsers] ADD [TrabajadorId] int NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119025243_AgregarTrabajadorIdAUsuarios'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119025243_AgregarTrabajadorIdAUsuarios', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    ALTER TABLE [Tareas] ADD [FechaFinalizacion] datetime2 NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    CREATE TABLE [TareaAvances] (
        [Id] int NOT NULL IDENTITY,
        [TareaId] int NOT NULL,
        [Fecha] datetime2 NOT NULL,
        [PorcentajeAvance] int NOT NULL,
        [Estado] int NOT NULL,
        [RegistradoPorId] nvarchar(450) NULL,
        CONSTRAINT [PK_TareaAvances] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TareaAvances_Tareas_TareaId] FOREIGN KEY ([TareaId]) REFERENCES [Tareas] ([Id]) ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    CREATE INDEX [IX_Tareas_ResponsableId] ON [Tareas] ([ResponsableId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_AspNetUsers_TrabajadorId] ON [AspNetUsers] ([TrabajadorId]) WHERE [TrabajadorId] IS NOT NULL');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    CREATE INDEX [IX_TareaAvances_TareaId_Fecha] ON [TareaAvances] ([TareaId], [Fecha]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    ALTER TABLE [AspNetUsers] ADD CONSTRAINT [FK_AspNetUsers_Trabajadores_TrabajadorId] FOREIGN KEY ([TrabajadorId]) REFERENCES [Trabajadores] ([Id]) ON DELETE NO ACTION;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    ALTER TABLE [Tareas] ADD CONSTRAINT [FK_Tareas_AspNetUsers_ResponsableId] FOREIGN KEY ([ResponsableId]) REFERENCES [AspNetUsers] ([Id]) ON DELETE SET NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119144632_AuditoriaYMachineLearning'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119144632_AuditoriaYMachineLearning', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154106_PlanVigenteEnAvances'
)
BEGIN
    ALTER TABLE [TareaAvances] ADD [FechaInicioPlan] datetime2 NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154106_PlanVigenteEnAvances'
)
BEGIN
    ALTER TABLE [TareaAvances] ADD [FechaLimitePlan] datetime2 NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154106_PlanVigenteEnAvances'
)
BEGIN
    ALTER TABLE [TareaAvances] ADD [Prioridad] int NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154106_PlanVigenteEnAvances'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119154106_PlanVigenteEnAvances', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Trabajadores] ADD CONSTRAINT [CK_Trabajadores_Area] CHECK ([Area] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Tareas] ADD CONSTRAINT [CK_Tareas_Estado] CHECK ([Estado] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Tareas] ADD CONSTRAINT [CK_Tareas_Fechas] CHECK ([FechaInicio] IS NULL OR [FechaLimite] IS NULL OR [FechaLimite] >= [FechaInicio])');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Tareas] ADD CONSTRAINT [CK_Tareas_PorcentajeAvance] CHECK ([PorcentajeAvance] BETWEEN 0 AND 100)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Tareas] ADD CONSTRAINT [CK_Tareas_Prioridad] CHECK ([Prioridad] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [TareaAvances] ADD CONSTRAINT [CK_TareaAvances_Estado] CHECK ([Estado] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [TareaAvances] ADD CONSTRAINT [CK_TareaAvances_PorcentajeAvance] CHECK ([PorcentajeAvance] BETWEEN 0 AND 100)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Proyectos] ADD CONSTRAINT [CK_Proyectos_Area] CHECK ([Area] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Proyectos] ADD CONSTRAINT [CK_Proyectos_Estado] CHECK ([Estado] BETWEEN 1 AND 3)');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    EXEC(N'ALTER TABLE [Proyectos] ADD CONSTRAINT [CK_Proyectos_Fechas] CHECK ([FechaInicio] IS NULL OR [FechaEntrega] IS NULL OR [FechaEntrega] >= [FechaInicio])');
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119154210_RestriccionesCheck'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119154210_RestriccionesCheck', N'8.0.34');
END;
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetRoleClaims] DROP CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserClaims] DROP CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserLogins] DROP CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserRoles] DROP CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserRoles] DROP CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUsers] DROP CONSTRAINT [FK_AspNetUsers_Trabajadores_TrabajadorId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserTokens] DROP CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [Tareas] DROP CONSTRAINT [FK_Tareas_AspNetUsers_ResponsableId];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserTokens] DROP CONSTRAINT [PK_AspNetUserTokens];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUsers] DROP CONSTRAINT [PK_AspNetUsers];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserRoles] DROP CONSTRAINT [PK_AspNetUserRoles];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserLogins] DROP CONSTRAINT [PK_AspNetUserLogins];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetUserClaims] DROP CONSTRAINT [PK_AspNetUserClaims];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetRoles] DROP CONSTRAINT [PK_AspNetRoles];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [AspNetRoleClaims] DROP CONSTRAINT [PK_AspNetRoleClaims];
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetUserTokens]', N'UsuarioTokens';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetUsers]', N'Usuarios';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetUserRoles]', N'UsuarioRoles';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetUserLogins]', N'UsuarioLogins';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetUserClaims]', N'UsuarioClaims';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetRoles]', N'Roles';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[AspNetRoleClaims]', N'RolClaims';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[Usuarios].[IX_AspNetUsers_TrabajadorId]', N'IX_Usuarios_TrabajadorId', N'INDEX';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[UsuarioRoles].[IX_AspNetUserRoles_RoleId]', N'IX_UsuarioRoles_RoleId', N'INDEX';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[UsuarioLogins].[IX_AspNetUserLogins_UserId]', N'IX_UsuarioLogins_UserId', N'INDEX';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[UsuarioClaims].[IX_AspNetUserClaims_UserId]', N'IX_UsuarioClaims_UserId', N'INDEX';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    EXEC sp_rename N'[RolClaims].[IX_AspNetRoleClaims_RoleId]', N'IX_RolClaims_RoleId', N'INDEX';
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioTokens] ADD CONSTRAINT [PK_UsuarioTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [Usuarios] ADD CONSTRAINT [PK_Usuarios] PRIMARY KEY ([Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioRoles] ADD CONSTRAINT [PK_UsuarioRoles] PRIMARY KEY ([UserId], [RoleId]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioLogins] ADD CONSTRAINT [PK_UsuarioLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioClaims] ADD CONSTRAINT [PK_UsuarioClaims] PRIMARY KEY ([Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [Roles] ADD CONSTRAINT [PK_Roles] PRIMARY KEY ([Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [RolClaims] ADD CONSTRAINT [PK_RolClaims] PRIMARY KEY ([Id]);
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [RolClaims] ADD CONSTRAINT [FK_RolClaims_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [Tareas] ADD CONSTRAINT [FK_Tareas_Usuarios_ResponsableId] FOREIGN KEY ([ResponsableId]) REFERENCES [Usuarios] ([Id]) ON DELETE SET NULL;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioClaims] ADD CONSTRAINT [FK_UsuarioClaims_Usuarios_UserId] FOREIGN KEY ([UserId]) REFERENCES [Usuarios] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioLogins] ADD CONSTRAINT [FK_UsuarioLogins_Usuarios_UserId] FOREIGN KEY ([UserId]) REFERENCES [Usuarios] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioRoles] ADD CONSTRAINT [FK_UsuarioRoles_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioRoles] ADD CONSTRAINT [FK_UsuarioRoles_Usuarios_UserId] FOREIGN KEY ([UserId]) REFERENCES [Usuarios] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [Usuarios] ADD CONSTRAINT [FK_Usuarios_Trabajadores_TrabajadorId] FOREIGN KEY ([TrabajadorId]) REFERENCES [Trabajadores] ([Id]) ON DELETE NO ACTION;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    ALTER TABLE [UsuarioTokens] ADD CONSTRAINT [FK_UsuarioTokens_Usuarios_UserId] FOREIGN KEY ([UserId]) REFERENCES [Usuarios] ([Id]) ON DELETE CASCADE;
END;
GO

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261119180159_NomenclaturaTablasIdentity'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261119180159_NomenclaturaTablasIdentity', N'8.0.34');
END;
GO

COMMIT;
GO

