import 'dart:io';

void main() async {
  final file = File('apps/main_app/lib/src/features/quotes/presentation/pages/quotes_list_page.dart');
  String content = await file.readAsString();
  
  // Specific replacements
  content = content.replaceAll("User Management", "Quotes Management");
  content = content.replaceAll("UserListPage", "QuotesListPage");
  content = content.replaceAll("_UserListPageState", "_QuotesListPageState");
  content = content.replaceAll("UserFormDialog", "QuoteFormDialog");
  content = content.replaceAll("user_form_dialog.dart", "quote_form_dialog.dart");
  content = content.replaceAll("user_provider.dart", "quote_provider.dart");
  
  // Table names
  content = content.replaceAll("'profiles'", "'quotes'");
  
  // Field names context
  content = content.replaceAll("userName", "quoteName");
  content = content.replaceAll("userEmail", "quoteTitle");
  content = content.replaceAll("user", "quote");
  content = content.replaceAll("User", "Quote");
  content = content.replaceAll("users", "quotes");
  content = content.replaceAll("Users", "Quotes");
  content = content.replaceAll("role", "status"); // Roles mapping to status? Wait quotes don't have roles.
  
  // Fixes on case mismatches
  content = content.replaceAll("Qquote", "Quote");
  content = content.replaceAll("qquote", "quote");

  await file.writeAsString(content);
}
