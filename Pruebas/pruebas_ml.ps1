param([string]$Base = "http://localhost:5199", [string]$AdminEmail, [string]$AdminPass,
      [string]$Proyecto = "C:\GestionFTTH\GestionFTTH\GestionFTTH.Web")

# Auditoría funcional del módulo ML.NET. Usa datos QA (prefijo QA-H) que elimina al final
# y deja el modelo en modo demostrativo (estado inicial esperado sin historial real).

$ErrorActionPreference = "Continue"
$resultados = New-Object System.Collections.Generic.List[object]
function Registrar($nombre, $ok, $detalle = "") {
    $resultados.Add([pscustomobject]@{ Prueba = $nombre; Resultado = $(if ($ok) { "OK" } else { "FALLA" }); Detalle = $detalle })
}
function Token($html) { [regex]::Match($html, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"').Groups[1].Value }
function SQL($q) {
    # Reintentos: SQL Server Express puede rechazar logins puntualmente bajo carga
    for ($n = 1; $n -le 3; $n++) {
        $salida = sqlcmd -S "localhost\SQLEXPRESS" -E -C -I -d GestionFTTH -h -1 -W -b -l 60 -Q "SET NOCOUNT ON; $q" 2>&1
        if ($LASTEXITCODE -eq 0) { return ($salida | Where-Object { $_ -ne "" }) }
        Start-Sleep -Seconds 3
    }
    throw "sqlcmd falló tras 3 intentos: $salida"
}
$zip = Join-Path $Proyecto "MLModels\ModeloRetraso.zip"
$json = Join-Path $Proyecto "MLModels\ModeloRetraso.json"
$csv = Join-Path $Proyecto "MLModels\DatosEntrenamiento.csv"
function Info() { Get-Content $json -Raw -Encoding UTF8 | ConvertFrom-Json }

$s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$p = Invoke-WebRequest "$Base/Identity/Account/Login" -WebSession $s -UseBasicParsing
$null = Invoke-WebRequest "$Base/Identity/Account/Login" -Method Post -WebSession $s -UseBasicParsing -Body @{ "Input.Email" = $AdminEmail; "Input.Password" = $AdminPass; "__RequestVerificationToken" = (Token $p.Content) }

function Entrenar([switch]$PermitirDemo) {
    $m = Invoke-WebRequest "$Base/ModeloRiesgo" -WebSession $s -UseBasicParsing
    $body = @{ "__RequestVerificationToken" = (Token $m.Content) }
    if ($PermitirDemo) { $body["permitirDemoSobreReal"] = "true" }
    $r = Invoke-WebRequest "$Base/ModeloRiesgo/Entrenar" -Method Post -WebSession $s -UseBasicParsing -Body $body
    $txt = [System.Net.WebUtility]::HtmlDecode($r.Content)
    return ([regex]::Match($txt, '(?s)alert alert-(success|danger)[^>]*>\s*(.*?)\s*<button')).Groups[2].Value -replace '\s+', ' '
}
function Pagina($url) { [System.Net.WebUtility]::HtmlDecode((Invoke-WebRequest "$Base$url" -WebSession $s -UseBasicParsing).Content) }

# Limpieza previa de datos históricos QA
SQL "DELETE FROM Tareas WHERE Codigo LIKE 'QA-H%'; DELETE FROM Proyectos WHERE Codigo = 'QA-H-PRY';" | Out-Null

# ---------- 1. Datos DEMO ----------
$filas = Import-Csv $csv
Registrar "CSV demostrativo: todas las filas marcadas Origen=DEMO" (@($filas | Where-Object { $_.Origen -ne "DEMO" }).Count -eq 0) "$($filas.Count) filas"
Registrar "CSV demostrativo: contiene ambas clases" ((@($filas | ? { $_.SeRetraso -eq 'true' }).Count -gt 0) -and (@($filas | ? { $_.SeRetraso -eq 'false' }).Count -gt 0))
Registrar "CSV demostrativo: sin columnas de información futura" (-not ($filas[0].PSObject.Properties.Name -match 'Finaliz|Final|Cierre'))

$msg = Entrenar -PermitirDemo
$i = Info
Registrar "Entrenamiento demo: guardado y marcado demostrativo" ($msg -match "MODO DEMOSTRATIVO" -and $i.ModoDemostrativo -eq $true) $msg
Registrar "Entrenamiento demo: división aleatoria estratificada declarada" ($i.TipoDivision -match "estratificada") $i.TipoDivision
Registrar "Entrenamiento demo: métricas marcadas no confiables" ($i.MetricasConfiables -eq $false)
$f1 = if (($i.Precision + $i.Recall) -gt 0) { 2 * $i.Precision * $i.Recall / ($i.Precision + $i.Recall) } else { 0 }
Registrar "Métricas coherentes (F1 = 2PR/(P+R))" ([math]::Abs($f1 - $i.F1Score) -lt 0.001) "F1 informado $($i.F1Score) / calculado $([math]::Round($f1,4))"
Registrar "Línea base informada y superada" ($i.AccuracyLineaBase -gt 0 -and $i.Accuracy -gt $i.AccuracyLineaBase) "Accuracy $($i.Accuracy) vs línea base $($i.AccuracyLineaBase)"
$demoAcc = $i.Accuracy
$msg2 = Entrenar -PermitirDemo
Registrar "Reproducibilidad (misma accuracy al reentrenar)" ((Info).Accuracy -eq $demoAcc) "$demoAcc / $((Info).Accuracy)"
$t = Pagina "/Tareas"
Registrar "Interfaz indica modo demostrativo" ($t -match "text-dark`">Modo demostrativo")

# ---------- 2. Histórico real (QA) con ruido y fechas escalonadas ----------
$sqlHist = @"
DECLARE @p int;
INSERT INTO Proyectos(Codigo,Nombre,Area,Estado,FechaRegistro) VALUES('QA-H-PRY','Historico QA',2,3,SYSUTCDATETIME());
SET @p = SCOPE_IDENTITY();
DECLARE @i int = 1;
WHILE @i <= 80
BEGIN
  DECLARE @d int = 8 + (@i * 7) % 20;
  DECLARE @ini date = DATEADD(day, -(400 - @i * 4), CAST(GETDATE() AS date));
  DECLARE @lim date = DATEADD(day, @d, @ini);
  DECLARE @lento bit = CASE WHEN (@i * 3) % 7 < 3 THEN 1 ELSE 0 END;
  -- ruido: 1 de cada 5 tareas contradice el patrón de avance
  DECLARE @late bit = CASE WHEN @i % 5 = 0 THEN 1 - @lento ELSE @lento END;
  DECLARE @fin date = CASE WHEN @late = 1 THEN DATEADD(day, 2 + @i % 6, @lim) ELSE DATEADD(day, -(@i % 2), @lim) END;
  INSERT INTO Tareas(Codigo,Titulo,ProyectoId,Estado,Prioridad,FechaInicio,FechaLimite,FechaFinalizacion,PorcentajeAvance,FechaRegistro)
  VALUES(CONCAT('QA-H', @i), CONCAT('Historico QA ', @i), @p, 3, 1 + @i % 3, @ini, @lim, @fin, 100, SYSUTCDATETIME());
  DECLARE @t int = SCOPE_IDENTITY();
  INSERT INTO TareaAvances(TareaId,Fecha,PorcentajeAvance,Estado,Prioridad,FechaInicioPlan,FechaLimitePlan) VALUES
   (@t, DATEADD(day, @d*3/10, @ini), CASE WHEN @lento=1 THEN 10 + @i%8 ELSE 28 + @i%9 END, 2, 1 + @i % 3, @ini, @lim),
   (@t, DATEADD(day, @d*6/10, @ini), CASE WHEN @lento=1 THEN 30 + @i%9 ELSE 58 + @i%8 END, 2, 1 + @i % 3, @ini, @lim),
   (@t, DATEADD(day, @d*8/10, @ini), CASE WHEN @lento=1 THEN 48 + @i%10 ELSE 78 + @i%7 END, 2, 1 + @i % 3, @ini, @lim);
  SET @i += 1;
END
"@
SQL $sqlHist | Out-Null
$nTareas = [int](SQL "SELECT COUNT(*) FROM Tareas WHERE Codigo LIKE 'QA-H%' AND Codigo <> 'QA-H-PRY'")
$hashDemo = (Get-FileHash $zip).Hash

$msg = Entrenar
$i = Info
Registrar "Usa histórico real cuando existe" ($msg -match "datos históricos reales" -and $i.ModoDemostrativo -eq $false -and $i.OrigenDatos -match "SQL Server") "$msg | $($i.OrigenDatos)"
Registrar "Evaluación temporal y agrupada por tarea" ($i.TipoDivision -match "Temporal y agrupada por tarea") $i.TipoDivision
Registrar "20 % de las TAREAS en evaluación (no de las filas)" ($i.TareasEvaluacion -eq [math]::Round($nTareas * 0.2) -and ($i.TareasEntrenamiento + $i.TareasEvaluacion) -eq $nTareas) "Tareas: $($i.TareasEntrenamiento) entrenamiento / $($i.TareasEvaluacion) evaluación de $nTareas"
Registrar "Modelo real reemplaza al demo y se recarga" ((Get-FileHash $zip).Hash -ne $hashDemo -and (Pagina "/Tareas") -notmatch "text-dark`">Modo demostrativo")
Registrar "Métricas reales no perfectas con datos con ruido" ($i.Accuracy -lt 1) "Accuracy $($i.Accuracy), AUC $($i.Auc), línea base $($i.AccuracyLineaBase)"
$adv = ($i.Advertencias -join " ")
Registrar "Advertencia de corte temporal registrada" ($adv -match "Evaluación temporal") ""

# ---------- 3. Protección real -> demo ----------
$hashReal = (Get-FileHash $zip).Hash
SQL "DELETE FROM Tareas WHERE Codigo LIKE 'QA-H%'; DELETE FROM Proyectos WHERE Codigo = 'QA-H-PRY';" | Out-Null
$msg = Entrenar
Registrar "Sin historial suficiente NO reemplaza el modelo real por el demo" ($msg -match "Se conserva el modelo real" -and (Get-FileHash $zip).Hash -eq $hashReal -and (Info).ModoDemostrativo -eq $false) $msg

# ---------- 4. Fallo de entrenamiento conserva el último modelo válido ----------
Rename-Item $csv "DatosEntrenamiento.csv.qa"
$msg = Entrenar -PermitirDemo
$conservado = (Get-FileHash $zip).Hash -eq $hashReal
$listado = (Invoke-WebRequest "$Base/Tareas" -WebSession $s -UseBasicParsing).StatusCode
Rename-Item (Join-Path $Proyecto "MLModels\DatosEntrenamiento.csv.qa") "DatosEntrenamiento.csv"
Registrar "Error de entrenamiento: mensaje controlado y modelo conservado" ($msg -match "Se conserva el último modelo válido" -and $conservado -and $listado -eq 200) $msg

# ---------- 5. Volver a modo demostrativo de forma explícita ----------
$msg = Entrenar -PermitirDemo
Registrar "Reemplazo explícito por modelo demostrativo (opción marcada)" ($msg -match "MODO DEMOSTRATIVO" -and (Info).ModoDemostrativo -eq $true -and (Pagina "/Tareas") -match "text-dark`">Modo demostrativo") $msg

$resultados
