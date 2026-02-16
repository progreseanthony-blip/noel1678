// Stub database to allow web compilation for UI preview
class AppDatabase {
  final dynamic connection;
  AppDatabase(this.connection);
  
  // Minimal stubs for what might be used
  int get schemaVersion => 1;
  void close() {}
}
