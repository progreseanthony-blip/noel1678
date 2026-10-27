# Temporary local access for future Daily Reports

Enabled on 2026-10-22 at the user's request, only in database `postgres`
of local container `supabase_db_Noel_1678`. Not a deployable migration.

- Future project memberships appear in the access context before their start.
- The Daily Reports project menu accepts future crew leadership when the
  project authorization and leadership periods overlap.
- Opening the report list today is allowed without an eligible crew today.
  Select the future report date to load its crew and workers.
- Saving still requires leadership and project authorization for the selected
  report date. Other crews, unassigned projects, expired access, disabled
  accounts and closed-project protections remain in force.
- No service, worker, membership or leadership dates were modified.

Pending after testing: restore the original five function definitions using
`scratch/restore_future_report_access_local.sql`, then sign out and back in.
Apply or restore only with `psql -v ON_ERROR_STOP=1` against the local container.
Do not add the temporary enable script to production migrations.

Backup: `backups/data_backup_20261022_142549.sql`.
Original function definitions are in the restore script.
All public-table row counts and hashes matched before and after activation.
Future-access tests (including actual draft saving and rejected writes outside
crew scope) and Daily Report section integration tests passed in isolated
database `noel_machinery_planning_20261022`; test fixtures were rolled back.
