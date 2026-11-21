param([string]$Base = "http://localhost:5199", [string]$Email, [string]$Clave,
      [string]$Salida = "C:\GestionFTTH\GestionFTTH\Pruebas\capturas",
      [string]$Navegador = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
      [string[]]$Paginas = @("/Dashboard", "/Proyectos", "/Tareas", "/Trabajadores", "/Usuarios", "/ModeloRiesgo", "/Tareas/Create", "/Usuarios/Create"))

# Pruebas visuales con Edge headless controlado por DevTools Protocol (CDP):
# login real en el navegador, capturas en escritorio y móvil, clic en el
# indicador de riesgo (modal), desbordamiento horizontal y errores de consola.

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force $Salida | Out-Null
$perfil = Join-Path $env:TEMP ("edge-qa-" + [guid]::NewGuid().ToString("N"))
$puerto = 9333
$proc = Start-Process $Navegador -ArgumentList "--headless=new", "--remote-debugging-port=$puerto", "--user-data-dir=$perfil", "--no-first-run", "--disable-gpu", "about:blank" -PassThru

$resultados = New-Object System.Collections.Generic.List[object]
function Registrar($nombre, $ok, $detalle = "") { $resultados.Add([pscustomobject]@{ Prueba = $nombre; Resultado = $(if ($ok) { "OK" } else { "FALLA" }); Detalle = $detalle }) }

try {
    $objetivo = $null
    for ($i = 0; $i -lt 30 -and -not $objetivo; $i++) {
        Start-Sleep -Milliseconds 500
        try { $objetivo = (Invoke-RestMethod "http://127.0.0.1:$puerto/json/list") | Where-Object { $_.type -eq "page" } | Select-Object -First 1 } catch {}
    }
    if (-not $objetivo) { throw "No se pudo conectar con el navegador headless." }

    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ws.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(30)
    $ws.ConnectAsync([Uri]$objetivo.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
    $script:idMsg = 0
    $script:consola = New-Object System.Collections.Generic.List[string]

    function Recibir() {
        $buffer = New-Object byte[] 1048576
        $ms = New-Object IO.MemoryStream
        do {
            $seg = New-Object ArraySegment[byte] (, $buffer)
            $r = $ws.ReceiveAsync($seg, [Threading.CancellationToken]::None).Result
            $ms.Write($buffer, 0, $r.Count)
        } while (-not $r.EndOfMessage)
        return [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    }
    function CDP($metodo, $parametros = @{}) {
        $script:idMsg++
        $json = @{ id = $script:idMsg; method = $metodo; params = $parametros } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $ws.SendAsync((New-Object ArraySegment[byte] (, $bytes)), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
        while ($true) {
            $m = Recibir
            if ($m.method -eq "Runtime.exceptionThrown") { $script:consola.Add("Excepción JS: " + $m.params.exceptionDetails.exception.description) }
            if ($m.method -eq "Runtime.consoleAPICalled" -and $m.params.type -eq "error") { $script:consola.Add("console.error: " + ($m.params.args | % { $_.value }) -join " ") }
            if ($m.method -eq "Log.entryAdded" -and $m.params.entry.level -eq "error") { $script:consola.Add("Log: " + $m.params.entry.text + " " + $m.params.entry.url) }
            if ($m.id -eq $script:idMsg) { return $m }
        }
    }
    function JS($expr) { (CDP "Runtime.evaluate" @{ expression = $expr; returnByValue = $true; awaitPromise = $true }).result.result.value }
    function Ir($url) {
        $null = CDP "Page.navigate" @{ url = "$Base$url" }
        for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Milliseconds 250; if ((JS "document.readyState") -eq "complete") { break } }
        Start-Sleep -Milliseconds 400
    }
    function Pantalla($ancho, $alto, $movil) {
        $null = CDP "Emulation.setDeviceMetricsOverride" @{ width = $ancho; height = $alto; deviceScaleFactor = 1; mobile = $movil }
    }
    function Capturar($nombre) {
        $alto = [int](JS "Math.min(document.documentElement.scrollHeight, 2600)")
        $ancho = [int](JS "document.documentElement.clientWidth")
        $r = CDP "Page.captureScreenshot" @{ format = "png"; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = $ancho; height = $alto; scale = 1 } }
        $archivo = Join-Path $Salida "$nombre.png"
        [IO.File]::WriteAllBytes($archivo, [Convert]::FromBase64String($r.result.data))
        return $archivo
    }

    $null = CDP "Page.enable"; $null = CDP "Runtime.enable"; $null = CDP "Log.enable"
    Pantalla 1366 900 $false

    # ---- Login real en el navegador ----
    Ir "/Identity/Account/Login"
    $null = Capturar "00_login_escritorio"
    $emailJs = $Email | ConvertTo-Json; $claveJs = $Clave | ConvertTo-Json
    $null = JS "document.querySelector('#Input_Email').value=$emailJs; document.querySelector('#Input_Password').value=$claveJs; document.querySelector('#login-submit').click(); true"
    for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Milliseconds 250; if ((JS "location.pathname") -ne "/Identity/Account/Login" -and (JS "document.readyState") -eq "complete") { break } }
    $destino = JS "location.pathname"
    Registrar "Login desde el navegador ($Email)" ($destino -eq "/Dashboard" -or $destino -eq "/Tareas") $destino

    # ---- Recorrido de pantallas: escritorio y móvil ----
    $n = 1
    foreach ($p in $Paginas) {
        foreach ($modo in @(@{ N = "escritorio"; W = 1366; H = 900; M = $false }, @{ N = "movil"; W = 390; H = 844; M = $true })) {
            Pantalla $modo.W $modo.H $modo.M
            $script:consola.Clear()
            Ir $p
            $titulo = JS "document.title"
            $desborde = [int](JS "document.documentElement.scrollWidth - document.documentElement.clientWidth")
            $archivo = Capturar ("{0:00}_{1}_{2}" -f $n, ($p.Trim('/') -replace '/', '_'), $modo.N)
            Registrar "$p ($($modo.N)): carga sin errores JS" ($script:consola.Count -eq 0 -and $titulo -notmatch "Error") "$titulo $(($script:consola | Select-Object -First 2) -join ' | ')"
            Registrar "$p ($($modo.N)): sin desbordamiento horizontal de la página" ($desborde -le 0) "exceso $desborde px"
            if (-not $modo.M) {
                # En escritorio todas las columnas (incluidas las acciones) deben verse sin scroll
                $scrollTabla = [int](JS "Math.max(0, ...Array.from(document.querySelectorAll('.table-responsive')).map(t => t.scrollWidth - t.clientWidth))")
                Registrar "$p (escritorio): tablas visibles completas sin scroll horizontal" ($scrollTabla -le 0) "exceso $scrollTabla px"
            }
        }
        $n++
    }

    # ---- Modal de predicción: clic real ----
    Pantalla 1366 900 $false
    Ir "/Tareas"
    $hayBoton = JS "!!document.querySelector('button.btn-riesgo:not(.riesgo-nd)')"
    if ($hayBoton) {
        $null = JS "document.querySelector('button.btn-riesgo:not(.riesgo-nd)').click(); true"
        Start-Sleep -Milliseconds 900
        $visible = JS "document.querySelector('#modalPrediccion').classList.contains('show')"
        $datos = JS "['tarea','prioridad','duracion','dias','avance','probabilidad'].map(c => document.querySelector('#modalPrediccion [data-campo=' + c + ']').textContent.trim()).join(' | ')"
        $null = Capturar "90_modal_prediccion"
        Registrar "Modal de predicción se abre y muestra los datos" ($visible -and $datos -notmatch '\|\s*\|' -and $datos -match '%') $datos
        $null = JS "document.querySelector('#modalPrediccion .btn-close').click(); true"
        Start-Sleep -Milliseconds 600
        Registrar "Modal se cierra" (-not (JS "document.querySelector('#modalPrediccion').classList.contains('show')"))
    } else {
        Registrar "Modal de predicción (requiere tareas activas con predicción)" $false "No hay tareas con predicción en el listado"
    }

    # ---- Confirmación de eliminación (diálogo JS) ----
    $esGestor = JS "!!document.querySelector('a[href=\'/Tareas/Create\']')"
    $tieneConfirm = JS "!!document.querySelector('form[data-confirmar]')"
    if ($esGestor) {
        Registrar "Formularios de eliminación con confirmación" $tieneConfirm
    } else {
        Registrar "Rol sin permisos de eliminación: no se muestran botones Eliminar" (-not $tieneConfirm)
    }

    # ---- Validación en cliente (jQuery Validation) ----
    if ($Paginas -contains "/Proyectos") {
    Ir "/Proyectos/Create"
    $null = JS "document.querySelector('form[action=\'/Proyectos/Create\'] button[type=submit]').click(); true"
    Start-Sleep -Milliseconds 600
    $msgCliente = JS "Array.from(document.querySelectorAll('.field-validation-error')).map(e => e.textContent.trim()).join(' | ')"
    $sigueEnPagina = (JS "location.pathname") -eq "/Proyectos/Create"
    $null = Capturar "91_validacion_cliente"
    Registrar "Validación en cliente bloquea envío vacío (Proyecto)" ($sigueEnPagina -and $msgCliente -match "Ingrese el código") $msgCliente
    }

    # ---- Menú lateral plegable en móvil ----
    Pantalla 390 844 $true
    Ir $Paginas[0]
    $altoOculto = [int](JS "document.querySelector('#ftthMenu').getBoundingClientRect().height")
    $null = JS "document.querySelector('.ftth-menu-toggle').click(); true"
    Start-Sleep -Milliseconds 800
    $altoAbierto = [int](JS "document.querySelector('#ftthMenu').getBoundingClientRect().height")
    $null = Capturar "92_menu_movil_abierto"
    Registrar "Móvil: menú oculto al cargar y se despliega con el botón" ($altoOculto -eq 0 -and $altoAbierto -gt 100) "alto oculto $altoOculto px / abierto $altoAbierto px"
    Pantalla 1366 900 $false
    Ir $Paginas[0]
    $visibleEscritorio = [int](JS "document.querySelector('#ftthMenu').getBoundingClientRect().height")
    $botonVisible = JS "getComputedStyle(document.querySelector('.ftth-menu-toggle')).display !== 'none'"
    Registrar "Escritorio: menú siempre visible y sin botón de plegado" ($visibleEscritorio -gt 100 -and -not $botonVisible) "alto $visibleEscritorio px"

    # ---- Menú lateral: ítem activo y opciones según el rol ----
    Ir $Paginas[-1]
    $activo = JS "document.querySelector('.ftth-menu-item.active') ? document.querySelector('.ftth-menu-item.active').textContent.trim() : ''"
    $opciones = JS "Array.from(document.querySelectorAll('.ftth-menu a.ftth-menu-item')).map(a => a.textContent.trim().replace(/^\S+\s+/, '')).join(', ')"
    Registrar "Menú lateral: módulo activo y opciones del rol" ($activo -ne "") "activo: $activo | opciones: $opciones"
}
finally {
    try { $ws.Dispose() } catch {}
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.StartTime -ge $proc.StartTime -and ((Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine -match [regex]::Escape($perfil)) } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Remove-Item $perfil -Recurse -Force -ErrorAction SilentlyContinue
}

$resultados
