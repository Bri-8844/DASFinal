# Manual de usuario por rol

## Roles y permisos

| Funcionalidad | Administrador principal | Gerente de operaciones (AdministradorGerencia) | Jefe de área | Trabajador |
|---|---|---|---|---|
| Dashboard | ✔ | ✔ | — | — |
| Proyectos (crear, ver, editar, eliminar) | ✔ | ✔ | — | — |
| Trabajadores (crear, ver, editar, eliminar) | ✔ | ✔ | — | — |
| Usuarios (crear, editar, eliminar, desbloquear) | ✔ todos | ✔ excepto Administradores principales | — | — |
| Modelo ML.NET (métricas y reentrenamiento) | ✔ | ✔ | — | — |
| Tareas: ver | Todas | Todas | Las de su área | Las asignadas a él |
| Tareas: crear, editar, eliminar | ✔ | ✔ | En su área | — |
| Tareas: actualizar avance | ✔ | ✔ | En su área | Las suyas |
| Reabrir una tarea finalizada | ✔ | ✔ | En su área | — |

Al iniciar sesión, cada rol entra directamente a su pantalla principal: los administradores al **Dashboard**, y el
jefe de área y el trabajador a **Tareas**. En celulares, el menú se despliega con el botón **☰ Menú**.

---

## 1. Primeros pasos (Administrador principal)

Orden recomendado para dejar el sistema operativo:

1. **Cambiar la contraseña** del administrador inicial: menú superior (su correo) → *Password*.
2. **Trabajadores → + Nuevo trabajador**: registrar al personal (nombres, apellidos, área, cargo). El código `TRB0001…` se genera solo.
3. **Usuarios → + Nuevo usuario**: crear las cuentas.
   - Los roles **Jefe de área** y **Trabajador** deben vincularse a un trabajador. El área del trabajador vinculado define qué tareas ve el jefe.
   - Los roles administrativos no se vinculan a ningún trabajador.
   - Las cuentas quedan activas de inmediato.
4. **Proyectos → + Nuevo proyecto**.
5. **Tareas → + Nueva tarea**: asignar el proyecto y el responsable (un usuario con rol Trabajador), las fechas de inicio y límite, la prioridad y el avance.

## 2. Administrador principal y Gerente de operaciones

### Dashboard
Indicadores de proyectos (total, en ejecución, finalizados y pendientes, y por área) y de tareas (activas,
vencidas, **en riesgo alto según ML.NET** y sin predicción). El enlace "Ver tareas" abre el listado filtrado por riesgo alto.

### Proyectos
- **Listado** con acciones *Ver / Editar / Eliminar* y número de tareas. Se puede filtrar por área desde el Dashboard.
- **Editar**: carga todos los datos actuales, valida las fechas y que el código no se repita, y muestra la confirmación "Proyecto actualizado correctamente".
- **Eliminar**: solo se permite si el proyecto **no tiene tareas**. Si las tiene, el sistema lo indica.

### Trabajadores
- *Ver* muestra los datos, la cuenta vinculada y las tareas asignadas.
- **Eliminar** no se permite si el trabajador tiene una cuenta de usuario: primero hay que eliminar o desvincular la cuenta.

### Usuarios
- **Editar**: correo, rol, trabajador vinculado y, opcionalmente, una nueva contraseña. Los cambios de rol cierran las sesiones abiertas de ese usuario en menos de un minuto.
- No se puede quitar el rol *Trabajador* a quien tiene tareas activas: primero hay que reasignarlas.
- **Eliminar**: sus tareas quedan "Sin asignar". No se puede eliminar la propia cuenta ni al último Administrador principal.
- **Desbloquear**: tras 5 intentos fallidos de inicio de sesión, la cuenta se bloquea 5 minutos y aparece el estado *Bloqueada*.
- El **Gerente de operaciones** no puede ver, editar, eliminar ni crear Administradores principales.

### Modelo ML.NET
Ver [MANUAL_MLNET.md](MANUAL_MLNET.md).

## 3. Jefe de área

- **Tareas** muestra solo las tareas de proyectos de **su área**. El área es la del trabajador vinculado a su cuenta; si su cuenta no tiene trabajador vinculado, verá un aviso.
- Puede **crear, editar y eliminar** tareas de su área y asignarlas solo a trabajadores de su área.
- La columna **Riesgo de retraso (ML.NET)** ayuda a decidir qué tareas necesitan seguimiento. Al pulsar el indicador se ve el detalle de la predicción.
- Filtros: *Todas · Activas · Riesgo alto · Finalizadas*. El listado se pagina de 25 en 25.

## 4. Trabajador

- **Mis tareas** muestra solo las tareas asignadas a usted.
- Abra una tarea (*Ver*) y use **Actualizar avance** para registrar el porcentaje y el estado.
  - Al marcarla *Finalizada*, el avance pasa a 100 % y se guarda la fecha real de cierre.
  - Una tarea finalizada solo puede reabrirla su jefe de área o un administrador.
- Cada actualización queda en el **Historial de avance**, que también se usa para entrenar el modelo de predicción.
  **Registre el avance con regularidad**: así las predicciones futuras serán más precisas.

## 5. Mi cuenta (todos los roles)

Menú superior (su correo) → *Administrar cuenta*: cambiar la contraseña, el teléfono o activar la autenticación en
dos pasos. Estas páginas de cuenta están en inglés (pendiente de traducción). La eliminación de la propia cuenta está
deshabilitada: la gestiona un administrador.

## 6. Mensajes frecuentes

| Mensaje | Qué significa |
|---|---|
| "Acceso denegado" | Su rol no tiene permiso para esa pantalla o ese registro |
| "Registro no encontrado" | El registro no existe o fue eliminado |
| "Cuenta bloqueada" | Varios intentos fallidos; espere 5 minutos o pida a un administrador que la desbloquee |
| "No se puede eliminar…" | Hay registros relacionados (tareas, cuenta vinculada) que lo impiden |
| Riesgo "No disponible" | Faltan datos para predecir; ver [MANUAL_MLNET.md](MANUAL_MLNET.md#4-cuando-se-muestra-no-disponible) |
