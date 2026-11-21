# Manual de ML.NET: riesgo de retraso de tareas

## 1. Qué hace

Para cada tarea **activa**, el modelo estima la probabilidad de que termine **después de su fecha límite**:

- **Riesgo ALTO**: probabilidad ≥ 60 % (umbral configurable).
- **Riesgo BAJO**: probabilidad < 60 %.
- **No disponible**: faltan datos para hacer una predicción fiable.

Se muestra en **Tareas** (columna *Riesgo de retraso (ML.NET)*, con un modal de detalle), en el detalle de cada tarea y en el **Dashboard**.
Es **una herramienta de apoyo**: no modifica fechas, estados ni prioridades, y no sustituye el criterio del responsable.

## 2. Datos que usa el modelo

| Característica | Origen |
|---|---|
| Prioridad (Alta / Media / Baja) | Prioridad de la tarea |
| Duración planificada (días) | Fecha límite − fecha de inicio |
| Porcentaje de avance | Avance registrado |
| Días transcurridos | Fecha de la observación − fecha de inicio |
| Proporción del plazo consumido y brecha de avance | Se calculan **solo** a partir de las anteriores |

**Etiqueta (lo que aprende a predecir):** la tarea terminó después de su fecha límite (`FechaFinalizacion > FechaLimite`).

**Sin información futura (sin *data leakage*):** cada ejemplo histórico es un registro diario de la tabla
`TareaAvances`, con el avance y el plan (prioridad y fechas) **vigentes ese día**. Nunca se usan el avance final, la
fecha real de cierre ni el estado final como entrada.

## 3. Modo demostrativo y modo real

| Modo | Cuándo | Cómo se identifica |
|---|---|---|
| **DEMOSTRATIVO** | La base aún no tiene historial suficiente. Se entrena con `MLModels/DatosEntrenamiento.csv`: 900 registros **simulados** con `Origen=DEMO` | Badge amarillo "Modo demostrativo" en Tareas, el modal, el detalle, el Dashboard y la pantalla del modelo |
| **REAL** | `TareaAvances` tiene al menos **60** registros válidos de tareas **finalizadas**, con casos a tiempo y con retraso | Origen "Histórico real (SQL Server)" en la pantalla del modelo; sin badge demo |

> **Estado actual: modo DEMOSTRATIVO.** Las métricas del modelo demo (accuracy 0,756, AUC 0,825) describen su
> desempeño con datos simulados y **no** indican el rendimiento real del sistema.

## 4. Cuándo se muestra "No disponible"

- La tarea está **finalizada** (no se predice lo que ya ocurrió).
- Falta la fecha de inicio o la fecha límite.
- La duración planificada es 0 días (inicio igual a límite) o negativa.
- La tarea **aún no ha iniciado** (fecha de inicio futura).
- El avance está fuera de 0–100 o la prioridad no es válida.
- No hay un modelo entrenado o no se pudo cargar (la aplicación sigue funcionando).

## 5. Entrenar o reentrenar el modelo

**Quién:** Administrador principal o Gerente de operaciones. **Dónde:** menú **Modelo ML.NET**.

1. Revise en la pantalla el modelo vigente: fecha, origen de datos, tipo de división y métricas.
2. Pulse **Entrenar / reentrenar modelo** y confirme.
3. El sistema:
   1. Carga el **histórico real** si alcanza el mínimo; si no, el CSV demostrativo.
   2. Descarta registros inválidos y exige ambas clases (con y sin retraso).
   3. Separa entrenamiento y evaluación:
      - **Datos reales:** separación **temporal y por tarea**. El 20 % de las tareas que finalizaron más recientemente se reserva para evaluar, y ninguna tarea aparece en ambos conjuntos.
      - **Datos demo:** separación aleatoria estratificada, porque no tienen fechas.
   4. Entrena el pipeline: OneHotEncoding(Prioridad) → Concatenate → NormalizeMeanVariance → **SdcaLogisticRegression**.
   5. Calcula Accuracy, Precision, Recall, F1, AUC y la **accuracy de línea base** (predecir siempre la clase mayoritaria).
   6. **Solo reemplaza el modelo vigente** si el nuevo cumple accuracy ≥ 0,60 y AUC ≥ 0,60. Si no, o si ocurre un error, **se conserva el anterior**.
   7. Guarda `MLModels/ModeloRetraso.zip` y `ModeloRetraso.json` y lo carga sin reiniciar la aplicación.

**Protección del modelo real:** si el modelo vigente es **real** y en algún momento el historial no alcanza el
mínimo, el reentrenamiento **no** lo sustituye por uno demostrativo. Para forzarlo hay que marcar
*"Permitir reemplazar el modelo real por uno demostrativo"*.

**Entrenamiento automático:** solo ocurre **una vez**, al iniciar la aplicación, si no existe `ModeloRetraso.zip`.
Nunca se entrena al abrir pantallas.

## 6. Cómo pasar al modo real

1. Registre las tareas con **fecha de inicio y fecha límite**.
2. Los responsables deben **actualizar el avance periódicamente**: cada actualización crea un registro histórico (uno por tarea y día).
3. Al terminar, marque la tarea como **Finalizada**. Si se finaliza en una fecha anterior a hoy, indíquela en *Editar → Fecha de finalización*.
4. Compruebe el volumen de datos disponibles:
   ```sql
   SELECT COUNT(*) AS RegistrosValidos
   FROM TareaAvances a JOIN Tareas t ON t.Id = a.TareaId
   WHERE t.Estado = 3 AND t.FechaFinalizacion IS NOT NULL
     AND a.Fecha < t.FechaFinalizacion;
   ```
5. Con ≥ 60 registros y ambos resultados (tareas a tiempo y con retraso), reentrene desde **Modelo ML.NET**.
6. Revise la pantalla del modelo:
   - El **origen** debe ser "Histórico real (SQL Server)".
   - La **accuracy** debe superar claramente la **línea base** y el **AUC** debe estar por encima de 0,5.
   - La indicación **"Métricas confiables"** aparece cuando la evaluación tiene al menos 30 registros y 10 tareas.

## 7. Configuración (`appsettings.json` → `MachineLearning`)

| Clave | Valor | Significado |
|---|---|---|
| `UmbralRiesgoAlto` | 0.60 | Probabilidad a partir de la cual el riesgo es ALTO (**único lugar donde se define**) |
| `RutaModelo` / `RutaDatosDemo` | `MLModels/…` | Rutas relativas a la carpeta de la aplicación |
| `MinimoRegistrosReales` | 60 | Registros históricos necesarios para usar datos reales |
| `MinimoRegistrosEntrenamiento` | 30 | Mínimo absoluto para entrenar |
| `AccuracyMinima` / `AucMinimo` | 0.60 / 0.60 | Validaciones que debe superar un modelo nuevo |
| `FraccionEvaluacion` | 0.20 | Fracción de tareas reservadas para evaluación |
| `EntrenarAlIniciarSiNoExiste` | true | Entrenamiento inicial si falta el modelo |
| `SemillaAleatoria` | 2026 | Reproducibilidad |

## 8. Archivos

| Archivo | Descripción |
|---|---|
| `MLModels/DatosEntrenamiento.csv` | Datos **simulados** (`Origen=DEMO`). Ver `LEEME_DATOS_DEMO.txt` |
| `MLModels/ModeloRetraso.zip` | Modelo entrenado (ML.NET) |
| `MLModels/ModeloRetraso.json` | Métricas, origen y advertencias del último entrenamiento |
| `Services/MachineLearning/TaskModelTrainer.cs` | Carga de datos, división, pipeline, evaluación y guardado seguro |
| `Services/MachineLearning/TaskPredictionService.cs` | Carga del modelo y predicción segura para concurrencia (un `PredictionEngine` por solicitud) |

**Respaldo:** copie `ModeloRetraso.zip` y `.json` antes de reentrenar si desea conservar una versión concreta.

## 9. Limitaciones

- Las probabilidades no están calibradas con datos reales mientras el modelo sea demostrativo.
- El modelo estima una **asociación** estadística; no explica causas.
- Varias actualizaciones en un mismo día guardan solo la última en el historial.
