param([string]$Base = "http://localhost:5199", [string]$AdminEmail, [string]$AdminPass, [switch]$IncluirSesion, [string]$PassQA)

# Pruebas de seguridad y casos negativos de GestiónFTTH.
# Crea datos de prueba con prefijo QA (no modifica otros registros).

$ErrorActionPreference = "Continue"
$resultados = New-Object System.Collections.Generic.List[object]
$run = Get-Random -Minimum 1000 -Maximum 9999
$hoy = Get-Date
if (-not $PassQA) { $PassQA = "Qa#" + [guid]::NewGuid().ToString("N").Substring(0, 10) + "x9" }   # aleatoria por ejecución (cuentas QA temporales)
$passQA = $PassQA

function Registrar($nombre, $ok, $detalle = "") {
    $resultados.Add([pscustomobject]@{ Prueba = $nombre; Resultado = $(if ($ok) { "OK" } else { "FALLA" }); Detalle = $detalle })
}
function Token($html) { [regex]::Match($html, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"').Groups[1].Value }
function Get-Pagina($sesion, $url) {
    try {
        $x = Invoke-WebRequest "$Base$url" -WebSession $sesion -UseBasicParsing -MaximumRedirection 5
        return [pscustomobject]@{ Content = [System.Net.WebUtility]::HtmlDecode($x.Content); StatusCode = [int]$x.StatusCode; Url = $x.BaseResponse.ResponseUri.AbsoluteUri }
    } catch {
        $r = $_.Exception.Response
        $cuerpo = ""
        try { $sr = New-Object IO.StreamReader($r.GetResponseStream()); $cuerpo = [System.Net.WebUtility]::HtmlDecode($sr.ReadToEnd()) } catch {}
        return [pscustomobject]@{ Content = $cuerpo; StatusCode = [int]$r.StatusCode; Url = "" }
    }
}
function Enviar($sesion, $urlForm, $urlPost, $campos, [switch]$SinToken) {
    if (-not $SinToken) {
        $pagina = Invoke-WebRequest "$Base$urlForm" -WebSession $sesion -UseBasicParsing
        $campos["__RequestVerificationToken"] = Token $pagina.Content
    }
    try {
        $x = Invoke-WebRequest "$Base$urlPost" -Method Post -Body $campos -WebSession $sesion -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
        return [pscustomobject]@{ StatusCode = [int]$x.StatusCode; Location = [string]$x.Headers["Location"]; Content = [System.Net.WebUtility]::HtmlDecode($x.Content) }
    } catch {
        $r = $_.Exception.Response
        return [pscustomobject]@{ StatusCode = [int]$r.StatusCode; Location = [string]$r.Headers["Location"]; Content = "" }
    }
}
function Login($email, $pass) {
    $s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $r = Enviar $s "/Identity/Account/Login" "/Identity/Account/Login" @{ "Input.Email" = $email; "Input.Password" = $pass }
    return @{ Sesion = $s; Respuesta = $r }
}
function Denegado($r) { ($r.StatusCode -eq 403) -or ($r.Location -match "AccessDenied") -or ($r.Url -match "AccessDenied") -or ($r.Content -match "Acceso denegado") }
function F($d) { $d.ToString("yyyy-MM-dd") }
function SQL($q) { (sqlcmd -S "localhost\SQLEXPRESS" -E -C -I -d GestionFTTH -h -1 -W -Q "SET NOCOUNT ON; $q" | Where-Object { $_ -ne "" }) }

# ---------- Preparación ----------
$adm = (Login $AdminEmail $AdminPass).Sesion

function NuevoTrabajador($nombre, $area) {
    $null = Enviar $adm "/Trabajadores/Create" "/Trabajadores/Create" @{ Nombres = $nombre; Apellidos = "QA"; Area = "$area"; Cargo = "QA" }
    return [int](SQL "SELECT MAX(Id) FROM Trabajadores WHERE Nombres = N'$nombre'")
}
function NuevoUsuario($email, $rol, $trab) {
    $c = @{ Email = $email; Password = $passQA; ConfirmPassword = $passQA; Rol = $rol }
    if ($trab) { $c["TrabajadorId"] = "$trab" }
    return Enviar $adm "/Usuarios/Create" "/Usuarios/Create" $c
}
function IdUsuario($email) { SQL "SELECT Id FROM Usuarios WHERE Email = '$email'" }
function NuevoProyecto($cod, $area) {
    $null = Enviar $adm "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = $cod; Nombre = "Proyecto $cod"; Area = "$area"; Estado = "2" }
    return [int](SQL "SELECT Id FROM Proyectos WHERE Codigo = '$cod'")
}
function NuevaTarea($cod, $proy, $resp, $estado = 2, $avance = 20) {
    $null = Enviar $adm "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = "$proy"; ResponsableId = $resp; Codigo = $cod; Titulo = "Tarea $cod"; Prioridad = "2"; Estado = "$estado"; FechaInicio = (F $hoy.AddDays(-3)); FechaLimite = (F $hoy.AddDays(7)); PorcentajeAvance = "$avance" }
    return [int](SQL "SELECT Id FROM Tareas WHERE Codigo = '$cod'")
}

$tA = NuevoTrabajador "QA TrabA$run" 2      # Diseño
$tB = NuevoTrabajador "QA TrabB$run" 3      # Construcción
$tJ = NuevoTrabajador "QA Jefe$run" 2       # Diseño
$eA = "qa.a$run@gestionftth.local"; $eB = "qa.b$run@gestionftth.local"; $eJ = "qa.j$run@gestionftth.local"; $eG = "qa.g$run@gestionftth.local"
$null = NuevoUsuario $eA "Trabajador" $tA; $null = NuevoUsuario $eB "Trabajador" $tB; $null = NuevoUsuario $eJ "JefeArea" $tJ; $null = NuevoUsuario $eG "AdministradorGerencia" $null
$uA = IdUsuario $eA; $uB = IdUsuario $eB
$pD = NuevoProyecto "QA-SD$run" 2; $pC = NuevoProyecto "QA-SC$run" 3
$tareaA = NuevaTarea "QA-SA$run" $pD $uA
$tareaB = NuevaTarea "QA-SB$run" $pC $uB
$tareaFin = NuevaTarea "QA-SF$run" $pD $uA 3 100
Registrar "Preparación de datos de prueba" ($uA -and $uB -and $tareaA -gt 0 -and $tareaB -gt 0 -and $tareaFin -gt 0) "tareas $tareaA/$tareaB/$tareaFin"

$sA = (Login $eA $passQA).Sesion; $sJ = (Login $eJ $passQA).Sesion; $sG = (Login $eG $passQA).Sesion

# ---------- 1. Trabajador ----------
Registrar "Trabajador: no ve tarea de otro trabajador (URL Details)" (Denegado (Get-Pagina $sA "/Tareas/Details/$tareaB"))
Registrar "Trabajador: no abre Edit de su tarea (solo gestores)" (Denegado (Get-Pagina $sA "/Tareas/Edit/$tareaA"))
Registrar "Trabajador: POST ActualizarAvance en tarea ajena denegado" (Denegado (Enviar $sA "/Tareas" "/Tareas/ActualizarAvance" @{ Id = "$tareaB"; PorcentajeAvance = "90"; Estado = "2" }))
Registrar "Trabajador: avance de tarea ajena no cambió en BD" ((SQL "SELECT PorcentajeAvance FROM Tareas WHERE Id=$tareaB") -eq "20")
Registrar "Trabajador: POST Delete de tarea denegado" ((Denegado (Enviar $sA "/Tareas" "/Tareas/Delete/$tareaA" @{})) -and (SQL "SELECT COUNT(*) FROM Tareas WHERE Id=$tareaA") -eq "1")
Registrar "Trabajador: POST Create de tarea denegado" (Denegado (Enviar $sA "/Tareas" "/Tareas/Create" @{ ProyectoId = "$pD"; ResponsableId = $uA; Codigo = "QA-X$run"; Titulo = "x"; Prioridad = "1"; Estado = "1"; FechaInicio = (F $hoy); FechaLimite = (F $hoy.AddDays(2)); PorcentajeAvance = "0" }))
foreach ($u in "/Dashboard", "/Proyectos", "/Trabajadores", "/Usuarios", "/ModeloRiesgo", "/Proyectos/Create", "/Usuarios/Create") {
    Registrar "Trabajador: GET $u denegado" (Denegado (Get-Pagina $sA $u))
}
Registrar "Trabajador: POST Proyectos/Delete denegado" ((Denegado (Enviar $sA "/Tareas" "/Proyectos/Delete/$pD" @{})) -and (SQL "SELECT COUNT(*) FROM Proyectos WHERE Id=$pD") -eq "1")
$r = Enviar $sA "/Tareas/Details/$tareaFin" "/Tareas/ActualizarAvance" @{ Id = "$tareaFin"; PorcentajeAvance = "50"; Estado = "2" }
Registrar "Trabajador: no puede reabrir una tarea finalizada" (((SQL "SELECT Estado FROM Tareas WHERE Id=$tareaFin") -eq "3") -and ((Get-Pagina $sA "/Tareas/Details/$tareaFin").Content -match "Solo el jefe de área o un administrador puede reabrir"))
$r = Enviar $sA "/Tareas/Details/$tareaA" "/Tareas/ActualizarAvance" @{ Id = "$tareaA"; PorcentajeAvance = "150"; Estado = "2" }
Registrar "Validación servidor: avance 150 rechazado" ((SQL "SELECT PorcentajeAvance FROM Tareas WHERE Id=$tareaA") -eq "20")
$r = Enviar $sA "/Tareas/Details/$tareaA" "/Tareas/ActualizarAvance" @{ Id = "$tareaA"; PorcentajeAvance = "45"; Estado = "2" }
Registrar "Trabajador: actualiza avance de su tarea" ((SQL "SELECT PorcentajeAvance FROM Tareas WHERE Id=$tareaA") -eq "45")
Registrar "Historial guarda el plan vigente (prioridad y fechas)" ((SQL "SELECT COUNT(*) FROM TareaAvances WHERE TareaId=$tareaA AND Prioridad IS NOT NULL AND FechaInicioPlan IS NOT NULL AND FechaLimitePlan IS NOT NULL") -ge 1)

# ---------- 2. Jefe de área (Diseño) ----------
$idx = (Get-Pagina $sJ "/Tareas").Content
Registrar "Jefe: listado incluye su área y excluye otras" ($idx -match "QA-SA$run" -and $idx -notmatch "QA-SB$run")
Registrar "Jefe: no ve tarea de otra área (URL Details)" (Denegado (Get-Pagina $sJ "/Tareas/Details/$tareaB"))
Registrar "Jefe: no edita tarea de otra área (URL Edit)" (Denegado (Get-Pagina $sJ "/Tareas/Edit/$tareaB"))
Registrar "Jefe: POST Delete de tarea de otra área denegado" ((Denegado (Enviar $sJ "/Tareas" "/Tareas/Delete/$tareaB" @{})) -and (SQL "SELECT COUNT(*) FROM Tareas WHERE Id=$tareaB") -eq "1")
Registrar "Jefe: POST ActualizarAvance de otra área denegado" (Denegado (Enviar $sJ "/Tareas" "/Tareas/ActualizarAvance" @{ Id = "$tareaB"; PorcentajeAvance = "99"; Estado = "2" }))
$r = Enviar $sJ "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = "$pC"; ResponsableId = $uB; Codigo = "QA-SJ$run"; Titulo = "x"; Prioridad = "1"; Estado = "1"; FechaInicio = (F $hoy); FechaLimite = (F $hoy.AddDays(2)); PorcentajeAvance = "0" }
Registrar "Jefe: no crea tareas en proyecto de otra área (POST directo)" ($r.StatusCode -eq 200 -and $r.Content -match "proyectos de su área" -and (SQL "SELECT COUNT(*) FROM Tareas WHERE Codigo='QA-SJ$run'") -eq "0")
$r = Enviar $sJ "/Tareas/Edit/$tareaA" "/Tareas/Edit/$tareaA" @{ Id = "$tareaA"; ProyectoId = "$pC"; ResponsableId = $uA; Codigo = "QA-SA$run"; Titulo = "x"; Prioridad = "2"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-3)); FechaLimite = (F $hoy.AddDays(7)); PorcentajeAvance = "45" }
Registrar "Jefe: no mueve su tarea a un proyecto de otra área" ((SQL "SELECT ProyectoId FROM Tareas WHERE Id=$tareaA") -eq "$pD")
$r = Enviar $sJ "/Tareas/Edit/$tareaA" "/Tareas/Edit/$tareaA" @{ Id = "$tareaA"; ProyectoId = "$pD"; ResponsableId = $uB; Codigo = "QA-SA$run"; Titulo = "x"; Prioridad = "2"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-3)); FechaLimite = (F $hoy.AddDays(7)); PorcentajeAvance = "45" }
Registrar "Jefe: no asigna responsable de otra área" ((SQL "SELECT ResponsableId FROM Tareas WHERE Id=$tareaA") -eq $uA)
foreach ($u in "/Dashboard", "/Proyectos", "/Trabajadores", "/Usuarios", "/ModeloRiesgo") {
    Registrar "Jefe: GET $u denegado" (Denegado (Get-Pagina $sJ $u))
}

# ---------- 3. Gerencia ----------
$idPrincipal = SQL "SELECT TOP 1 u.Id FROM Usuarios u JOIN UsuarioRoles ur ON ur.UserId=u.Id JOIN Roles r ON r.Id=ur.RoleId WHERE r.Name='AdministradorPrincipal'"
Registrar "Gerencia: GET Edit de Administrador principal denegado" (Denegado (Get-Pagina $sG "/Usuarios/Edit/$idPrincipal"))
$r = Enviar $sG "/Usuarios" "/Usuarios/Edit/$idPrincipal" @{ Id = $idPrincipal; Email = "hack$run@gestionftth.local"; Rol = "Trabajador" }
Registrar "Gerencia: POST Edit de Administrador principal denegado" ((Denegado $r) -and (SQL "SELECT COUNT(*) FROM Usuarios WHERE Id='$idPrincipal' AND Email LIKE 'hack%'") -eq "0")
Registrar "Gerencia: POST Delete de Administrador principal denegado" ((Denegado (Enviar $sG "/Usuarios" "/Usuarios/Delete/$idPrincipal" @{})) -and (SQL "SELECT COUNT(*) FROM Usuarios WHERE Id='$idPrincipal'") -eq "1")
$r = Enviar $sG "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.esc$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "AdministradorPrincipal" }
Registrar "Gerencia: no crea Administrador principal (POST directo)" ((SQL "SELECT COUNT(*) FROM Usuarios WHERE Email='qa.esc$run@gestionftth.local'") -eq "0")
$idG = IdUsuario $eG
$r = Enviar $sG "/Usuarios/Edit/$idG" "/Usuarios/Edit/$idG" @{ Id = $idG; Email = $eG; Rol = "AdministradorPrincipal" }
Registrar "Gerencia: no se autopromueve a Administrador principal" ((SQL "SELECT COUNT(*) FROM UsuarioRoles ur JOIN Roles r ON r.Id=ur.RoleId WHERE ur.UserId='$idG' AND r.Name='AdministradorPrincipal'") -eq "0")

# ---------- 4. CSRF, asignación masiva, validaciones ----------
$r = Enviar $adm "" "/Proyectos/Create" @{ Codigo = "QA-CSRF$run"; Nombre = "x"; Area = "1"; Estado = "1" } -SinToken
Registrar "POST sin token antifalsificación rechazado (400)" ($r.StatusCode -eq 400 -and (SQL "SELECT COUNT(*) FROM Proyectos WHERE Codigo='QA-CSRF$run'") -eq "0") "HTTP $($r.StatusCode)"
$r = Enviar $adm "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = "QA-MA$run"; Nombre = "Masiva"; Area = "1"; Estado = "1"; Id = "987654"; FechaRegistro = "2000-01-01" }
Registrar "Asignación masiva: Id y FechaRegistro ignorados (Proyecto)" ((SQL "SELECT COUNT(*) FROM Proyectos WHERE Codigo='QA-MA$run' AND Id<>987654 AND YEAR(FechaRegistro)>2000") -eq "1")
$r = Enviar $adm "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = "$pD"; ResponsableId = $uA; Codigo = "QA-MT$run"; Titulo = "x"; Prioridad = "1"; Estado = "2"; FechaInicio = (F $hoy); FechaLimite = (F $hoy.AddDays(3)); PorcentajeAvance = "10"; FechaRegistro = "2000-01-01"; FechaFinalizacion = (F $hoy.AddDays(-30)) }
Registrar "Asignación masiva: FechaRegistro ignorada y FechaFinalizacion limpiada (Tarea activa)" ((SQL "SELECT COUNT(*) FROM Tareas WHERE Codigo='QA-MT$run' AND YEAR(FechaRegistro)>2000 AND FechaFinalizacion IS NULL") -eq "1")
$r = NuevoUsuario "qa.adm$run@gestionftth.local" "AdministradorGerencia" $tA
Registrar "Asignación masiva: rol admin no recibe TrabajadorId" ((SQL "SELECT COUNT(*) FROM Usuarios WHERE Email='qa.adm$run@gestionftth.local' AND TrabajadorId IS NULL") -eq "1")

$r = Enviar $adm "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = ""; Nombre = ""; Area = ""; Estado = "" }
Registrar "Campos vacíos: Proyecto (mensajes en español)" ($r.StatusCode -eq 200 -and $r.Content -match "Ingrese el código del proyecto" -and $r.Content -match "Ingrese el nombre del proyecto" -and $r.Content -notmatch "is invalid")
$r = Enviar $adm "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = ""; ResponsableId = ""; Codigo = ""; Titulo = ""; Prioridad = "2"; Estado = "1"; FechaInicio = ""; FechaLimite = ""; PorcentajeAvance = "" }
Registrar "Campos vacíos: Tarea" ($r.StatusCode -eq 200 -and $r.Content -match "Ingrese el código de la tarea" -and $r.Content -match "Seleccione un responsable" -and $r.Content -match "Ingrese la fecha de inicio")
$r = Enviar $adm "/Usuarios/Create" "/Usuarios/Create" @{ Email = ""; Password = ""; ConfirmPassword = ""; Rol = "" }
Registrar "Campos vacíos: Usuario" ($r.StatusCode -eq 200 -and $r.Content -match "Ingrese el correo electrónico" -and $r.Content -match "Ingrese una contraseña")
$r = NuevoUsuario $eA "AdministradorGerencia" $null
Registrar "Duplicado: correo de usuario (mensaje en español)" ($r.StatusCode -eq 200 -and $r.Content -match "Ya existe una cuenta con")
$r = NuevoUsuario "qa.debil$run@gestionftth.local" "AdministradorGerencia" $null
$r = Enviar $adm "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.debil$run@gestionftth.local"; Password = "abcdef"; ConfirmPassword = "abcdef"; Rol = "AdministradorGerencia" }
Registrar "Contraseña débil rechazada (mensaje en español)" ($r.StatusCode -eq 200 -and $r.Content -match "al menos un número")

# ---------- 5. Registros inexistentes ----------
foreach ($u in "/Tareas/Details/999999", "/Tareas/Edit/999999", "/Proyectos/Details/999999", "/Trabajadores/Details/999999", "/Trabajadores/Edit/999999", "/Usuarios/Edit/no-existe") {
    $r = Get-Pagina $adm $u
    Registrar "Inexistente $u -> 404 con página" ($r.StatusCode -eq 404 -and $r.Content -match "Registro no encontrado") "HTTP $($r.StatusCode)"
}
$r = Enviar $adm "/Tareas" "/Tareas/Delete/999999" @{}
Registrar "POST Delete tarea inexistente -> 404" ($r.StatusCode -eq 404)

# ---------- 6. Identity: páginas deshabilitadas ----------
Registrar "Registro público deshabilitado incluso para administradores" (Denegado (Get-Pagina $adm "/Identity/Account/Register"))
Registrar "Eliminar propia cuenta (DeletePersonalData) deshabilitado" (Denegado (Get-Pagina $sA "/Identity/Account/Manage/DeletePersonalData"))
Registrar "Página Datos personales sin botón Eliminar" ((Get-Pagina $sA "/Identity/Account/Manage/PersonalData").Content -notmatch "DeletePersonalData")

# ---------- 7. Rol con tareas activas ----------
$r = Enviar $adm "/Usuarios/Edit/$uA" "/Usuarios/Edit/$uA" @{ Id = $uA; Email = $eA; Rol = "AdministradorGerencia" }
Registrar "No se quita el rol Trabajador a quien tiene tareas activas" ($r.StatusCode -eq 200 -and $r.Content -match "tarea\(s\) activa\(s\)")

# ---------- 8. Bloqueo por intentos fallidos ----------
$eL = "qa.lock$run@gestionftth.local"; $null = NuevoUsuario $eL "AdministradorGerencia" $null
for ($i = 1; $i -le 5; $i++) { $null = Login $eL "Incorrecta#1" }
$intento = Login $eL $passQA
Registrar "Bloqueo tras 5 intentos fallidos (incluso con la clave correcta)" ($intento.Respuesta.Location -match "Lockout") $intento.Respuesta.Location
Registrar "Página de bloqueo en español" ((Get-Pagina (New-Object Microsoft.PowerShell.Commands.WebRequestSession) "/Identity/Account/Lockout").Content -match "Cuenta bloqueada")
$idL = IdUsuario $eL
Registrar "Usuarios muestra la cuenta como Bloqueada" ((Get-Pagina $adm "/Usuarios").Content -match "Bloqueada")
$null = Enviar $adm "/Usuarios" "/Usuarios/Desbloquear/$idL" @{}
$intento = Login $eL $passQA
Registrar "Desbloquear permite volver a iniciar sesión" ($intento.Respuesta.StatusCode -eq 302 -and $intento.Respuesta.Location -notmatch "Lockout") $intento.Respuesta.Location

# ---------- 9. Invalidación de sesión (opcional, tarda ~70 s) ----------
if ($IncluirSesion) {
    $eS = "qa.ses$run@gestionftth.local"; $null = NuevoUsuario $eS "AdministradorGerencia" $null
    $sS = (Login $eS $passQA).Sesion
    $antes = Get-Pagina $sS "/Dashboard"
    $idS = IdUsuario $eS
    $null = Enviar $adm "/Usuarios" "/Usuarios/Delete/$idS" @{}
    Start-Sleep -Seconds 70
    $despues = Get-Pagina $sS "/Dashboard"
    Registrar "Sesión de un usuario eliminado se invalida (≤ 1 min)" ($antes.Content -match "Resumen general" -and $despues.Content -notmatch "Resumen general" -and $despues.Content -match "Input.Email") ""
}

$resultados
