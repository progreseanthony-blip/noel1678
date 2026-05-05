import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Approves a quote and converts it into a project.
  /// Throws an exception if the project already exists or if an error occurs.
  static Future<String> convertQuoteToProject(String quoteId) async {
    // 1. Check if a project already exists for this quote
    final existingProject = await _supabase
        .from('projects')
        .select('id')
        .eq('quote_id', quoteId)
        .maybeSingle();

    if (existingProject != null) {
      throw Exception('A project has already been created for this estimate.');
    }

    // 2. Fetch the quote details
    final quote = await _supabase
        .from('quotes')
        .select()
        .eq('id', quoteId)
        .single();

    // 3. Create the project
    final projectInsert = await _supabase.from('projects').insert({
      'quote_id': quoteId,
      'title': quote['title'] ?? 'Untitled Project',
      'client_name': quote['client_name'],
      'status': 'active',
      'start_date': DateTime.now().toIso8601String(),
    }).select().single();

    final String projectId = projectInsert['id'];

    // 4. Fetch the expected machinery and materials from the quote
    final services = await _supabase
        .from('quote_services')
        .select('id, name, quote_service_machineries(id, machine_name, quantity), quote_service_materials(id, material_name, unit_name, quantity), quote_service_labors(id, role_name, role_id, employees_quantity)')
        .eq('quote_id', quoteId);

    final List<Map<String, dynamic>> machineriesToInsert = [];
    final List<Map<String, dynamic>> materialsToInsert = [];
    final List<Map<String, dynamic>> laborToInsert = [];
    final List<Map<String, dynamic>> tasksToInsert = [];

    for (final service in services) {
      // Create a task for each service
      tasksToInsert.add({
        'project_id': projectId,
        'quote_service_id': service['id'],
        'name': service['name'] ?? 'General Service Task',
        'status': 'pending',
      });

      // ... existing machinery logic ...
      final List machineries = service['quote_service_machineries'] ?? [];
      for (final mach in machineries) {
        machineriesToInsert.add({
          'project_id': projectId,
          'quote_service_machinery_id': mach['id'],
          'machinery_name': mach['machine_name'] ?? 'Unknown Machine',
          'expected_quantity': mach['quantity'] ?? 1,
          'received_quantity': 0,
        });
      }

      // ... existing materials logic ...
      final List materials = service['quote_service_materials'] ?? [];
      for (final mat in materials) {
        materialsToInsert.add({
          'project_id': projectId,
          'quote_service_material_id': mat['id'],
          'material_name': mat['material_name'] ?? 'Unknown Material',
          'unit_name': mat['unit_name'] ?? 'units',
          'expected_quantity': mat['quantity'] ?? 0,
          'received_quantity': 0,
        });
      }

      // ... new labor logic ...
      final List labors = service['quote_service_labors'] ?? [];
      for (final lab in labors) {
        laborToInsert.add({
          'project_id': projectId,
          'quote_service_labor_id': lab['id'],
          'role_name': lab['role_name'] ?? 'General Worker',
          'expected_employees': (lab['employees_quantity'] as num?)?.toInt() ?? 1,
          'active_employees': 0,
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
