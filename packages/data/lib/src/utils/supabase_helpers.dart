/// Converts a dynamic response from Supabase (which returns JSArray on web)
/// into a properly typed List<Map<String, dynamic>>.
///
/// On web, Supabase returns `List<dynamic>` (JSArray) with Map-like entries,
/// which fails with implicit cast. This helper does explicit conversion.
List<Map<String, dynamic>> safeCastList(dynamic value) {
  if (value == null) return [];
  return List<Map<String, dynamic>>.from(value as List);
}
