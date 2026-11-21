param([string]$Base = "http://localhost:5199", [string]$AdminEmail, [string]$AdminPass, [int]$Tareas = 500)

# Mide tiempos de respuesta con un volumen de datos QA (prefijo QA-R) y los elimina al final.
$ErrorActionPreference = "Continue"
function SQL($q) { sqlcmd -S "localhost\SQLEXPRESS" -E -C -I -d GestionFTTH -h -1 -W -b -l 60 -Q "SET NOCOUNT ON; $q" | Where-Object { $_ -ne "" } }
function Token($html) { [regex]::Match($html, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"').Groups[1].Value }

SQL @"
DECLARE @p int;
INSERT INTO Proyectos(Codigo,Nombre,Area,Estado,FechaRegistro) VALUES('QA-R-PRY','Rendimiento QA',2,2,SYSUTCDATETIME());
SET @p = SCOPE_IDENTITY();
DECLARE @i int = 1;
WHILE @i <= $Tareas
BEGIN
  DECLARE @ini date = DATEADD(day, -(@i % 30), CAST(GETDATE() AS date));
  INSERT INTO Tareas(Codigo,Titulo,ProyectoId,Estado,Prioridad,FechaInicio,FechaLimite,PorcentajeAvance,FechaRegistro)
  VALUES(CONCAT('QA-R', @i), CONCAT('Rendimiento ', @i), @p, 1 + @i % 3, 1 + @i % 3, @ini, DATEADD(day, 5 + @i % 40, @ini), CASE WHEN @i % 3 = 2 THEN 100 ELSE @i % 100 END, SYSUTCDATETIME());
  INSERT INTO TareaAvances(TareaId,Fecha,PorcentajeAvance,Estado) VALUES (SCOPE_IDENTITY(), @ini, 0, 1);
  SET @i += 1;
END
"@ | Out-Null

$s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$p = Invoke-WebRequest "$Base/Identity/Account/Login" -WebSession $s -UseBasicParsing
$null = Invoke-WebRequest "$Base/Identity/Account/Login" -Method Post -WebSession $s -UseBasicParsing -Body @{ "Input.Email" = $AdminEmail; "Input.Password" = $AdminPass; "__RequestVerificationToken" = (Token $p.Content) }

$resultados = foreach ($url in "/Dashboard", "/Tareas", "/Tareas?filtro=riesgo-alto", "/Proyectos", "/Usuarios", "/Trabajadores") {
    $null = Invoke-WebRequest "$Base$url" -WebSession $s -UseBasicParsing   # calentamiento
    $tiempos = 1..5 | ForEach-Object {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-WebRequest "$Base$url" -WebSession $s -UseBasicParsing
        $sw.Stop(); $sw.ElapsedMilliseconds
    }
    $orden = $tiempos | Sort-Object
    [pscustomobject]@{ Pagina = $url; MedianaMs = $orden[2]; MaxMs = $orden[-1]; KB = [math]::Round($r.RawContentLength / 1KB) }
}

SQL "DELETE FROM Tareas WHERE Codigo LIKE 'QA-R%'; DELETE FROM Proyectos WHERE Codigo='QA-R-PRY';" | Out-Null
"Volumen: $Tareas tareas QA (eliminadas al final)"
$resultados
