# Accesos, responsables y cuadrillas

> Actualización del 18 de octubre: se está reemplazando el flujo independiente
> Crew Reports/Worked Hours por su integración en Reporte diario y Labor Cost.
> El estado y los límites de cada fase están en
> [implementacion_reporte_diario_unificado.md](implementacion_reporte_diario_unificado.md).
> La fase 2 ya conecta las cuadrillas con Reporte diario en localhost. Crew Reports
> redirige a ese módulo; Worked Hours y las descripciones anteriores de aportes
> duplicados se conservan aquí como referencia histórica hasta completar las
> fases de Labor Cost y compatibilidad.

Implementación local en `feat/role-access-project-teams`. No implica despliegue,
aplicación de migraciones en producción, merge ni push.

El 14 de octubre de 2026 se aplicó la migración a la base local de trabajo para
habilitar las pruebas en localhost. Antes se guardaron los respaldos
`backups/data_backup_20261014_162659.sql` y
`backups/schema_before_access_20261014_162705.sql`.
La cuenta existente `samuel@mey.com` conserva su contraseña y fue verificada como
`Admin` con acceso `active`. No se creó otra cuenta administradora.

También se aplicó localmente la migración incremental de Resource Planning,
con respaldos previos `backups/data_backup_20261014_165430.sql` y
`backups/schema_before_team_planning_20261014_165505.sql`.

## Roles y alcance

| Rol activo | Acceso |
| --- | --- |
| Admin | Todos los módulos; activa cuentas y administra asignaciones. |
| Supervisor | Proyectos asignados, planificación, organización de cuadrillas, reportes diarios, revisión de aportes y horas operativas. Sin acceso al módulo de Estimaciones. |
| Foreman | Aportes diarios y horas de sus cuadrillas vigentes. No consulta tablas de nómina, costos ni catálogos completos. |
| Employee, rol desconocido, pendiente o deshabilitado | Sin acceso operativo. |

El Supervisor no puede crear, editar, aprobar ni eliminar estimaciones o sus
recursos, tampoco mediante solicitudes directas a Supabase. La planificación
mantiene lectura de la estimación de origen únicamente para proyectos asignados.
Ser autor de un borrador antiguo o tener una asignación en `quote_members` no
concede acceso. Los precios y costos necesarios para planificar recursos
siguen formando parte de Resource Planning. Nómina, facturación,
órdenes de cambio y paneles financieros quedan reservados al administrador.
Separar también las tarifas internas/márgenes que ya conviven en las tablas de
estimación requiere definir una política adicional de campos; no se debe asumir
que un campo oculto en pantalla queda protegido en la API.

Las políticas se verifican en Supabase, además de filtrar menú y rutas. Cada
navegación vuelve a consultar el contexto de acceso. Los RPC de Foreman validan
rol, vigencia, proyecto, cuadrilla y estado en cada operación y devuelven solamente
los datos operativos necesarios.

## Incorporación de usuarios

1. La persona se registra con el formulario existente; se crea pendiente.
2. Un Admin edita el usuario, selecciona Admin/Supervisor/Foreman y lo activa.
3. En **Resource Planning → proyecto → Responsables del proyecto** (cabecera), el
   Admin autoriza Supervisor o Foreman con fechas de vigencia. Tener un rol no
   asigna automáticamente obras. Esta opción también existe en proyectos solo de Labor.
4. Una cuenta de acceso y un trabajador son entidades distintas. Los integrantes
   de cuadrilla no necesitan cuenta. El campo opcional `profiles.worker_id` permite
   vincular una cuenta con un trabajador cuando corresponda; no se enlaza por email.

Los roles de sistema no pueden renombrarse ni eliminarse. Crear otro nombre de
rol no concede permisos. No se permite desactivar/degradar/eliminar al último
administrador activo.

## Equipo del proyecto

- `project_members`: responsables y vigencias, sin alterar la planificación.
- `project_crews`: identidad de cuadrillas por proyecto.
- `crew_service_assignments`: servicio y vigencia de cada cuadrilla, con identidad
  estable para servicios de estimación, servicios exclusivos de CO y Labor general.
- `crew_leaders`: historial de líderes con cuenta Foreman asignada a ese proyecto.
- `crew_members`: historial de integrantes, usando los trabajadores y las
  asignaciones de `project_labor_assignments` existentes.
- `quote_members`: se conserva por compatibilidad histórica, pero ya no concede
  permisos al Supervisor ni se administra desde el equipo del proyecto.

Solo Admin puede autorizar supervisores y Foreman para el proyecto. El Supervisor
puede crear cuadrillas, seleccionar entre los Foreman previamente autorizados y
organizar los trabajadores de su obra desde **Labor y cuadrillas**. Puede agregar
personal por selección múltiple, usando las plazas y fechas planificadas, y
vincularlo a una cuadrilla en la misma operación. No puede incorporar nuevas
cuentas al proyecto ni cambiar roles. La pantalla independiente Project Teams se
retiró del menú; los enlaces antiguos redirigen a Resource Planning. Al abrir de
nuevo la pestaña de equipo se recargan las asignaciones hechas en Labor.

Un proyecto admite varios supervisores y cuadrillas. Una cuadrilla tiene un líder
por intervalo; una persona puede dirigir varias cuadrillas. Un trabajador no puede
integrar dos cuadrillas en fechas superpuestas. Su pertenencia debe quedar cubierta
por una asignación laboral en ese proyecto. Las fechas son inclusivas: si un líder
termina el día 10, el reemplazo comienza el 11.

Para cambiar un responsable o integrante, finalizar su vigencia y agregar una
nueva asignación. No se borran los historiales. La pertenencia a una cuadrilla no
crea plazas laborales ni modifica presupuestos. El servidor comprueba también
conflictos de planificación entre proyectos que el Supervisor no puede consultar.

## Registro y aprobación

1. El Foreman abre **Crew Reports**, selecciona cuadrilla y fecha.
2. Registra observaciones, jornadas y descansos, horómetros/producción y consumos
   de materiales planificados. Guarda borrador o envía a revisión.
3. Un Supervisor asignado o Admin revisa el aporte, lo devuelve con motivo o lo
   aprueba. La persona que lo creó no puede aprobarlo.
4. Aprobar incorpora el aporte al reporte único de proyecto/fecha mediante una
   transacción. Un aporte no se incorpora dos veces. Una jornada laboral por
   trabajador/fecha y un registro de maquinaria por recurso/fecha evitan duplicados.
5. Incorporar todos los aportes antes de enviar el consolidado: si este ya está
   enviado/aprobado, no admite nuevas incorporaciones.
6. El consolidado continúa en borrador. Su aprobación final corresponde a otra
   persona autorizada distinta de su responsable; por ejemplo, un Admin cuando
   el Supervisor que consolidó es el único Supervisor del proyecto.

Los aportes aprobados conservan su identidad en `crew_report_id`. Guardar desde el
asistente anterior no los borra ni los duplica. Las secciones que contienen aportes
se muestran en consulta en ese asistente. Los aportes aprobados son inmutables;
la interfaz de correcciones posteriores de aportes aprobados no está incluida.
Actualmente las jornadas de cuadrilla deben terminar el mismo día; para trabajo
nocturno que cruza medianoche se necesita ampliar el modelo de turnos.

En **Worked Hours** se consultan y exportan CSV de horas incorporadas, con el estado
del consolidado. La exportación no incluye importes ni tarifas. Para Foreman solo
se devuelven los aportes propios de sus cuadrillas actualmente autorizadas. La
nómina oficial ahora utiliza únicamente reportes diarios aprobados; no se
recalculan automáticamente períodos ya guardados.

## Historial y proyectos cerrados

`access_audit` registra actor, fecha, operación y valores anteriores/nuevos de
usuarios, asignaciones, proyectos y reportes. Solo Admin puede consultarlo.
Los cambios de recursos y reportes de proyectos completados se bloquean en servidor,
incluidos registros hijos. Reabrir un reporte aprobado requiere Admin y notas.

## Aplicación posterior de la migración

La migración inicial `20261014000000_project_access_and_crews.sql` reemplaza las políticas
permisivas antiguas de las tablas públicas. Las tablas desconocidas se reservan a
Admin. No asigna usuarios existentes automáticamente ni copia datos de otro entorno.
Los Admin existentes continúan activos; Employee necesita clasificación explícita.

La migración incremental `20261014010000_team_planning_and_supervisor_scope.sql`
retira la creación/modificación de estimaciones al Supervisor y permite organizar
cuadrillas dentro de sus proyectos activos. Conserva todas las asignaciones y
auditorías existentes. Los equipos de proyectos no activos quedan en consulta.

Antes de aplicarla a una base de trabajo o producción:

1. Revisar perfiles y mantener al menos un Admin existente.
2. Ejecutar `scripts/db_backup.ps1` como exige AGENTS.md, y conservar también un
   respaldo del esquema/políticas porque esta migración sustituye políticas RLS.
3. Aplicar la migración y publicar el frontend coordinadamente. El frontend nuevo
   deniega acceso si falta `get_access_context`, en lugar de ignorar la restricción.
4. Activar/asignar responsables y cuadrillas, comprobando cada rol.
5. Revisar los buckets públicos heredados: esta migración protege los datos y RPC
   de aplicación, pero no convierte las evidencias históricas de Storage en archivos
   privados ni invalida enlaces públicos ya existentes.

La administración de invitaciones por email y los adjuntos/evidencias en el nuevo
formulario de cuadrilla no forman parte de esta versión; se conserva el registro
de cuentas existente y la evidencia del reporte consolidado.

## Validación reproducible

- `flutter test test/access_context_test.dart` en `apps/main_app`.
- Aplicar ambas migraciones únicamente a una base de pruebas con el esquema del proyecto
  y ejecutar `supabase/tests/project_access.sql` con `psql -v ON_ERROR_STOP=1`.
  El script usa usuarios ficticios y termina con `ROLLBACK`.
- Regenerar core/data/main_app siguiendo AGENTS.md y compilar con `flutter build web`.

Las bases de pruebas con prefijo `noel_access_` y sufijo `_20261014` dentro del
contenedor local de Noel se crearon para probar únicamente una copia del esquema;
no contienen copias de datos reales. Posteriormente se aplicó la migración a la
base `postgres` local de trabajo, con respaldo previo, como se indica al inicio.
