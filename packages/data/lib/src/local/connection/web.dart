import 'package:drift/drift.dart';

QueryExecutor connect() {
  // Fallback in-memory for web to allow UI testing without FFI errors
  return QueryExecutor.inMemory();
}
