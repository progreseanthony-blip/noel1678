import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Approves a quote and converts it into a project.
  /// Throws an exception if the project already exists or if an error occurs.
  static Future<String> convertQuoteToProject(String quoteId) async {
    // 1. Fetch the quote details to check its status
    final quote = await _supabase
        .from('quotes')
        .select()
        .eq('id', quoteId)
        .single();

    if (quote['status'] == 'accepted') {
      throw Exception('This estimate has already been approved and converted to a project.');
    }

    // 2. Check if a partial/orphaned project exists for this quote
    final existingProject = await _supabase
        .from('projects')
        .select('id')
        .eq('quote_id', quoteId)
        .maybeSingle();

    if (existingProject != null) {
      // Clean up the orphaned project from a previously failed creation attempt
      await _supabase.from('projects').delete().eq('id', existingProject['id']);
    }

    // 3. Create the project
    final projectInsert = await _supabase.from('projects').insert({
      'quote_id': quoteId,
      'title': quote['title'] ?? 'Untitled Project',
      'client_name': quote['client_name'],
      'status': 'active',
      'start_date': DateTime.now().toIso8601String(),
      'project_type': quote['quote_type'] ?? 'standard',
    }).select().single();

    final String projectId = projectInsert['id'];

    // 4. Fetch the expected machinery, materials, labor, and instruments from the quote
    final services = await _supabase
        .from('quote_services')
        .select('id, name, quote_service_machineries(id, machine_name, quantity, is_primary_mover), quote_service_materials(id, material_name, unit_name, quantity), quote_service_labors(id, role_name, role_id, employees_quantity), quote_service_instruments(id, instrument_name, quantity)')
        .eq('quote_id', quoteId);

    final List<Map<String, dynamic>> machineriesToInsert = [];
    final List<Map<String, dynamic>> materialsToInsert = [];
    final List<Map<String, dynamic>> laborToInsert = [];
    final List<Map<String, dynamic>> instrumentsToInsert = [];
    final List<Map<String, dynamic>> tasksToInsert = [];

    for (final service in services) {
      // Create a task for each service
      tasksToInsert.add({
        'project_id': projectId,
        'quote_service_id': service['id'],
        'name': service['name'] ?? 'General Service Task',
        'status': 'pending',
      });

      // ... machinery logic ...
      final List machineries = service['quote_service_machineries'] ?? [];
      for (final mach in machineries) {
        machineriesToInsert.add({
          'project_id': projectId,
          'quote_service_machinery_id': mach['id'],
          'quote_service_id': service['id'],
          'machinery_name': mach['machine_name'] ?? 'Unknown Machine',
          'expected_quantity': mach['quantity'] ?? 1,
          'received_quantity': 0,
          'is_principal': mach['is_primary_mover'] ?? false,
          'is_unplanned': false,
        });
      }

      // ... existing materials logic ...
      final List materials = service['quote_service_materials'] ?? [];
      for (final mat in materials) {
        materialsToInsert.add({
          'project_id': projectId,
          'quote_service_material_id': mat['id'],
          'quote_service_id': service['id'],
          'material_name': mat['material_name'] ?? 'Unknown Material',
          'unit_name': mat['unit_name'] ?? 'units',
          'expected_quantity': mat['quantity'] ?? 0,
          'received_quantity': 0,
        });
      }

      // ... labor logic ...
      final List labors = service['quote_service_labors'] ?? [];
      for (final lab in labors) {
        laborToInsert.add({
          'project_id': projectId,
          'quote_service_labor_id': lab['id'],
          'quote_service_id': service['id'],
          'role_name': lab['role_name'] ?? 'General Worker',
          'expected_employees': (lab['employees_quantity'] as num?)?.toInt() ?? 1,
          'active_employees': 0,
          'is_unplanned': false,
        });
      }

      // ... instruments logic ...
      final List instruments = service['quote_service_instruments'] ?? [];
      for (final inst in instruments) {
        instrumentsToInsert.add({
          'project_id': projectId,
          'quote_service_instrument_id': inst['id'],
          'quote_service_id': service['id'],
          'instrument_name': inst['instrument_name'] ?? 'Unknown Instrument',
          'expected_quantity': inst['quantity'] ?? 1,
          'received_quantity': 0,
          'is_unplanned': false,
        });
      }
    }

    if (machineriesToInsert.isNotEmpty) {
      await _supabase.from('project_machinery').insert(machineriesToInsert);
    }
    if (materialsToInsert.isNotEmpty) {
      await _supabase.from('project_materials').insert(materialsToInsert);
    }
    if (laborToInsert.isNotEmpty) {
      await _supabase.from('project_labor').insert(laborToInsert);
    }
    if (instrumentsToInsert.isNotEmpty) {
      await _supabase.from('project_instruments').insert(instrumentsToInsert);
    }
    if (tasksToInsert.isNotEmpty) {
      await _supabase.from('project_tasks').insert(tasksToInsert);
    }

    // 5. Update quote status to 'accepted' if it's not already
    if (quote['status'] != 'accepted') {
      await _supabase
          .from('quotes')
          .update({'status': 'accepted'})
          .eq('id', quoteId);
    }

    return projectId;
  }
}
