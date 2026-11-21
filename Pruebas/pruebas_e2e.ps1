param([string]$Base = "http://localhost:5199", [string]$AdminEmail, [string]$AdminPass)

$ErrorActionPreference = "Continue"
$resultados = New-Object System.Collections.Generic.List[object]
$run = Get-Random -Minimum 1000 -Maximum 9999
$hoy = Get-Date

function Registrar($nombre, $ok, $detalle = "") {
    $resultados.Add([pscustomobject]@{ Prueba = $nombre; Resultado = $(if ($ok) { "OK" } else { "FALLA" }); Detalle = $detalle })
}

function Token($html) {
    $m = [regex]::Match($html, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"')
    if (-not $m.Success) { $m = [regex]::Match($html, 'value="([^"]+)"[^>]*name="__RequestVerificationToken"') }
    return $m.Groups[1].Value
}

function Get-Pagina($sesion, $url) {
    try { $x = Invoke-WebRequest "$Base$url" -WebSession $sesion -UseBasicParsing -MaximumRedirection 5; return [pscustomobject]@{ Content = [System.Net.WebUtility]::HtmlDecode($x.Content); StatusCode = $x.StatusCode } }
    catch { return $_.Exception.Response }
}

# POST de formulario: toma el token de $urlForm y devuelve la respuesta (sin seguir redirección)
function Enviar($sesion, $urlForm, $urlPost, $campos) {
    $pagina = Invoke-WebRequest "$Base$urlForm" -WebSession $sesion -UseBasicParsing
    $campos["__RequestVerificationToken"] = Token $pagina.Content
    try {
        return Invoke-WebRequest "$Base$urlPost" -Method Post -Body $campos -WebSession $sesion -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
    } catch {
        $r = $_.Exception.Response
        if ($r -ne $null) { return $r }
        throw
    }
}

function Codigo($resp) { try { return [int]$resp.StatusCode } catch { return -1 } }
function Ubicacion($resp) { try { return [string]$resp.Headers["Location"] } catch { return "" } }

function Login($email, $pass) {
    $s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $r = Enviar $s "/Identity/Account/Login" "/Identity/Account/Login" @{ "Input.Email" = $email; "Input.Password" = $pass; "Input.RememberMe" = "false" }
    return @{ Sesion = $s; Respuesta = $r }
}

function F($d) { return $d.ToString("yyyy-MM-dd") }

# ================= 1. Autenticación =================
$adm = Login $AdminEmail $AdminPass
$s = $adm.Sesion
Registrar "Login administrador" ((Codigo $adm.Respuesta) -eq 302) "HTTP $(Codigo $adm.Respuesta) -> $(Ubicacion $adm.Respuesta)"

$r = Get-Pagina $s "/"
Registrar "Inicio admin redirige a Dashboard" ($r.Content -match "Resumen general" -and $r.Content -match "Seguimiento de tareas") ""

$anon = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$r = Get-Pagina $anon "/Identity/Account/Register"
Registrar "Registro público bloqueado (anónimo)" ($r.Content -match 'Input.Password' -and $r.Content -notmatch 'Input.ConfirmPassword') "Muestra login en lugar del registro"

$r = Get-Pagina $anon "/Tareas"
Registrar "Tareas exige autenticación" ($r.Content -match 'Input.Email') ""

# ================= 2. Trabajadores =================
$r = Enviar $s "/Trabajadores/Create" "/Trabajadores/Create" @{ Nombres = "QA Ana$run"; Apellidos = "Prueba Campo"; Area = "2"; Cargo = "Técnico QA" }
Registrar "Crear trabajador 1" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Enviar $s "/Trabajadores/Create" "/Trabajadores/Create" @{ Nombres = "QA Luis"; Apellidos = "Prueba Jefe"; Area = "2"; Cargo = "Jefe QA" }
Registrar "Crear trabajador 2" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Enviar $s "/Trabajadores/Create" "/Trabajadores/Create" @{ Nombres = ""; Apellidos = ""; Area = "9"; Cargo = "" }
Registrar "Validación trabajador vacío" ((Codigo $r) -eq 200 -and $r.Content -match "Ingrese los nombres") ""

$lista = (Get-Pagina $s "/Trabajadores").Content
$ids = [regex]::Matches($lista, '/Trabajadores/Details/(\d+)') | % { [int]$_.Groups[1].Value } | Sort-Object -Unique
$idTrab = $ids[-2]; $idJefe = $ids[-1]
Registrar "Listar trabajadores" ($lista -match "QA Ana$run" -and $lista -match "TRB\d{4}") "ids $idTrab, $idJefe"

$r = Enviar $s "/Trabajadores/Edit/$idTrab" "/Trabajadores/Edit/$idTrab" @{ Id = "$idTrab"; Nombres = "QA Ana$run María"; Apellidos = "Prueba Campo"; Area = "2"; Cargo = "Técnico QA" }
$det = (Get-Pagina $s "/Trabajadores/Details/$idTrab").Content
Registrar "Editar y ver trabajador" ((Codigo $r) -eq 302 -and $det -match "QA Ana$run María") ""

# ================= 3. Usuarios =================
$passQA = "Qa#" + [guid]::NewGuid().ToString("N").Substring(0, 10) + "x9"   # contraseña aleatoria por ejecución (cuentas QA temporales)
$r = Enviar $s "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.trabajador$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "Trabajador"; TrabajadorId = "$idTrab" }
Registrar "Crear usuario Trabajador" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Enviar $s "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.jefe$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "JefeArea"; TrabajadorId = "$idJefe" }
Registrar "Crear usuario JefeArea" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Enviar $s "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.dup$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "Trabajador"; TrabajadorId = "$idTrab" }
Registrar "Validación trabajador ya vinculado" ((Codigo $r) -eq 200 -and $r.Content -match "ya tiene una cuenta") ""

$r = Enviar $s "/Trabajadores" "/Trabajadores/Delete/$idTrab" @{}
$lista = (Get-Pagina $s "/Trabajadores").Content
Registrar "Bloqueo eliminar trabajador con cuenta" ($lista -match "QA Ana$run María" -and $lista -match "No se puede eliminar") ""

# ================= 4. Proyectos =================
$codP = "QA-PRY-" + (Get-Random -Maximum 9999)
$r = Enviar $s "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = $codP; Nombre = "Proyecto QA"; Descripcion = "Proyecto de prueba"; Area = "2"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-30)); FechaEntrega = (F $hoy.AddDays(60)) }
Registrar "Crear proyecto" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Enviar $s "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = $codP; Nombre = "Duplicado"; Area = "2"; Estado = "1" }
Registrar "Validación código de proyecto duplicado" ((Codigo $r) -eq 200 -and $r.Content -match "Ya existe otro proyecto") ""

$lista = (Get-Pagina $s "/Proyectos").Content
$idP = [int]([regex]::Matches($lista, '/Proyectos/Edit/(\d+)') | % { [int]$_.Groups[1].Value } | Sort-Object | Select-Object -Last 1)
Registrar "Listado de proyectos con acciones Ver/Editar/Eliminar" ($lista -match $codP -and $lista -match "/Proyectos/Edit/$idP" -and $lista -match "/Proyectos/Delete/$idP") "id $idP"

# EDITAR PROYECTO (prioridad de la auditoría)
$edit = Get-Pagina $s "/Proyectos/Edit/$idP"
$cargaOk = $edit.Content -match "value=`"$codP`"" -and $edit.Content -match 'value="Proyecto QA"' -and $edit.Content -match '<option selected="selected" value="2">Diseño</option>' -and $edit.Content -match '<option selected="selected" value="2">En ejecución</option>'
Registrar "Editar proyecto: carga datos actuales y combos" $cargaOk ""
$r = Enviar $s "/Proyectos/Edit/$idP" "/Proyectos/Edit/$idP" @{ Id = "$idP"; Codigo = $codP; Nombre = "Proyecto QA Editado"; Descripcion = "Descripción editada"; Area = "2"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-30)); FechaEntrega = (F $hoy.AddDays(90)) }
$det = Get-Pagina $s (Ubicacion $r)
Registrar "Editar proyecto: guarda y muestra confirmación" ((Codigo $r) -eq 302 -and $det.Content -match "Proyecto actualizado correctamente" -and $det.Content -match "Proyecto QA Editado") "Redirige a $(Ubicacion $r)"
$lista = (Get-Pagina $s "/Proyectos").Content
Registrar "Editar proyecto: cambios visibles en listado" ($lista -match "Proyecto QA Editado" -and $lista -match $hoy.AddDays(90).ToString("dd/MM/yyyy")) ""
$r = Enviar $s "/Proyectos/Edit/$idP" "/Proyectos/Edit/$idP" @{ Id = "$idP"; Codigo = $codP; Nombre = "X"; Area = "2"; Estado = "2"; FechaInicio = (F $hoy); FechaEntrega = (F $hoy.AddDays(-5)) }
Registrar "Editar proyecto: validación de fechas" ((Codigo $r) -eq 200 -and $r.Content -match "no puede ser anterior al inicio") ""
$r = Enviar $s "/Proyectos/Edit/$idP" "/Proyectos/Edit/999999" @{ Id = "999999"; Codigo = "QA-NOEXISTE"; Nombre = "X"; Area = "2"; Estado = "2" }
Registrar "Editar proyecto inexistente -> 404" ((Codigo $r) -eq 404) "HTTP $(Codigo $r)"
$r = Get-Pagina $s "/Proyectos/Edit/999999"
Registrar "GET editar proyecto inexistente -> 404" ((Codigo $r) -eq 404) "HTTP $(Codigo $r)"

# ================= 5. Tareas + ML.NET =================
$usuarios = (Get-Pagina $s "/Tareas/Create").Content
$idResp = [regex]::Match($usuarios, '<option value="([0-9a-f\-]{36})">QA Ana' + $run).Groups[1].Value
Registrar "Formulario de tarea carga proyectos y trabajadores" ($idResp -ne "" -and $usuarios -match $codP) ""

function NuevaTarea($cod, $titulo, $prio, $ini, $lim, $avance, $estado) {
    return Enviar $s "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = "$idP"; ResponsableId = $idResp; Codigo = $cod; Titulo = $titulo; Descripcion = "Tarea QA"; Prioridad = "$prio"; Estado = "$estado"; FechaInicio = (F $ini); FechaLimite = (F $lim); PorcentajeAvance = "$avance" }
}

$sufijo = Get-Random -Maximum 9999
$r1 = NuevaTarea "QA-A$sufijo" "QA retrasada" 3 $hoy.AddDays(-7) $hoy.AddDays(3) 30 2
$r2 = NuevaTarea "QA-B$sufijo" "QA al dia" 2 $hoy.AddDays(-2) $hoy.AddDays(8) 80 2
$r3 = NuevaTarea "QA-C$sufijo" "QA futura" 1 $hoy.AddDays(5) $hoy.AddDays(15) 0 1
$r4 = NuevaTarea "QA-D$sufijo" "QA finalizada" 2 $hoy.AddDays(-20) $hoy.AddDays(-5) 100 3
Registrar "Crear 4 tareas" (((Codigo $r1),(Codigo $r2),(Codigo $r3),(Codigo $r4) | ? { $_ -ne 302 }).Count -eq 0) "HTTP $(Codigo $r1),$(Codigo $r2),$(Codigo $r3),$(Codigo $r4)"
$r = NuevaTarea "QA-A$sufijo" "dup" 1 $hoy $hoy.AddDays(1) 0 1
Registrar "Validación código de tarea duplicado" ((Codigo $r) -eq 200 -and $r.Content -match "Ya existe una tarea") ""
$r = Enviar $s "/Tareas/Create" "/Tareas/Create" @{ ProyectoId = "$idP"; ResponsableId = $idResp; Codigo = "QA-E$sufijo"; Titulo = "x"; Prioridad = "2"; Estado = "1"; FechaInicio = (F $hoy); FechaLimite = (F $hoy.AddDays(-1)); PorcentajeAvance = "150" }
Registrar "Validación avance > 100 y fechas inválidas" ((Codigo $r) -eq 200 -and $r.Content -match "entre 0 y 100" -and $r.Content -match "no puede ser anterior") ""

$idx = (Get-Pagina $s "/Tareas").Content
$filas = [regex]::Matches($idx, '(?s)<tr>.*?</tr>') | % { $_.Value }
function FilaDe($cod) { return ($filas | ? { $_ -match [regex]::Escape($cod) } | Select-Object -First 1) }
function RiesgoDe($fila) { $m = [regex]::Match($fila, '(?s)class="btn-riesgo[^"]*".*?</span>\s*([^<]+?)\s*</button>'); return $m.Groups[1].Value.Trim() }

$fA = FilaDe "QA-A$sufijo"; $fB = FilaDe "QA-B$sufijo"; $fC = FilaDe "QA-C$sufijo"; $fD = FilaDe "QA-D$sufijo"
$rA = RiesgoDe $fA; $rB = RiesgoDe $fB; $rC = RiesgoDe $fC; $rD = RiesgoDe $fD
Registrar "Columna 'Riesgo de retraso (ML.NET)' en listado" ($idx -match "Riesgo de retraso \(ML.NET\)" -and $idx -match "Predicción ML.NET" -and $idx -match "no sustituye\s+la evaluación") ""
Registrar "Predicción tarea atrasada (Alta, 10 días, 30%, 7 días)" ($rA -match '^(ALTO|BAJO) - \d+%$') "Resultado: $rA"
Registrar "Predicción tarea al día (Media, 10 días, 80%, 2 días)" ($rB -match '^(ALTO|BAJO) - \d+%$') "Resultado: $rB"
Registrar "Tarea atrasada con más riesgo que la tarea al día" ([int]($rA -replace '\D','') -gt [int]($rB -replace '\D','')) "$rA vs $rB"
Registrar "Tarea no iniciada -> No disponible" ($rC -eq "No disponible" -and $fC -match "aún no ha iniciado") "Resultado: $rC"
Registrar "Tarea finalizada -> No disponible" ($rD -eq "No disponible" -and $fD -match "ya está finalizada") "Resultado: $rD"
Registrar "Modal de detalle de predicción presente" ($idx -match 'id="modalPrediccion"' -and $fA -match 'data-duracion="10"' -and $fA -match 'data-dias="7"' -and $fA -match 'data-avance="30"') ""

$idA = [int][regex]::Match($fA, '/Tareas/Details/(\d+)').Groups[1].Value
$det = (Get-Pagina $s "/Tareas/Details/$idA").Content
Registrar "Ver detalle de tarea con predicción e historial" ($det -match "Riesgo de retraso \(ML.NET\)" -and $det -match "Historial de avance" -and $det -match "30 %") ""

$edit = (Get-Pagina $s "/Tareas/Edit/$idA").Content
Registrar "Editar tarea: carga datos" ($edit -match "QA-A$sufijo" -and $edit -match "QA retrasada" -and $edit -match "value=`"$(F $hoy.AddDays(-7))`"") ""
$r = Enviar $s "/Tareas/Edit/$idA" "/Tareas/Edit/$idA" @{ Id = "$idA"; ProyectoId = "$idP"; ResponsableId = $idResp; Codigo = "QA-A$sufijo"; Titulo = "QA retrasada editada"; Prioridad = "3"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-7)); FechaLimite = (F $hoy.AddDays(3)); PorcentajeAvance = "60" }
$det = (Get-Pagina $s (Ubicacion $r)).Content
Registrar "Editar tarea: guarda y confirma" ((Codigo $r) -eq 302 -and $det -match "se actualizó correctamente" -and $det -match "QA retrasada editada" -and $det -match "60 %") ""
$rA2 = RiesgoDe ((([regex]::Matches((Get-Pagina $s "/Tareas").Content, '(?s)<tr>.*?</tr>') | % { $_.Value }) | ? { $_ -match "QA-A$sufijo" } | Select-Object -First 1))
Registrar "La predicción cambia con el avance (30% -> 60%)" ($rA2 -ne $rA) "Antes: $rA / Después: $rA2"

$r = Enviar $s "/Tareas/Details/$idA" "/Tareas/ActualizarAvance" @{ Id = "$idA"; PorcentajeAvance = "100"; Estado = "3" }
$det = (Get-Pagina $s "/Tareas/Details/$idA").Content
Registrar "Actualizar avance a Finalizada (fecha real automática)" ((Codigo $r) -eq 302 -and $det -match "Finalizó a tiempo" -and $det -match "ya está finalizada") ""

$filtro = (Get-Pagina $s "/Tareas?filtro=riesgo-alto").Content
Registrar "Filtro riesgo alto funciona" ($filtro -notmatch "QA-C$sufijo" -and $filtro -notmatch "QA-D$sufijo") ""

# ================= 6. Roles =================
$trab = Login "qa.trabajador$run@gestionftth.local" $passQA
Registrar "Login usuario creado desde módulo Usuarios" ((Codigo $trab.Respuesta) -eq 302) "HTTP $(Codigo $trab.Respuesta)"
$t = (Get-Pagina $trab.Sesion "/").Content
Registrar "Trabajador: entra a Mis tareas y ve sus tareas" ($t -match "Mis tareas asignadas" -and $t -match "QA-B$sufijo" -and $t -notmatch "/Tareas/Create") ""
$t = Get-Pagina $trab.Sesion "/Dashboard"
Registrar "Trabajador: Dashboard denegado" ($t.Content -match "Access denied|Acceso denegado|AccessDenied" -or (Codigo $t) -eq 403) ""
$idB = [int][regex]::Match((FilaDe "QA-B$sufijo"), '/Tareas/Details/(\d+)').Groups[1].Value
$r = Enviar $trab.Sesion "/Tareas/Details/$idB" "/Tareas/ActualizarAvance" @{ Id = "$idB"; PorcentajeAvance = "85"; Estado = "2" }
Registrar "Trabajador: actualiza avance de su tarea" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"

$jefe = Login "qa.jefe$run@gestionftth.local" $passQA
$j = (Get-Pagina $jefe.Sesion "/").Content
Registrar "Jefe de área: ve tareas de su área y puede crear" ($j -match "Tareas del área de Diseño" -and $j -match "QA-B$sufijo" -and $j -match "/Tareas/Create") ""

# ================= 7. Integridad y eliminaciones =================
$r = Enviar $s "/Proyectos/Details/$idP" "/Proyectos/Delete/$idP" @{}
$det = (Get-Pagina $s "/Proyectos/Details/$idP").Content
Registrar "Bloqueo eliminar proyecto con tareas" ($det -match "No se puede eliminar el proyecto") ""

# ================= 8. Modelo ML (administración) =================
$m = (Get-Pagina $s "/ModeloRiesgo").Content
Registrar "Pantalla del modelo con métricas y modo demostrativo" ($m -match "MODO DEMOSTRATIVO" -and $m -match "Accuracy" -and $m -match "AUC") ""
$r = Enviar $s "/ModeloRiesgo" "/ModeloRiesgo/Entrenar" @{}
$m = (Get-Pagina $s "/ModeloRiesgo").Content
Registrar "Reentrenamiento controlado desde la interfaz" ((Codigo $r) -eq 302 -and $m -match "Modelo entrenado y guardado") ""
$r = Enviar $trab.Sesion "/Tareas" "/ModeloRiesgo/Entrenar" @{}
Registrar "Trabajador no puede reentrenar" ((Codigo $r) -ne 302 -or (Ubicacion $r) -match "AccessDenied") "HTTP $(Codigo $r) $(Ubicacion $r)"

# ================= 9. Usuarios: editar / eliminar =================
$uIdx = (Get-Pagina $s "/Usuarios").Content
$idUJefe = [regex]::Match($uIdx, '(?s)qa\.jefe' + $run + '@gestionftth\.local.*?/Usuarios/Edit/([0-9a-f\-]{36})').Groups[1].Value
$r = Enviar $s "/Usuarios/Edit/$idUJefe" "/Usuarios/Edit/$idUJefe" @{ Id = $idUJefe; Email = "qa.jefe2$run@gestionftth.local"; Rol = "JefeArea"; TrabajadorId = "$idJefe"; NuevaPassword = ""; ConfirmarNuevaPassword = "" }
$uIdx = (Get-Pagina $s "/Usuarios").Content
Registrar "Editar usuario" ((Codigo $r) -eq 302 -and $uIdx -match "qa.jefe2$run@gestionftth.local") "HTTP $(Codigo $r)"

# ================= 10. Permisos adicionales =================
# Tarea de otro responsable: creamos un 2.º trabajador con cuenta y una tarea suya
$r = Enviar $s "/Trabajadores/Create" "/Trabajadores/Create" @{ Nombres = "QA Otro$run"; Apellidos = "Prueba"; Area = "3"; Cargo = "Técnico" }
$lista = (Get-Pagina $s "/Trabajadores").Content
$idOtro = ([regex]::Matches($lista, '/Trabajadores/Details/(\d+)') | % { [int]$_.Groups[1].Value } | Sort-Object -Unique)[-1]
$null = Enviar $s "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.otro$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "Trabajador"; TrabajadorId = "$idOtro" }
$form = (Get-Pagina $s "/Tareas/Create").Content
$idRespOtro = [regex]::Match($form, '<option value="([0-9a-f\-]{36})">QA Otro' + $run).Groups[1].Value
$null = NuevaTarea "QA-F$sufijo" "QA de otro" 2 $hoy.AddDays(-1) $hoy.AddDays(9) 10 2
$fF = (([regex]::Matches((Get-Pagina $s "/Tareas").Content, '(?s)<tr>.*?</tr>') | % { $_.Value }) | ? { $_ -match "QA-F$sufijo" } | Select-Object -First 1)
$idF = [int][regex]::Match($fF, '/Tareas/Details/(\d+)').Groups[1].Value
$r = Enviar $s "/Tareas/Edit/$idF" "/Tareas/Edit/$idF" @{ Id = "$idF"; ProyectoId = "$idP"; ResponsableId = $idRespOtro; Codigo = "QA-F$sufijo"; Titulo = "QA de otro"; Prioridad = "2"; Estado = "2"; FechaInicio = (F $hoy.AddDays(-1)); FechaLimite = (F $hoy.AddDays(9)); PorcentajeAvance = "10" }
Registrar "Reasignar responsable de una tarea" ((Codigo $r) -eq 302) "HTTP $(Codigo $r)"
$r = Get-Pagina $trab.Sesion "/Tareas/Details/$idF"
Registrar "Trabajador no puede ver tarea ajena" ((Codigo $r) -eq 403 -or $r.Content -match "AccessDenied|Access denied|Acceso denegado") "HTTP $(Codigo $r)"
$r = Get-Pagina $trab.Sesion "/Tareas/Edit/$idB"
Registrar "Trabajador no puede editar tareas (solo avance)" ((Codigo $r) -eq 403 -or $r.Content -match "AccessDenied|Access denied|Acceso denegado") ""
$r = Get-Pagina $s "/Tareas/Details/999999"
Registrar "Tarea inexistente -> 404" ((Codigo $r) -eq 404) "HTTP $(Codigo $r)"

# Jerarquía de roles: Gerencia no puede crear Administrador principal
$null = Enviar $s "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.gerente$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "AdministradorGerencia" }
$ger = Login "qa.gerente$run@gestionftth.local" $passQA
$g = (Get-Pagina $ger.Sesion "/Usuarios/Create").Content
Registrar "Gerencia no ve la opción Administrador principal" ($g -notmatch 'value="AdministradorPrincipal"' -and $g -match 'value="AdministradorGerencia"') ""
$r = Enviar $ger.Sesion "/Usuarios/Create" "/Usuarios/Create" @{ Email = "qa.escalada$run@gestionftth.local"; Password = $passQA; ConfirmPassword = $passQA; Rol = "AdministradorPrincipal" }
Registrar "Gerencia no puede crear Administrador principal (POST directo)" ((Codigo $r) -eq 200 -and $r.Content -match "Solo un administrador principal") "HTTP $(Codigo $r)"

# Páginas de Identity para usuario autenticado
$r = Get-Pagina $s "/Identity/Account/Manage"
Registrar "Página Administrar cuenta" ((Codigo $r) -eq 200 -or $r.Content -match "Profile|Perfil") ""

# ================= 11. Eliminaciones =================
$r = Enviar $s "/Tareas" "/Tareas/Delete/$idF" @{}
$idx = (Get-Pagina $s "/Tareas").Content
Registrar "Eliminar tarea" ((Codigo $r) -eq 302 -and $idx -notmatch "/Tareas/Details/$idF`"" -and $idx -match "se eliminó correctamente") ""

$uIdx = (Get-Pagina $s "/Usuarios").Content
$idUOtro = [regex]::Match($uIdx, '(?s)qa\.otro' + $run + '@gestionftth\.local.*?/Usuarios/Delete/([0-9a-f\-]{36})').Groups[1].Value
$r = Enviar $s "/Usuarios" "/Usuarios/Delete/$idUOtro" @{}
$uIdx = (Get-Pagina $s "/Usuarios").Content
Registrar "Eliminar usuario" ((Codigo $r) -eq 302 -and $uIdx -notmatch "/Usuarios/Edit/$idUOtro" -and $idUOtro -ne "") ""

$r = Enviar $s "/Trabajadores" "/Trabajadores/Delete/$idOtro" @{}
$lista = (Get-Pagina $s "/Trabajadores").Content
Registrar "Eliminar trabajador sin cuenta" ((Codigo $r) -eq 302 -and $lista -notmatch "/Trabajadores/Details/$idOtro`"") ""

$adminId = [regex]::Match($uIdx, '(?s)Usted.*?').Success
Registrar "Admin no tiene botón para eliminarse a sí mismo" ([regex]::Match($uIdx, '(?s)<tr>(?:(?!</tr>).)*Usted(?:(?!</tr>).)*</tr>').Value -notmatch '/Usuarios/Delete/') ""

# Proyecto sin tareas: se puede eliminar
$codP2 = "QA-PRY-B" + (Get-Random -Maximum 9999)
$null = Enviar $s "/Proyectos/Create" "/Proyectos/Create" @{ Codigo = $codP2; Nombre = "Proyecto QA vacío"; Area = "1"; Estado = "1" }
$lista = (Get-Pagina $s "/Proyectos").Content
$idP2 = [int]([regex]::Matches($lista, '/Proyectos/Edit/(\d+)') | % { [int]$_.Groups[1].Value } | Sort-Object | Select-Object -Last 1)
$r = Enviar $s "/Proyectos" "/Proyectos/Delete/$idP2" @{}
$lista = (Get-Pagina $s "/Proyectos").Content
Registrar "Eliminar proyecto sin tareas" ((Codigo $r) -eq 302 -and $lista -notmatch "/Proyectos/Edit/$idP2`"" -and $lista -match "eliminado correctamente") ""

$resultados
