import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final url = 'https://mvesrkpudqsyhmoqjdsc.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12ZXNya3B1ZHFzeWhtb3FqZHNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMDA1MzEsImV4cCI6MjA4Njc3NjUzMX0.W6JW-kexTmxGASwG-g6LTpgf21wiZqLuczsqUZKyFQk';

  final supabase = SupabaseClient(url, anonKey);

  print('Conectando a producción...');

  try {
    // 1. Obtener los roles de producción
    final rolesRes = await supabase.from('labor_roles').select('id, description');
    final rolesMap = {for (var r in rolesRes) r['description'].toString(): r['id'].toString()};

    print('Roles encontrados en producción: ${rolesMap.keys.join(', ')}');

    final workers = [
      {'name': 'Carlos Rodriguez', 'id': 'ID-1001', 'role': 'SUPERVISOR'},
      {'name': 'Maria Gonzales', 'id': 'ID-1002', 'role': 'SUPERVISOR'},
      {'name': 'Jose Martinez', 'id': 'ID-1003', 'role': 'SUPERVISOR'},
      {'name': 'Luis Hernandez', 'id': 'ID-1004', 'role': 'SUPERVISOR'},
      {'name': 'Ana Lopez', 'id': 'ID-1005', 'role': 'SUPERVISOR'},
      // ... Add some more from the list
      {'name': 'Juan Perez', 'id': 'OP-2001', 'role': 'Excavator Operator'},
      {'name': 'Pedro Garcia', 'id': 'OP-2002', 'role': 'Excavator Operator'},
      {'name': 'Lionel Messi', 'id': 'TK-3009', 'role': 'Truck Operator'},
      {'name': 'Diego Maradona', 'id': 'TK-3010', 'role': 'Truck Operator'},
      {'name': 'Arthur Morgan', 'id': 'SH-4001', 'role': 'Shaper Class B'},
      {'name': 'Geralt of Rivia', 'id': 'SC-5001', 'role': 'Scraper operator'},
    ];

    int count = 0;
    for (var w in workers) {
      final roleId = rolesMap[w['role']];
      if (roleId != null) {
        await supabase.from('workers').insert({
          'full_name': w['name'],
          'id_number': w['id'],
          'role_id': roleId,
          'status': 'Active'
        });
        print('Insertado: ${w['name']}');
        count++;
      } else {
        print('Error: Rol no encontrado para ${w['name']} (${w['role']})');
      }
    }

    print('Proceso terminado. Se insertaron $count trabajadores en producción.');
    exit(0);
  } catch (e) {
    print('Error fatal: $e');
    exit(1);
  }
}
