import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://mvesrkpudqsyhmoqjdsc.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12ZXNya3B1ZHFzeWhtb3FqZHNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMDA1MzEsImV4cCI6MjA4Njc3NjUzMX0.W6JW-kexTmxGASwG-g6LTpgf21wiZqLuczsqUZKyFQk';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    print('Testing query to machinery...');
    final data = await client.from('machinery').select().limit(1);
    print(data);
  } catch(e) {
    print('Error: $e');
  }
}
