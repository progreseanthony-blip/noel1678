# Reporte diario, cuadrillas y horas: implementación por fases

## Estado actual — 27 de octubre de 2026

Fases 0 a 5 completadas en local, incluida la conciliación de descansos y horas.
El menú de la fase 6 está unificado y los campos históricos se conservaron.
Queda la fase 7 de validación integrada y compilación web final, además de retirar
la excepción temporal de fechas futuras cuando terminen las pruebas del usuario.

## Estado inicial al 18 de octubre de 2026

Rama de trabajo: `feat/role-access-project-teams`. Sin merge ni push.

Se completaron el inventario, la base del backend y la **fase 2 del asistente**.
Las migraciones `20261018000000_daily_execution_foundation.sql` y
`20261018010000_daily_report_section_integration.sql` se probaron en bases aisladas
y se aplicaron juntas, en una transacción, **únicamente a la base local**.
Producción no fue modificada. Crew Reports ya redirige a Reporte diario; la consulta
de horas en Labor Cost y el retiro de Worked Hours siguen pendientes.

Antes de activar se generaron los respaldos
`backups/data_backup_20261018_172523.sql` y
`backups/schema_before_daily_sections_20261018_172529.sql`.
Se compararon cantidades y huellas de integridad antes/después: los 38 reportes,
189 jornadas, 179 registros de maquinaria y tres períodos de nómina conservaron
todos sus valores anteriores. No se crearon equipos, usuarios o registros de
prueba en la base de trabajo.

Inventario local, consultado sin modificar datos: 38 reportes diarios, ningún
`crew_daily_report`, ningún registro laboral enlazado mediante `crew_report_id`
y tres períodos de nómina calculados. Este inventario no permite asumir que
producción tenga las mismas condiciones.

## Reglas acordadas

- Un reporte por proyecto/fecha. Las cuadrillas aportan secciones dentro de él.
- Pertenencia habitual y cuadrilla de ejecución son datos distintos. Un préstamo
  temporal no modifica `crew_members` ni la planificación del trabajador.
- El Foreman solicita préstamos de su cuadrilla; un Supervisor asignado o Admin
  los autoriza. Se conserva solicitante, autorizador, motivo e intervalo.
- Se admite A → B → A, también trabajando en el mismo servicio. Los intervalos
  son del mismo día, con fin excluyente: terminar a las 10:00 permite comenzar
  otro tramo a las 10:00. Los turnos que cruzan medianoche quedan pendientes.
- La maquinaria sigue planificada por servicio. La ejecución identifica la
  unidad física de Recepción, el operador, la cuadrilla y el intervalo.
- El horómetro mide uso; las horas de inicio/fin permiten comprobar conflictos.
- Labor Cost será la consulta de horas para Supervisor/Foreman sin tarifas ni
  importes. Las restricciones deben aplicarse también a las respuestas de la API.
- Supervisor continúa sin acceso a crear o modificar estimaciones.

## Fase 0 — Inventario y compatibilidad: completada

Se identificaron los flujos existentes de Daily Report, Reassign, Recepción,
Resource Planning y Labor Cost. El guardado anterior elimina/reinserta filas por
tipo de recurso; no puede utilizarse para editar secciones concurrentes.

Los reportes existentes conservan sus identificadores, valores y estados. No se
les asignó automáticamente una cuadrilla basándose en el equipo actual.

## Fase 1 — Base de ejecución y permisos: backend completado

La nueva migración agrega:

- `daily_report_sections`: una sección por reporte/cuadrilla, revisión, notas,
  autor, último editor, revisor y estados borrador/enviado/devuelto/aprobado.
- `daily_worker_transfers`: préstamos por trabajador e intervalo con autorización
  y cancelación trazable. Un préstamo con ejecución registrada no puede cancelarse.
- Metadatos en los registros **existentes** de mano de obra, maquinaria y
  materiales. No se crea otra tabla para capturar horas o consumos.
- Cuadrilla habitual como instantánea y cuadrilla de ejecución en cada tramo
  laboral; referencia al préstamo cuando corresponde.
- Identidad de inspección/unidad física y horas de inicio/fin en maquinaria.

Los RPC permiten abrir, consultar, guardar, enviar y revisar secciones; solicitar,
autorizar o cancelar préstamos. Guardar recursos y notas es una sola transacción:
un error conserva todas las filas y la revisión anterior. La revisión optimista
impide sobrescribir una versión que cambió desde otra sesión. La sección conserva
IDs de filas existentes y no acepta IDs de otra sección.

Los bloqueos del reporte serializan sus escrituras. Los bloqueos por trabajador,
operador y unidad física impiden validar simultáneamente usos incompatibles.
Solo el guardado autorizado puede modificar filas de una sección; el borrado
global del asistente anterior queda bloqueado cuando hay secciones canónicas.
La fase 2 conecta el asistente y bloquea la mezcla con registros anteriores.
La conversión de esos históricos queda reservada a la fase 6.

La consulta operativa usa listas explícitas de campos. No devuelve tarifas,
salarios, costos de recursos, recargos de operador ni costos de reposición.
Un Foreman consulta solamente su sección y los trabajadores habituales o prestados
autorizados que necesita. Supervisor/Admin pueden revisar sus secciones permitidas.

Se comprueban jornadas sin superposición, descansos válidos, préstamo autorizado,
planificación en el proyecto, disponibilidad de la unidad física, horómetros,
operador presente en la cuadrilla y ausencia de usos simultáneos. Se permite usar
la misma unidad consecutivamente entre cuadrillas. Si un registro antiguo no
identifica unidad/intervalo, no se presume que esté disponible para otro uso.

La aprobación de una sección no copia sus registros: ya pertenecen al reporte
diario. El autor y el último editor no pueden aprobarla. El envío del consolidado
exige la revisión previa de sus secciones de cuadrilla. Reportes enviados/aprobados
y proyectos cerrados permanecen bloqueados, incluso para nuevas inserciones.

**Límites del cálculo de horas:** los campos
diarios regular/extra siguen siendo valores de presentación por tramo; no deben
usarse como nueva clasificación de nómina. La clasificación semanal y los
descansos entre tramos deben unificarse en la fase 5, conservando las reglas
comerciales existentes. No se migraron ni eliminaron aportes antiguos.

## Fase 2 — Integrar el asistente existente: completada en local

El asistente de Daily Report permite elegir fecha y vista consolidada/cuadrilla.
Reutiliza los pasos General, Labor, Machinery, Materials y Review. El Foreman entra
desde Reportes diarios, ve sus cuadrillas autorizadas y edita solo la sección
seleccionada. El Supervisor/Admin gestiona el encabezado, revisa las secciones y
envía el consolidado. El autor, último editor o remitente correspondiente no puede
aprobar su propio trabajo. Se guarda el remitente real del consolidado, aunque
el encabezado lo haya creado inicialmente un Foreman.

Guardar una sección incluye sus jornadas, maquinaria, materiales, notas, firma
y fotos en una transacción. La firma y evidencias de la sección se restauran al
abrirla. Un error de validación o revisión conserva el borrador en pantalla.
Durante subidas/guardados se bloquea el cambio de ámbito. Cambiar fecha/cuadrilla
o salir avisa si hay cambios pendientes. Las consultas restringidas no hacen
peticiones adicionales a catálogos completos ni a datos de estimaciones/tarifas.

Los reportes con recursos capturados por el método anterior permanecen en su
editor consolidado. El servidor impide abrir secciones junto a esas filas, para
no bloquearlas ni atribuirlas a equipos actuales. Los reportes nuevos con equipos
configurados registran sus recursos por cuadrilla; el consolidado los consulta
sin borrarlos/reinsertarlos. El encabezado se crea/reutiliza con un bloqueo común
a los Foreman para conservar un único reporte por proyecto/fecha.

Se agregaron los campos mínimos de unidad física e intervalo al formulario
existente de Machinery para poder guardar sus registros canónicos; la fase 4
completará la reasignación por intervalos y su vista compacta. El paso Labor
permite especificar el descanso de cada tramo. Los indicadores históricos globales
de producción/consumo no se consultan desde la sección restringida; continúan en
el consolidado y en los módulos de seguimiento.

### Prueba funcional en localhost

1. Actualizar/reiniciar el proceso Flutter que sirve localhost para cargar el
   frontend nuevo. No basta con tener una compilación anterior abierta.
2. Como Admin, activar/asignar un Foreman y un Supervisor desde los flujos
   existentes; organizar integrantes en Resource Planning → Labor y cuadrillas.
   Las vigencias del equipo y las asignaciones laborales deben cubrir la fecha.
3. En Reporte diario, elegir una fecha con recursos planificados que **no tenga
   ya recursos capturados por el método anterior**. Seleccionar una cuadrilla.
4. Registrar entradas/salidas y descansos, guardar, salir y volver a abrir. Si se
   registra maquinaria, elegir una unidad recibida, un operador cuya asistencia
   cubra el intervalo y horómetros compatibles. Registrar materiales si corresponde.
5. Agregar notas/firma/evidencias y enviar la sección. Como Supervisor, revisarla,
   devolverla con motivo o aprobarla. Enviar el consolidado una vez aprobadas todas
   las secciones; aprobarlo con otra cuenta autorizada independiente.
6. Confirmar que los reportes anteriores conservan sus filas y que un Foreman no
   puede abrir cuadrillas ajenas, editar el encabezado o aprobar secciones.

Los préstamos A → B → A aún se prueban solo mediante SQL: la ampliación de Reassign
corresponde a la fase 3. Worked Hours todavía corresponde al flujo anterior y no
es una validación de las horas nuevas por sección; su integración está en fase 5.

## Fase 3 — Integrar Reassign: completada en local (23 de octubre)

Reassign permite escoger cuadrilla, servicio/posición, intervalo y motivo.
Exige cerrar el tramo de origen y guarda ese borrador antes de solicitar un
préstamo. El Foreman solicita; Supervisor/Admin revisan o autorizan desde el
reporte. Cada tramo conserva su ID, también al regresar al mismo servicio.
El destino incorpora al trabajador mediante una referencia temporal y carga el
intervalo y transfer_id aprobados, sin modificar las asignaciones planificadas.
El backend impide solapamientos y no autoriza mientras haya un tramo abierto
en conflicto. Se admite más de un préstamo separado para una misma persona.

La consulta operativa presenta destinos, servicios y solicitudes de forma
autorizada, sin precios. Se valida el servicio planificado de la cuadrilla de
destino; las cuadrillas heredadas sin períodos mantienen compatibilidad. Los
reintentos de una misma solicitud pendiente conservan su identidad. Cancelar
requiere motivo y el backend bloquea la cancelación si ya existe ejecución.

Migración local: `20261023000000_daily_transfer_context.sql`. Respaldos:
`backups/data_backup_20261023_085356.sql` y
`backups/schema_before_daily_transfers_20261023_085358.sql`. Recuentos y hashes
de todas las tablas públicas coinciden antes/después. Sin datos de prueba en
la base de trabajo; los fixtures SQL se ejecutaron en una base aislada y ROLLBACK.

Validación dirigida: 20 pruebas Flutter (7 de tramos y préstamos, 9 de secciones
y 4 de descanso) y dos baterías SQL (préstamos/ejecución y aprobación de
secciones). Generación core/data/main_app completada. La interfaz sigue en
inglés y no cambia los umbrales de nómina. Sin merge ni push.

### 23 de octubre — Normal/Table en Labor por cuadrilla

Se recupera el selector Normal/Table en la captura por cuadrilla. La tabla muestra
una fila por tramo con identidad estable, incluso cuando una persona regresa al
mismo servicio o realiza varios servicios. La selección masiva usa esas filas,
no el primer registro del trabajador, y respeta los filtros visibles. Cada fila
permite ajustar horas, Reassign y Remove; los préstamos pendientes de documentar
mantienen la opción Add authorized segment. Se aplica también a pantallas pequeñas.

Ambas vistas comparten registros y cálculo de horas/descansos. Cambiar de vista no
guarda ni duplica jornadas. Marcar ausencia no elimina silenciosamente un tramo
ya documentado. Se mantienen los bloqueos de lectura y las validaciones del backend.

Validación dirigida: 26 pruebas Flutter aprobadas (5 nuevas de tabla, 8 de tramos
y préstamos, 4 de descanso y 9 de secciones). Generación core/data/main_app
completada. Sin cambios de esquema o datos, merge ni push.

## Fase 4 — Integrar la operación de maquinaria: completada en local

Machinery permite agregar varios intervalos para la misma unidad física, sin
limitar el número de tramos a la cantidad de máquinas planificadas. Cada tramo
conserva operador, unidad recibida, inicio/fin, horómetros, producción, combustible
y fotos propios. Agregar otro tramo no copia producción ni horas del anterior.
Si solo hay una unidad recibida, queda preseleccionada.

En la captura por cuadrilla los operadores proceden de la asistencia registrada,
incluidos los préstamos autorizados y las reasignaciones. La disponibilidad se
evalúa por intervalo: los tramos consecutivos están permitidos, los cruces no.
Se exige que un tramo de asistencia cubra toda la operación; una asistencia sin
checkout o con un hueco entre tramos no sirve como cobertura. Se conserva visible
la selección actual cuando se modifica el horario para poder corregirla.

La pantalla indica los datos incompletos, los conflictos locales y el exceso de
horómetro respecto del intervalo; el guardado revisa lo mismo antes de enviar.
La base sigue siendo la autoridad para disponibilidad en otras cuadrillas,
reportes y sesiones concurrentes, sin exponer esos registros al Foreman.
Los registros heredados sin horario no se consideran automáticamente disponibles.
Los recargos de tarifa del formulario heredado requieren capacidad explícita de
Admin; la API de secciones mantiene su exclusión de campos monetarios.

No se cambió el esquema ni los datos de trabajo. Se conservan las barras
acumuladas y la excepción temporal para probar proyectos futuros.

Validación: 6 pruebas nuevas de intervalos aprobadas, además de 13 pruebas de
gráficos y 9 de secciones del reporte. La integración SQL canónica pasó en base
aislada con ROLLBACK, incluyendo usos consecutivos entre cuadrillas, conflictos
de unidad/operador, asistencia y exclusión de tarifas. Generación completada en
core/data/main_app; análisis sin errores, con avisos previos en los widgets.
Sin merge ni push.

## Fase 5 — Horas en Labor Cost: consulta habilitada en local

Foreman y Supervisor acceden desde Labor Cost al proyecto y consultan por rango,
cuadrilla autorizada o fechas de un período existente. Las funciones de lectura
devuelven únicamente campos operativos: no tarifas, salarios, recargos ni importes.
El Foreman ve la cuadrilla de ejecución en las fechas autorizadas, incluidos los
préstamos; Supervisor/Admin pueden consultar los registros permitidos del proyecto.

El servidor clasifica la semana ISO completa por trabajador, incluidos otros
proyectos y cuadrillas, antes de filtrar lo que se devuelve. El límite sigue en
40 horas semanales. Se distingue año ISO y semana; también se corrige esa clave
en el calculador financiero anterior. Las secciones aprobadas cuentan como
validadas; los registros heredados exigen reporte aprobado. Los borradores y
devueltos se muestran separados y no entran en totales validados ni PDFs.

La tabla, los totales generales y las plantillas existentes de PDF individual/firma
utilizan la misma clasificación operativa. El PDF individual se abre al hacer clic
en la fila del trabajador, mediante la vista de impresión que ya usaba Labor Cost.
Se eliminó el resumen duplicado por trabajador, sin agregar controles a la tabla.
La lectura conserva los descansos y horas netas
guardados por tramo: no altera jornadas anteriores. La conciliación de descuentos
automáticos y del informe financiero se completó el 26 de octubre, como se detalla
abajo; no se recalcularon históricos por esta consulta.

Se corrigió además el recálculo implícito al abrir la pantalla administrativa de
un período: ahora usa una vista previa sin escrituras. El cálculo explícito de
un período cerrado se rechaza. Los totales financieros guardados se conservan;
la vista operativa muestra las horas validadas actuales, no una nómina congelada.

Migración `20261023010000_labor_hours_read_model.sql` aplicada solo en local.
Respaldos: `backups/data_backup_20261023_135533.sql` y
`backups/schema_before_labor_hours_20261023_135536.sql`. Recuentos y hashes de
todas las tablas públicas idénticos antes/después. La excepción temporal para
proyectos futuros no se modificó.

Validación: 19 pruebas Flutter aprobadas (6 de consulta/interfaz/PDF, 5 de rutas y
8 de nómina/períodos cerrados). La batería SQL `labor_hours.sql` pasó en base
aislada con ROLLBACK, incluidos permisos, préstamos/retorno, semana entre proyectos,
borradores, campos financieros excluidos y período cerrado intacto. Generación
core/data/main_app completada; análisis sin errores, solo avisos de estilo.

### 26 de octubre — Descanso diario único y conciliación financiera

Los nuevos tramos automáticos utilizan `break_mode=auto_daily`. La misma regla se
aplica en Normal, Table, Reassign y en el guardado del servidor: 30 minutos al
alcanzar seis horas de trabajo en el día, distribuidos una sola vez entre tramos.
Se acredita el descanso ya registrado en otras cuadrillas/proyectos. El contexto
solo devuelve acumulados de los trabajadores autorizados, sin registros ajenos
ni importes. El servidor vuelve a calcular con bloqueo por trabajador/fecha.

Los registros anteriores reciben únicamente el marcador `recorded` mediante el
valor predeterminado de la columna: conservan horas, descuentos y demás campos.
Los descuentos manuales/registrados no se reinterpretan como automáticos. Una
corrección que invalidaría el descanso de otra sección enviada/aprobada se rechaza;
no se modifica esa sección silenciosamente. Los borradores pueden requerir guardar
el otro tramo antes de enviar si una eliminación deja el descanso sin asignación.

El cálculo financiero, el detalle individual y el PDF de firma consumen la misma
clasificación semanal del servidor que Labor Cost operativo. La semana completa
se clasifica antes de filtrar proyecto, cuadrilla o rango. No se utilizan los
indicadores diarios de horas extra para determinar el sobretiempo pagable.
Se conserva la tarifa base y el factor de sobretiempo existentes; se corrigió la
acumulación del recargo de operador para que coincidan fila y total general.

La pantalla financiera y sus exportaciones suman las mismas filas de vista previa.
Si difieren de los totales guardados, se muestra la diferencia como vista previa,
con los totales originales identificados y el PDF rotulado como tal. Leer no
actualiza períodos. Un trigger impide actualizar/borrar un período cerrado,
incluido el caso de cierre concurrente mientras otro usuario calcula.

Migración `20261026000000_reconcile_daily_breaks_and_payroll.sql`, aplicada solo en
local. Respaldos: `backups/data_backup_20261026_194656.sql` y
`backups/schema_before_reconciliation_20261026_194658.sql`. Cantidades y hashes de
todos los campos históricos públicos idénticos antes/después; la comparación
excluye únicamente el nuevo marcador `break_mode`. Los períodos y la excepción
temporal de acceso futuro permanecen intactos.

Validación: 51 pruebas Flutter aprobadas entre descansos, préstamos, Normal/Table,
secciones, PDFs y nómina. Las baterías SQL `daily_break_reconciliation.sql` y
`labor_hours.sql` pasaron en base aislada con ROLLBACK, incluidos A→B→A, payload
automático incorrecto, otra cuadrilla ya aprobada, histórico explícito, semana
entre proyectos, permisos y cálculo/cierre de períodos. Generación core/data/app
completada y análisis sin errores (avisos de estilo/deprecación). Consulta local
real verificada: 4 tramos, 38 horas netas/regulares y cero horas extra en el rango
de prueba. Sin merge ni push.

## Fase 6 — Navegación unificada; revisión histórica final en fase 7

Worked Hours se retira de los menús de todos los roles. Su enlace anterior
redirige a Labor Cost. Crew Reports sigue redirigiendo a Daily Report.
Los accesos directos a páginas financieras continúan bloqueados para Foreman y
Supervisor; las autorizaciones se comprueban de nuevo en la API de horas.

No se migran ni duplican aportes: la consulta lee cada ID existente una sola vez.
Utiliza la cuadrilla de sección/ejecución o la referencia heredada comprobable;
los históricos sin cuadrilla mantienen esa condición y no se atribuyen al Foreman.
La compatibilidad histórica adicional y la conciliación final quedan en fase 7.

## Fase 7 — Validación integrada y activación local: pendiente

### Observación de prueba — envío y revisión de cuadrilla (23 de octubre)

En el reporte futuro del 2 de noviembre se verificó: sección del Foreman en
`submitted`, reporte consolidado todavía en `draft`. El envío de una sección no
envía automáticamente el consolidado. La aprobación/devolución de cuadrillas
está en General, dentro del asistente; la aprobación final del consolidado es
otra acción. Se agregó en la lista de reportes el contador/enlace de cuadrillas
pendientes de revisión para Admin/Supervisor. No cambia estados ni excepciona
la revisión independiente del autor/último editor.

Verificar UI y permisos de los tres roles, jornadas divididas, revisión, PDFs,
períodos y reportes históricos. Ejecutar generación, análisis y compilación web.
La activación local de las fases 1/2 ya se hizo con respaldo de datos/esquema e
integridad comprobada. En futuras migraciones, ejecutar `scripts/db_backup.ps1` y
respaldar también el esquema. Aplicar únicamente DDL; no sincronizar datos entre
entornos. Producción, merge y push requieren la instrucción posterior del usuario.

## Pruebas de las fases 1/2

- Instalación de la migración sobre una copia del esquema anterior sin datos reales.
- `supabase/tests/daily_execution.sql`: pruebas de guardado atómico, revisión
  optimista, permisos, campos financieros, préstamos, A → B → A, maquinaria,
  revisión independiente y bloqueo de reportes/proyectos. Finaliza con `ROLLBACK`.
- `supabase/tests/project_access.sql`: regresión de los permisos y planificación
  existentes. Finaliza con `ROLLBACK`.
- `supabase/tests/daily_section_integration.sql`: navegación sin precios,
  conservación de históricos, firma/evidencias atómicas, encabezado único y
  aprobación independiente del remitente. Finaliza con `ROLLBACK`.
- `flutter test test/access_context_test.dart test/daily_report_sections_test.dart`:
  13 pruebas aprobadas (rutas, aislamiento de secciones, borradores ante errores,
  cambio de ámbito, fecha/estado, envío, reintento y subida de evidencias).
- Generación de core/data/main_app y compilación web release correctas. El análisis
  no detectó errores; persisten avisos de estilo/deprecaciones en archivos existentes.

Las tres baterías SQL pasaron en la base aislada del contenedor local. Ninguna
prueba utiliza datos de producción. No se ejecutaron fixtures de pruebas en la
base local de trabajo. No se cambiaron contraseñas ni credenciales.


## Ajuste de planificación — Labor y cuadrillas (18 de octubre)

Implementado y activado únicamente en local mediante
`20261018020000_unified_labor_crew_planning.sql`. Las fases 3 a 7 de ejecución
siguen pendientes; este ajuste organiza la planificación que las alimenta.

- Una ficha **Labor y cuadrillas**, con vistas Personal y Cuadrillas y filtro por
  identidad de servicio. No se fusionan servicios distintos por compartir nombre
  u oficio; los servicios exclusivos de CO también conservan su identidad.
- Personal permite buscar y seleccionar varios trabajadores de distintos oficios
  dentro del mismo servicio. Cada asignación conserva sus fechas de origen;
  la participación en cuadrilla puede ser un subperíodo de ellas.
- Agregar personal permite selección múltiple por oficio y toma inicialmente las
  fechas de las plazas planificadas. Se puede planificar sin cuadrilla o crear/vincular
  una cuadrilla y su Foreman en la misma transacción. Se comprueban plazas y
  disponibilidad; un error revierte todo el lote y mantiene abierto el formulario.
- Las autorizaciones de Supervisor/Foreman están en **Responsables del proyecto**,
  en la cabecera. Solo el Admin las modifica. Un Supervisor asignado organiza
  personal y líderes ya autorizados desde Labor.
- Las cuadrillas tienen servicio y vigencia; las membresías enlazan la asignación
  laboral concreta. La vista Cuadrillas muestra integrantes y líderes por período,
  permite definir fin y asignar un nuevo líder sin borrar la historia.
- La ampliación del período de una cuadrilla para el mismo servicio comprueba
  solapamientos y autorización del líder. Otro servicio requiere una vigencia que
  no se superponga. Las fechas son inclusivas.
- El calendario por oficio sigue disponible dentro de la misma ficha. Las fechas
  de cada persona se editan en Personal. El servidor impide recortar fechas ya
  utilizadas por membresías/reportes o cambiar el servicio/oficio de una plaza
  enlazada con historial de cuadrilla.
- Las cuadrillas anteriores sin servicio comprobado muestran su historial como
  **Servicio pendiente**, incluso si después se planifican períodos nuevos.
  No se atribuyeron servicios o integrantes históricos automáticamente.
- El reporte diario toma como predeterminada la asignación laboral enlazada a la
  pertenencia vigente. Conserva el flujo anterior para membresías sin enlace y
  las transferencias aprobadas. Esto no implementa todavía la interfaz de Reassign.
- Maquinaria conserva su planificación por servicio. La operación por unidad e
  intervalos y las horas en Labor Cost continúan en sus fases pendientes.

Validación: 18 pruebas Flutter aprobadas; las cuatro baterías SQL
(`unified_labor_crew_planning.sql`, `project_access.sql`, `daily_execution.sql`,
`daily_section_integration.sql`) aprobadas en una base aislada. También se probó
que un reporte impide recortar las fechas históricas del integrante o su Foreman,
y que los valores predeterminados usan la asignación de origen exacta.
Generación core/data/main_app y compilación web release correctas. El análisis
no detectó errores de compilación; permanecen avisos de estilo y deprecaciones.

Respaldos antes de activar:
`backups/data_backup_20261018_184948.sql` y
`backups/schema_before_unified_labor_20261018_184951.sql`.
Se compararon cantidades y huellas de todas las tablas públicas anteriores a la
migración: ninguna cambió. Se conservaron, entre otros, 38 reportes, 189 registros
laborales, 35 asignaciones planificadas y las dos cuadrillas existentes. No se
cargaron fixtures en la base local de trabajo ni se modificaron contraseñas.

### Prueba manual en localhost

1. Reiniciar el frontend local y abrir Resource Planning de un proyecto activo.
2. Como Admin, revisar **Responsables del proyecto** y autorizar al Foreman con
   una vigencia que cubra las fechas que se probarán.
3. Abrir **Labor y cuadrillas → Personal**, elegir el servicio y seleccionar
   varios trabajadores. Usar **Asignar cuadrilla**; verificar las fechas
   individuales heredadas, definir cuadrilla/Foreman y guardar.
4. Cambiar a **Cuadrillas** y comprobar el servicio, las vigencias, integrantes
   y líder. Volver a Personal y comprobar que ambas vistas reflejan lo guardado.
5. Probar **Agregar personal** con varias personas de un oficio y sus fechas.
   Un conflicto de disponibilidad debe mantener el formulario y evitar guardados
   parciales. Las plazas/calendario permanecen en el desplegable por oficio.
6. Abrir un reporte diario compatible para una fecha cubierta y comprobar el
   personal y servicio predeterminados. Las pruebas de préstamos temporales
   desde Reassign y del resumen de horas en Labor Cost quedan para fases posteriores.

Rama `feat/role-access-project-teams`, sin merge ni push. Producción sin cambios.


## Refinamiento del modal y fechas de referencia — 18 de octubre

El modal **Asignar personal y cuadrilla** usa ahora `ResponsiveDialogShell`, el
mismo contenedor compartido por la planificación de Labor, maquinaria e
instrumentos: cabecera y pie fijos, cuerpo con desplazamiento, presentación móvil
adaptada al teclado. Los campos tienen etiquetas externas, separación entre
bloques, selectores de fecha y períodos individuales claramente identificados.

Se revisaron los diálogos existentes de calendario/asignación y
`getWorkingDayContribution`. La propuesta de fechas sigue estas reglas:

1. Un trabajador ya planificado conserva exactamente su período individual.
   La pertenencia a cuadrilla puede ocupar un subperíodo de esa planificación.
2. Para personal nuevo, primero se usan las fechas guardadas del oficio/plaza.
   Si faltan, se propone el período estimado del servicio. Se consulta el vínculo
   directo, el servicio del proyecto o el detalle de Labor de la estimación.
3. Si falta el fin y existe duración estimada, se calcula con el calendario
   compartido: sábado 0.5, domingo 0 y descuentos por días no laborables/parciales.
   Cuando se desplaza el inicio, la duración permite proponer un nuevo fin.
4. El período explícito de la estimación se muestra como referencia y se conserva
   como tal. No constituye un límite obligatorio del servicio ni reemplaza las
   fechas de trabajadores existentes. Aplicar un período común requiere la acción
   explícita **Aplicar período a seleccionados**, seguida de las validaciones.
5. Los servicios exclusivos de CO sin estimación consultan únicamente el calendario
   de sus propias tareas, identificado como calendario del servicio. Si no hay
   fuente de fechas, el formulario lo indica; no toma fechas de otros recursos.
6. Ante varias estimaciones del mismo servicio, la referencia se elige de manera
   determinista por actualización, creación e ID. Las fechas se normalizan como
   fechas de calendario. Los catálogos distintos de roles de estimación y oficio
   del trabajador no se mezclan por identificador.

La migración `20261018030000_labor_planning_service_calendar.sql` agrega una
consulta autorizada de calendario, sin campos financieros ni escrituras en datos
de planificación. Se aplicó únicamente en local tras validar fixtures con
`ROLLBACK` en `supabase/tests/labor_planning_service_calendar.sql`.

Verificación: siete pruebas de fechas, ocho del formulario (incluidas etiquetas
externas y móvil con teclado) y las 13 regresiones de acceso/reporte diario.
Generación core/data/main_app y compilación web release correctas. El análisis
no encontró errores de compilación; quedan avisos de estilo en el componente.
La consulta se comprobó también, sin escribir datos, en los nueve proyectos con
Labor de la cuenta local habitual.

Respaldos: `backups/data_backup_20261018_201736.sql` y
`backups/schema_before_labor_calendar_20261018_201738.sql`. Cantidades y huellas de
todas las tablas públicas iguales antes/después. Producción sin cambios, sin
merge ni push. Las fases pendientes de ejecución se mantienen pendientes.

Para comprobarlo: reiniciar el frontend local, abrir **Labor y cuadrillas → Agregar
personal**, revisar el período de referencia, seleccionar un oficio sin fechas
propias y confirmar la propuesta del servicio. En trabajadores ya planificados,
comprobar que sus fechas individuales siguen siendo las mismas.


## Confirmación por oficio — 19 de octubre de 2026

Se añadió una selección en dos pasos dentro de **Asignar personal y cuadrilla**:
marcar personas y pulsar **Aceptar selección para este oficio**, junto al contador.
La aceptación muestra cada trabajador en **Personal confirmado**, agrupado por
oficio, con etiquetas que permiten quitarlo. El selector de oficio muestra también
el número confirmado. Cambiar de oficio conserva tanto las selecciones confirmadas
como las marcas aún pendientes y el período propuesto para cada oficio.

Aceptar confirma únicamente el formulario: no escribe en la base. El botón final
**Guardar planificación y equipo** mantiene el guardado atómico existente para
todos los oficios seleccionados. Si quedan selecciones o cambios de período por
aceptar, el guardado los señala y conserva el borrador. Se puede corregir, quitar
personal o añadir otro oficio antes del guardado definitivo.

Las fechas propuestas se muestran ahora junto al oficio, antes de seleccionar
personal. Al escoger un inicio, el fin se propone usando la duración del servicio
y el calendario laboral compartido (incluido sábado parcial y días no laborables).
Aceptar incorpora ese período al oficio; una modificación posterior del período
común se aplica al volver a aceptarlo. Los períodos individuales pueden ajustarse
antes de guardar. Al editar el inicio individual de personal nuevo, el cálculo usa
el oficio de esa fila, incluso si el selector está en otro oficio. Las asignaciones
que ya existían conservan sus fechas de origen y las restricciones de participación.

Validación: 31 pruebas Flutter aprobadas, incluyendo aceptación de varios oficios,
resumen persistente, eliminación de etiquetas, conservación de marcas pendientes,
prohibición de guardado sin aceptación y selección de fecha inicial con propuesta
automática del fin. Se conserva la regresión de acceso y reporte diario. No hay
cambios de esquema ni de datos por este ajuste. Las fases pendientes se mantienen;
sin merge, sin push y sin cambios en producción.

Generación core/data/main_app y compilación web release del ajuste de confirmación
completadas correctamente. No se detectaron errores de Dart en el análisis dirigido.


## Disponibilidad visible por oficio — 19 de octubre de 2026

Se verificó el rechazo reportado en CLEARING: la única plaza de CONSTRUCTION
FORMAN ya tenía una asignación del 25 al 29 de octubre. No se reemplazó al
trabajador ni se amplió la cantidad de plazas para resolver esa prueba.

El selector de oficios muestra ahora **ocupadas/planificadas** (por ejemplo,
**1/2** o **1/1**), calculado con las fechas propuestas de cada oficio. Debajo del
período se muestran el cupo disponible y los trabajadores ya asignados con sus
fechas. Las plazas se cuentan por las filas de planificación existentes, sin
usar el contador de recepción ni la cantidad original de la cotización como cupo
adicional: la aplicación ya desglosa estas cantidades en plazas por oficio.

Si el cupo está cubierto, las casillas no permiten agregar personas. Con una
plaza ocupada de dos, únicamente puede marcarse una persona adicional; al
quitarla se puede elegir otra. La aceptación vuelve a comprobar el lote y
conserva el personal previamente confirmado si encuentra un conflicto. Antes del
guardado se repite la comprobación con el mismo criterio de asignación de plazas
del servidor, incluidos los períodos inclusivos y los servicios distintos.

La consulta local es una instantánea: el servidor mantiene la validación atómica
ante cambios concurrentes y disponibilidad de otras obras. Los rechazos conocidos
se muestran en español sin el envoltorio técnico de PostgREST; el error queda
junto al botón de guardar, con espacio limitado y desplazamiento en mensajes
largos. Para utilizar a un trabajador ya planificado, debe seleccionarse su
asignación existente en Personal y organizar su cuadrilla, en lugar de agregarlo
otra vez como personal nuevo.

Validación: 39 pruebas Flutter aprobadas, incluyendo seis pruebas de disponibilidad
(servicio, cupos, intervalos inclusivos, reutilización temporal de plazas y mensajes)
y las verificaciones visuales de 1/1 completo y cupo restante de 1/2. Generación
core/data/main_app correcta; análisis dirigido sin errores. No se modificó esquema,
no se añadieron datos de pruebas a la base de trabajo y las asignaciones existentes
se conservaron. Las fases pendientes no cambian; sin merge ni push.

Compilación web release del ajuste de disponibilidad completada correctamente.


## Contador registrado y lista de ocupados recuperada de main — 19 de octubre

Se revisó directamente en `main`, mediante `git show` y sin cambiar de rama,
`worker_assignment_dialog.dart`. El flujo anterior conservaba al trabajador en
la lista, bloqueaba su casilla y mostraba el proyecto que ocupaba sus fechas.
Ese comportamiento se recuperó en el modal unificado, manteniendo la aceptación
por oficio, las cuadrillas y el guardado conjunto.

- El selector muestra ahora **plazas con asignaciones registradas/planificadas**
  sin filtrar por las fechas propuestas. Así una asignación en octubre no se
  presenta como cero solo porque la referencia estimada sigue en septiembre.
  Una plaza reutilizada en varios períodos se cuenta una vez en ese indicador.
- El bloque de disponibilidad distingue el contador registrado de la **ocupación
  del período elegido**. Muestra todas las asignaciones del oficio con fechas e
  indica si coinciden o quedan fuera de ese intervalo. El bloqueo por cupos sigue
  dependiendo del período para permitir reutilización temporal de plazas.
- La lista conserva visibles a los trabajadores ocupados, con la casilla
  deshabilitada y una etiqueta **Ocupado en proyecto · oficio · inicio → fin**.
  La disponibilidad considera tanto el mismo proyecto como otras obras.
- La consulta se renueva al cambiar oficio, inicio o fin. Se ignoran respuestas
  antiguas; mientras no esté verificada la disponibilidad, no se puede seleccionar
  personal. Si falla la consulta, se ofrece reintento. Un trabajador elegido para
  otro oficio del mismo borrador también queda bloqueado si las fechas coinciden.
- Antes del guardado se vuelve a comprobar cada período individual. Un conflicto
  surgido después de aceptar conserva los trabajadores confirmados en el formulario
  y explica qué persona requiere revisión. El servidor mantiene además su control
  atómico de conflictos y cupos.

La migración `20261019000000_labor_worker_availability.sql` incorpora una consulta
para Admin o Supervisor autorizado en un proyecto activo. Devuelve solo el contexto
necesario de la reserva: trabajador, nombre del proyecto, oficio y fechas. Conocer
el nombre de otra obra no concede acceso a sus pantallas, registros o costos.
No se modificaron las políticas de acceso a proyectos ajenos ni se exponen tarifas.

Validación: 45 pruebas Flutter aprobadas y
`supabase/tests/labor_worker_availability.sql` aprobada con fixtures y `ROLLBACK`
en una base aislada. Se incluyen contador con referencia en otro mes, trabajador
bloqueado con proyecto, habilitación en fechas libres, error/reintento, comprobación
antes de guardar y permisos sobre proyectos ajenos. Generación core/data/main_app
correcta; análisis sin errores de compilación (se conservan avisos de estilo).

Respaldo previo local: `backups/data_backup_20261019_092646.sql` y
`backups/schema_before_worker_availability_20261019_092648.sql`.
Las fases pendientes de ejecución se mantienen pendientes. Sin merge ni push.

Compilación web release correcta. Migración de disponibilidad activada únicamente
en local tras el respaldo indicado. Se compararon cantidades y huellas de todas
las tablas públicas antes/después: ninguna cambió. Consulta real verificada con
la cuenta local habitual en nueve proyectos activos, sin escribir datos.
Producción sin cambios; no se hizo merge ni push.

### Homologación visual del filtro de Labor y cuadrillas

El selector superior de servicios se comparte ahora con Machinery, Materials e
Instruments. Labor elimina su selector inferior y conserva el filtro al cambiar
de ficha. All Services muestra el servicio de cada trabajador y de las cuadrillas;
Agregar personal solicita el servicio si hay varios, y Asignar cuadrilla exige
seleccionar personal de un solo servicio. Cambiar el filtro limpia la selección.
Los calendarios por oficio siguen usando la identidad del servicio y cada uno
conserva su propio controlador de desplazamiento.

Las filas del personal pasan de un máximo de 180 a 72 píxeles, con cabecera de
44 píxeles y menor separación entre columnas. Se mantienen las fechas y el
historial de cuadrilla/Foreman dentro de la celda desplazable.

Validación: 33 pruebas Flutter aprobadas (planificación, disponibilidad y fechas),
incluida la navegación del filtro compartido y la protección contra mezclar
servicios al asignar una cuadrilla. Generación core/data/main_app completada;
análisis de los archivos modificados sin errores, con avisos existentes de estilo,
deprecaciones y variables no utilizadas. Sin cambios de base de datos, merge ni
push. Las fases pendientes se mantienen pendientes.

### Prioridad del oficio en la selección de personal (2026-10-20)

El modal muestra primero los trabajadores cuyo oficio registrado coincide con el
oficio planificado seleccionado y después el resto, ordenados por nombre dentro
de cada grupo. Se compara la identidad del oficio; cuando falta, se usa su nombre.
Ya no se excluye a los trabajadores de otros oficios: pueden cubrir la plaza
planificada sin modificar el oficio de su ficha. Se conservan los bloqueos por
ocupación y selección simultánea, las etiquetas del proyecto ocupado y el límite
de plazas del período. La búsqueda se aplica a ambos grupos.

Validación: 19 pruebas del modal aprobadas, incluida la prioridad por oficio y el
guardado de un trabajador de otro oficio en la plaza seleccionada, conservando
su ficha. Generación core/data/main_app completada. Sin cambios de base de datos,
merge ni push.

### Retiro, corrección y recursos responsables presupuestados (2026-10-20)

Implementado en la rama `feat/role-access-project-teams`, sin merge ni push:

- Personal: menú por asignación con Retirar de la cuadrilla (conserva la reserva
  laboral), Finalizar asignación al servicio (ajusta participaciones vinculadas y
  libera fechas posteriores) y Cancelar asignación por error (sin ejecución ni
  dependencias utilizadas). Se solicita último día inclusivo cuando corresponde
  y motivo. Las participaciones antiguas sin vínculo a una plaza requieren
  revisión en Cuadrillas; no se adivina su correspondencia.
- Cuadrillas: menú del Foreman con Corregir Foreman asignado, que sustituye la
  identidad sin alterar fechas si no hay actividad, y Cambiar Foreman desde una
  fecha, que cierra al anterior el día previo y crea al nuevo en una sola
  transacción. Se conservan autores y fechas usados por reportes, incluidos
  borradores y transferencias. La corrección también sirve para equipos futuros
  de un proyecto activo. Ambas operaciones conservan las otras autorizaciones
  del proyecto y registran motivo, actor y datos anteriores/posteriores.
- Catálogo de oficios: función operativa explícita Otro oficio / Supervisor /
  Foreman, independiente del rol de acceso de la cuenta. La línea de Labor de
  cotización permite ajustar la función y cobertura. Supervisor cubre el proyecto;
  Foreman puede cubrir este servicio o el proyecto. Se presupuestan una o varias
  personas con las cantidades, duración y tarifas existentes. El costo permanece
  una sola vez en el servicio de origen, con una aclaración visible cuando la
  cobertura es del proyecto; no se crea un subtotal adicional ni se redistribuyen
  importes históricos.
- Las cotizaciones nuevas requieren al menos una plaza de Supervisor y una de
  Foreman con cantidad entera, duración y tarifa positivas antes de enviarse o
  aprobarse. Se permite guardar borradores/partial. La validación se repite al
  iniciar un proyecto, antes de crear registros. La cabecera queda provisional
  durante el guardado de sus recursos y el estado final se establece al terminar.
- Las cotizaciones existentes conservan `team_planning_required=false` y sus
  líneas y costos originales. La interfaz indica la necesidad de revisión manual;
  no se interpreta el nombre de un oficio para reclasificar contratos anteriores.
- Las plazas nuevas copian función y cobertura desde su línea presupuestada.
  La asignación verifica una cuenta activa vinculada al trabajador con el rol
  correspondiente. Solo Admin puede añadir la autorización del proyecto al
  guardar la plaza; Supervisor necesita que ya cubra todo el período. Si hay una
  autorización parcial existente se pide revisarla, conservando su historial.
- Resource Planning muestra contadores de plazas de Supervisor/Foreman y
  permite a Admin abrir Vincular usuario para editar una cuenta registrada,
  vincular su ficha de trabajador y revisar rol/estado. La persona debe
  registrarse primero si aún no tiene cuenta; no se crean credenciales ni se
  envían mensajes automáticamente. Users también dispone del vínculo de ficha.
  Las plazas que requieren una cuenta muestran Usuario pendiente y bloquean la
  selección hasta cumplir los requisitos. La restricción se repite en el servidor.
- La referencia de una plaza con cobertura de proyecto abarca las referencias
  de sus servicios laborales, usando el calendario compartido. Las fechas
  individuales guardadas conservan precedencia. Sin referencias suficientes se
  mantiene la edición explícita. Plazas y calendarios se agrupan también por
  función y cobertura, además de servicio y oficio.

Migraciones locales:
`20261020000000_labor_planning_changes.sql` y
`20261020010000_budgeted_team_responsibilities.sql`.
Respaldo previo: `backups/data_backup_20261020_143507.sql` y
`backups/schema_before_team_budget_20261020_143509.sql`.
Comparación de cantidades y huellas de todas las tablas previas: sin cambios,
excluyendo únicamente los campos nuevos con valores predeterminados. Se verificó
la lectura con la cuenta habitual en 13 proyectos activos mediante ROLLBACK.

Validación: 50 pruebas Flutter de planificación, fechas, disponibilidad, accesos y
secciones aprobadas; corrida final de 31 pruebas de formularios, costo y fechas
de cobertura aprobada (incluye los dos casos adicionales de costo y cobertura).
SQL `labor_planning_changes.sql` aprobado en base aislada con ROLLBACK, incluyendo
corrección, permisos, relevo, retiro, cancelación, emisión obligatoria, copia de
plazas y autorización de usuario. Las seis baterías SQL previas también pasaron
en el esquema final; sus fixtures de cotización se marcan explícitamente como
contratos anteriores. Generación core/data/main_app completada. Análisis sin
errores de compilación; se conservan avisos existentes de estilo/deprecaciones.
Compilación web release con `.env` local correcta. Producción sin cambios.

Las fases pendientes de transferencias temporales, maquinaria, Labor Cost y
limpieza de navegación continúan pendientes; esta entrega no las sustituye.

### Supervisión por servicio con recursos compartidos (2026-10-20)

Sustituye el selector genérico de función operativa de las líneas de Labor en la
cotización. La mano de obra procedente de Work Projection conserva sus cargos,
cantidades, tarifas y cálculos. Las líneas nuevas de dirección se gestionan en
un bloque separado, Supervisión y liderazgo, dentro de cada servicio.

Para Supervisor y Foreman hay acciones Agregar recurso propio y Compartir recurso
existente. Se permiten varias plazas y varios recursos identificados por UUID y
nombre visible, por ejemplo Supervisor 1 y Foreman 2. Cada servicio muestra qué
otros servicios utilizan el mismo recurso. Cargo, identificador, cantidad y
tarifas se actualizan conjuntamente; meses y dedicación son específicos de cada
servicio. Quitar una cobertura no elimina las demás; Convertir en recurso propio
crea una identidad independiente conservando los valores revisables de la línea.
Las copias de una cotización remapean las identidades para no compartir personal
accidentalmente entre documentos diferentes.

El costo de cada participación utiliza los meses del servicio multiplicados por
la dedicación. Se guarda ese período efectivo en las columnas laborales ya usadas
por totales y reportes; la duración base se conserva por separado para la edición.
Por ejemplo, dos servicios simultáneos al 50 % consumen el equivalente a un recurso
completo; servicios consecutivos pueden usar el 100 % cada uno. No se introduce
otro subtotal que duplique las líneas laborales. Las líneas de dirección siguen
apareciendo como costo laboral distribuido en cada servicio.

Las cotizaciones nuevas exigen Supervisor y Foreman propios o compartidos en cada
servicio antes de enviarse/aprobarse. El formulario valida antes de persistir y el
servidor repite la comprobación: datos completos, cantidad entera, tarifa positiva,
períodos válidos, metadatos coherentes para una misma identidad y compromiso no
superior al 100 % en intervalos coincidentes. Se permite guardar borradores
incompletos. Documentos anteriores conservan su interpretación hasta adoptar
explícitamente el nuevo esquema; no se alteran los registros históricos.

Al convertir, cada identidad genera una sola agrupación de plazas físicas,
independiente del número de servicios cubiertos. El servidor también rechaza
duplicarlas. Resource Planning presenta la participación compartida en los otros
servicios y reutiliza la asignación original del trabajador, sin añadir otra
reserva de fechas ni otra autorización. La selección desde una participación
compartida se limita a ese recurso. Las fechas de referencia abarcan sus servicios
cubiertos, con el calendario de obra. La agrupación de plazas distingue también
la identidad del recurso. El listado superior de servicios incluye los servicios
planificados aunque solo tengan responsables compartidos.

El presupuesto compartido de origen queda protegido una vez que tiene plazas en
un proyecto. El formulario comprueba esa situación antes de modificar sus recursos
y el servidor bloquea modificar/eliminar las líneas compartidas ya planificadas.
El intercambio de responsables/personas se sigue gestionando desde Resource
Planning, conservando el historial de ejecución.

Migración local: `20261020020000_shared_estimate_leadership.sql`.
Respaldo final previo: `backups/data_backup_20261020_192837.sql` y
`backups/schema_before_shared_leadership_20261020_192838.sql`.
Integridad: todas las tablas previas conservaron cantidades y huellas de sus datos,
excluyendo únicamente las nuevas columnas con valores predeterminados. Lectura
verificada con la cuenta administradora habitual en 13 proyectos activos,
mediante una transacción con ROLLBACK.

Validación: 55 pruebas Flutter aprobadas; ocho baterías SQL aprobadas con fixtures
reversibles en `noel_shared_leadership_20261020`. Incluyen costo distribuido,
preservación del personal proyectado, sobreasignación simultánea, servicios
consecutivos, tarifas compartidas coherentes, plazas físicas únicas, protección
del presupuesto, reutilización de asignaciones y permisos. Generación
core/data/main_app completada, análisis sin errores de compilación y compilación
web release correcta con `.env` local. Se conservan avisos de estilo existentes.
La revisión automática alcanzó un límite de uso durante la primera comprobación
de integridad; esa acción no se ejecutó. Tras continuar el usuario, el mismo
procedimiento se completó con respaldo actualizado, sin eludir la revisión.

Rama `feat/role-access-project-teams`. Sin merge, push ni cambios en producción.
Las fases restantes de ejecución permanecen pendientes.

### Ajuste visual e idioma de la estimación (20 de octubre)

El idioma de la interfaz de la aplicación es inglés; la conversación y la
documentación de trabajo pueden continuar en español. El bloque Supervision and
Leadership de la estimación usa etiquetas, ayudas, acciones y validaciones en
inglés. Los nombres ingresados por los usuarios se conservan.

El selector Role / Position de Supervisor y Foreman usa el mismo tamaño de
etiqueta y espaciado interno que los campos contiguos. Su botón desplegable
compacto evita aumentar la altura del campo. No cambia los demás selectores del
formulario ni el cálculo de los recursos compartidos. Las tres pruebas de costos
y dedicación compartida fueron aprobadas.

### Cobertura simultánea confirmada y costo único (20 de octubre)

La cobertura de varios grupos queda a criterio del administrador. El bloqueo por
suma de porcentajes se reemplaza, en el flujo automático, por una advertencia con
recursos, servicios, fechas y montos resultantes antes de aprobar. Se usa tanto al
enviar/aceptar desde el formulario como en Approve & Start Project. Cancelar no
aplica la distribución de la vista previa ni crea el proyecto.

El formulario calcula Allocated Months y ofrece Cost allocation: Distribute
automatically o Charge to un servicio. El cálculo divide el calendario en tramos
del mismo recurso; conserva el tiempo completo fuera de coincidencias y reparte
el tramo coincidente proporcionalmente. Mantiene la base existente de meses de
estimación y 220 horas/mes. Si las duraciones por día difieren, la capacidad del
recurso en ese tramo es la mayor duración diaria presupuestada, nunca la suma.
Si se elige un servicio de costo, absorbe el tiempo de toda la cobertura; los
otros servicios mantienen la responsabilidad con costo cero. Esto no cambia la
cantidad de personas ni duplica las plazas físicas en Resource Planning.

La RPC prepare_quote_team_allocation proporciona una vista previa sin modificar
datos. La confirmación exige Admin activo, verifica que el presupuesto revisado
no haya cambiado y aplica meses, costo por servicio, total y auditoría en una
transacción. Incluye viáticos, overhead y profit; conserva el precio contractual
de líneas LS/staffing. La validación comprueba el cálculo y la confirmación del
presupuesto actual. Los cambios de fechas, recurso, tarifa o presupuesto invalidan
la confirmación. Los presupuestos anteriores conservan sus importes hasta que el
administrador confirma la nueva distribución; los proyectos ya creados no se
recalculan desde la estimación.

Migración local: 20261020030000_automatic_shared_leadership.sql. Respaldo previo:
backups/data_backup_20261020_202328.sql y
backups/schema_before_automatic_leadership_20261020_202330.sql. Las huellas de
todas las filas previas de public coincidieron después de la migración,
excluyendo únicamente las dos nuevas columnas predeterminadas. No se aprobaron
estimaciones existentes automáticamente.

Validación: 63 pruebas Flutter aprobadas, incluyendo coincidencia total/parcial,
fechas consecutivas, tres servicios, duraciones diferentes, servicio principal,
cambio de principal y las decisiones de confirmar/cancelar. Nueve baterías SQL
aprobadas en noel_auto_leadership_20261020 con fixtures en ROLLBACK: permisos,
reparto, precios, confirmación obsoleta, auditoría protegida y planificación de
una sola plaza compartida. Análisis sin errores; conserva avisos previos.
Compilación web release completada con configuración local. Vista previa de la
estimación pendiente verificada con samuel@mey.com sin aplicarla, y lectura de
planificación verificada en 13 proyectos activos mediante ROLLBACK.

Sin merge, push ni cambios en producción. Las fases pendientes siguen pendientes.

### Fechas de referencia en Project Access (21 de octubre)

Assign Project Access usa ResponsiveDialogShell, igual que los modales de
planificación: encabezado con icono y cierre, cuerpo con scroll y pie fijo.
Etiquetas externas, campos de igual altura, calendario y botones adaptables a
pantallas estrechas. El panel y sus acciones se presentan en inglés.

El bloque Service periods muestra todos los servicios de la estimación y del
proyecto, evitando duplicar los servicios vivos vinculados a la cotización. Toma
la estimación más reciente de Work Projection; si no existe, usa el rango de las
tareas planificadas del servicio. Las fechas faltantes se muestran como Not set,
sin inventar la fecha actual. El inicio propuesto es el menor inicio conocido y
el fin es el mayor fin conocido. Use service period permite recuperar esa
propuesta. La duración estimada en días laborables se muestra cuando está disponible.

El administrador puede modificar la vigencia porque limita acceso a todo el
proyecto, no la asignación laboral ni una cuadrilla. El fin puede quedar vacío;
cuando se informa, no puede ser anterior al inicio. Los errores al guardar
mantienen la persona y fechas ingresadas en el formulario.

Siete pruebas de períodos y widgets verifican precedencia de estimación, fallback
a planificación, deduplicación, ausencia de fechas, propuestas, selección de
cuentas activas, restauración del período, fin opcional, rango inválido y diseño
en 1280×950 y 390×844. Análisis de los archivos nuevos sin incidencias. No requiere
migración de base de datos ni modifica autorizaciones existentes automáticamente.
Validación final: 20 pruebas aprobadas, incluyendo las regresiones de permisos y
fechas de planificación; compilación web release correcta con configuración
local. El análisis de la integración no presenta errores; la página principal
conserva sus avisos de estilo anteriores. Sin merge ni push.
El recuadro de referencias se compactó a una línea por servicio: nombre, rango
de fechas y días estimados, sin repetir el origen de las fechas. Su altura máxima
es de 160 px con desplazamiento interno para proyectos con muchos servicios; en
pantallas estrechas el texto se adapta sin desbordarse.

### Modal de personal compacto (22 de octubre)

Assign Personnel and Crew presenta el período de referencia como Machinery
Planning: icono, encabezado breve y una línea con inicio, fin y días laborables.
Se eliminan del recuadro la repetición del servicio, las explicaciones del
calendario y los textos sobre precedencia de fechas; el cálculo no cambia.

Las filas de selección distribuyen nombre, oficio y estado de cuenta en columnas
en escritorio; en móvil se adaptan a dos líneas. Los únicos textos adicionales
son impedimentos de selección: cuenta requerida, selección en otro oficio y
proyecto/fechas de ocupación. Se conserva el bloqueo de trabajadores ocupados y
los datos completos de sus asignaciones. Los textos del modal y sus mensajes de
disponibilidad se muestran en inglés; se conservan los nombres y oficios de los
catálogos. Las pruebas comprueban un recuadro menor de 100 px y filas normales de
hasta 64 px en escritorio, además de disponibilidad, fechas y selección.

### Machinery Table: fechas del servicio y corrección masiva (22 de octubre)

La tabla conserva las fechas guardadas de las unidades y, si faltan, propone el
período del servicio. Ya no completa hoy ni agrega siete días arbitrariamente.
Si falta el fin, utiliza duración y calendario del proyecto cuando están
disponibles. La referencia de la estimación mantiene prioridad; las tareas
planificadas aportan referencia cuando el servicio no tiene fechas estimadas.
La tabla muestra el rango completo de las asignaciones, no solo un resumen que
puede estar vacío, y el contador de máquinas respeta el filtro del servicio.

Bulk schedule / correct dates trabaja exclusivamente con las filas mostradas.
Schedule pending units conserva las unidades ya planificadas y completa solo las
faltantes. Replace dates for all shown units permite corregir fechas existentes.
El formulario muestra máquinas, unidades, alcance y referencias por servicio.
Si los períodos son distintos no propone un rango común arbitrario: el usuario
elige el rango que aplicará. La acción individual de la tabla aplica a todas las
unidades de esa máquina y lo informa antes de guardar.

Table y Normal guardan mediante MachineryPlanningService y la RPC transaccional
save_machinery_planning. El servidor valida proyecto activo, rol autorizado,
pertenencia al proyecto, capacidad, fechas y snapshot de las asignaciones. Un
error cancela todo el lote. Las correcciones conservan IDs, cantidades, estados
y fechas reales de ejecución; Normal conserva grupos independientes y el resumen
abarca todas sus fechas. No permite eliminar ni dividir/reducir un grupo con
ejecución real. Los errores llegan al formulario y no se cuentan como éxitos.

Migración local: 20261022000000_atomic_machinery_planning.sql. Respaldos previos:
backups/data_backup_20261022_114241.sql y
backups/schema_before_machinery_planning_20261022_114246.sql. Todas las cantidades
y huellas de filas previas de public coincidieron después de instalar la función;
no se corrigieron automáticamente fechas de proyectos existentes.

Validación: 21 pruebas Flutter aprobadas, incluyendo propuestas, calendario,
varias unidades, períodos distintos, cambio de acción y móvil; diez baterías SQL
aprobadas en noel_machinery_planning_20261022 con fixtures en ROLLBACK. Comprueban
corrección de unidades existentes, pendientes, preservación de ejecución,
capacidad, datos obsoletos, rollback completo, alcance y permisos. Generación
core/data/main_app completada y análisis sin errores; conserva avisos existentes.
El primer intento de integración agotó el tiempo de la revisión automática de
permisos sin ejecutarse; el reintento terminó correctamente. Sin merge ni push.
Compilación web release completada correctamente con configuración local. La
activación solo instaló la función y registró la migración; no cambió las fechas
de ninguna maquinaria existente.

### 2026-10-22 — Descanso automático y validación del sobretiempo semanal

Comparado con `main` local: `StepLabor` descuenta 30 minutos en tramos de
6 horas o más y cero en tramos menores. El wizard por cuadrilla activaba
`explicitBreaks`, lo que iniciaba el descanso en cero y exigía introducirlo
manualmente. Se retiró esa activación para recuperar la política automática
compartida con el reporte consolidado. Los borradores existentes conservan sus
valores hasta volver a confirmar entrada/salida; no se reescribió información
histórica ni aprobada.

El cálculo de nómina `_calcWeeklyOT` conserva la implementación de `main`:
suma horas netas por trabajador y semana ISO, hasta 40 regulares y únicamente
el excedente como sobretiempo al 1.5. Las horas extras mostradas por jornada no
se suman como sobretiempo pagadero. Solo se consultan reportes aprobados.
No se modificó el cálculo de nómina.

Validación: 19 pruebas Flutter aprobadas (4 de descanso y horas netas, 9 de
secciones de reporte y 6 de nómina mediante API simulada). Incluyen límite de
6 horas, eliminación del descuento al acortar el tramo, 36/40/44 horas
semanales, cinco jornadas de 8.5 horas, separación entre semanas y entre
trabajadores. Generación core/data/main_app completada. Sin merge ni push.

### 2026-10-22 — Selector de cuadrilla e idioma del reporte

La etiqueta del selector se muestra encima del campo, fuera del borde flotante
que se recortaba en el Stepper. Usa `Crew` para Foreman y `Report scope` para
Admin/Supervisor. Fecha, selector y estado se alinean por la base y se acomodan
en filas según el espacio disponible. Los nombres largos usan una sola línea.

Se pasaron a inglés los textos de cuadrillas del wizard: estados, notas,
confirmaciones, avisos, errores, guardado y envío/revisión. También se ajustaron
los campos de unidad física e inicio/fin de maquinaria, los textos del descanso
manual y el acceso a Daily Reports del menú restringido. Los nombres y notas
introducidos por los usuarios no se traducen.

Validación: 19 pruebas existentes aprobadas con las expectativas de interfaz
actualizadas. Generación completada en core/data/main_app y análisis sin
errores; permanecen avisos previos en los archivos revisados. No se cambió la
lógica del reporte, los descansos ni el sobretiempo. Sin merge ni push.

### 2026-10-22 — Avance de maquinaria en reportes por cuadrilla

Se recuperaron las barras diarias y acumuladas en el flujo operativo, con
resúmenes por servicio, maquinaria principal y unidad física. Muestran plan,
producción total validada más captura actual y el aporte de la cuadrilla.
La consulta `get_daily_machinery_progress` entrega datos operativos mediante
el workspace autorizado; no expone tarifas, costos, operadores ni filas de
otras cuadrillas. Se mantienen los controles de proyecto, fecha y cuadrilla.

El histórico se limita a la fecha consultada: incluye reportes heredados
enviados/aprobados y secciones aprobadas; excluye reportes rechazados y fechas
posteriores. En la fecha actual se excluye la sección seleccionada del agregado
y se reemplaza por el contenido del formulario, incluso en consulta, para no
duplicar producción al guardar/reabrir. La unidad se identifica por
`machinery_inspection_id`; se suman sus tramos aunque cambien el orden, operador
o cuadrilla. Los registros antiguos sin unidad física solo cuentan en los
totales y se informa esta condición.

El plan usa períodos y cantidades guardados de maquinaria, con referencia al
calendario laboral: sábado medio día, domingo cero y días no laborables o
parciales. Sin fechas/metas se informa su ausencia, sin inventar un período.
La planificación actual no vincula períodos a unidades físicas: la meta por
unidad es una parte igual de la cantidad prevista, identificada expresamente
en la pantalla. No se suman medidas incompatibles en una sola barra.

Migración `20261022010000_daily_machinery_progress.sql` aplicada únicamente en
local después de respaldo: `backups/data_backup_20261022_152338.sql` y
`backups/schema_before_daily_machinery_progress_20261022_152342.sql`.
Recuentos y hashes de todas las tablas públicas idénticos antes/después.
No se alteró la excepción temporal de acceso para proyectos futuros.

Validación: 27 pruebas Flutter aprobadas, incluyendo la pantalla completa del
Foreman con barras por servicio/maquinaria/unidad, pantallas estrechas,
calendario, tramos, unidades reordenadas y ausencia de fechas; también se
verificaron secciones, descanso automático y nómina semanal. Once baterías SQL
aprobadas en base aislada con fixtures en ROLLBACK, incluyendo permisos,
identidad física, exclusión de datos posteriores/rechazados y no duplicación
de la sección actual. Generación core/data/main_app completada. Sin merge ni push.

### 2026-10-22 — Comparación sobre el plan y vista del administrador

Las barras Plan/Actual usan una escala común y muestran porcentaje y diferencia,
incluido sobrecumplimiento (100 plan / 130 real: 130%, +30). El consolidado del
administrador carga la misma consulta operativa; los registros actuales, incluso
pendientes de revisión, se muestran como `Current report`. Los valores actuales
del snapshot se reemplazan por las filas del reporte para no duplicar secciones
aprobadas. El histórico mantiene su filtro de validación. Sin cambios de base,
aprobación, nómina, merge ni push.

Validación puntual: 12 pruebas de maquinaria y 9 del flujo de secciones
aprobadas. Incluyen ejecución superior/inferior al plan, consolidado del
administrador sin duplicación, unidades físicas y pantalla estrecha con scroll.

### 2026-10-22 — Presentación compacta del acumulado

Por solicitud del usuario se sustituyeron las barras diarias y las dos barras
Plan/Actual por una sola barra acumulada con una marca vertical del plan.
Solo se muestran título, acumulado real/planificado y porcentaje. El detalle
diario y las notas quedan en tooltips. Se elimina el resumen gráfico intermedio
de maquinaria y la repetición de viajes cuando ya se muestra el volumen CY;
se mantienen el servicio y cada unidad física.

Calendario verificado contra main: lunes a viernes completos, sábado medio día,
domingo sin incremento y días no laborables/parciales según calendario. El
cálculo no cambió; se añadió una prueba del acumulado viernes-sábado-domingo-lunes.
Sin cambios de base de datos, merge ni push.

Validación compacta: 13 pruebas de maquinaria aprobadas, incluyendo la marca
del plan, exceso de producción, vistas Foreman/Administrador y calendario de
fin de semana. La lógica del acumulado y sus permisos no se modificaron.

### 2026-10-27 — Acumulado operativo con reportes enviados

Comparación con main: el avance original incluía producción de reportes
submitted y approved. El RPC por cuadrillas estaba exigiendo approved, lo que
omitía aportes enviados de días anteriores mientras crecía el plan acumulado.
Migración 20261027000000: incluye submitted y approved en el agregado operativo,
conservando corte por fecha, identidad física, exclusión del aporte actual que
sustituye el formulario y permisos. No cambia validación financiera ni nómina.
Se actualizan los tooltips en inglés sin ampliar la gráfica.

Validación: suite SQL aislada con ROLLBACK (historial enviado al día siguiente,
sin duplicar tras aprobar, rechazados/futuro excluidos y permisos); 13 pruebas
Flutter de avance/calendario aprobadas. Aplicado solo local tras respaldos;
conteos y hashes de todas las tablas públicas idénticos. Sin merge ni push.

### 2026-10-27 — Maquinaria por servicio de la cuadrilla

Se corrige la carga de maquinaria de todo el proyecto en el reporte de una
cuadrilla con servicio planificado. El workspace filtra maquinaria y gráficas
por crew_service_assignments vigente y por la identidad del servicio
(cotización o servicio propio del proyecto). Un trigger valida también INSERT
y UPDATE, incluidos standby y sustitución por Supervisor, evitando el bypass
del selector. La asignación continúa siendo al servicio, no a la cuadrilla.
Cuadrillas históricas sin planificación de servicio conservan su comportamiento
anterior; una asignación existente pero fuera de vigencia no habilita recursos.
No se elimina ni reasigna ejecución histórica.

Validación: nueva suite SQL crew_machinery_service_scope con guardado permitido,
rechazo exacto de servicio ajeno, fechas, filtrado y atomicidad; regresiones
 daily_execution, daily_section_integration y daily_machinery_progress aprobadas.
Aplicación local respaldada; conteos/hashes públicos sin cambios. Sin merge/push.

### 2026-10-27 — Cierre seguro del diálogo de devolución

La devolución de una sección por Supervisor podía fallar al liberar el
TextEditingController del motivo mientras el diálogo todavía animaba su cierre.
Se reprodujo el uso de controlador eliminado antes de corregirlo. Ahora el
diálogo de revisión administra su formulario y controlador en su propio State,
liberándolos al desmontarse. Devuelve el motivo confirmado a la página; cancelar
no ejecuta revisión. El motivo continúa siendo obligatorio. Se conservan el
RPC, las reglas de aprobación independiente y el diseño existente en inglés.
No hay cambios de base de datos.

Validación: 13 pruebas Flutter aprobadas (4 de confirmación/cancelación del diálogo y 9 del reporte por cuadrillas). Sin merge ni push.
