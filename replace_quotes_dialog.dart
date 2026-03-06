import 'dart:io';

void main() async {
  final file = File('apps/main_app/lib/src/features/quotes/presentation/widgets/quote_form_dialog.dart');
  String content = await file.readAsString();
  
  content = content.replaceAll("UserFormDialog", "QuoteFormDialog");
  content = content.replaceAll("_UserFormDialogState", "_QuoteFormDialogState");
  content = content.replaceAll("userToEdit", "quoteToEdit");
  content = content.replaceAll("user", "quote");
  content = content.replaceAll("User", "Quote");
  content = content.replaceAll("'profiles'", "'quotes'");
  content = content.replaceAll("email", "status");
  content = content.replaceAll("Email", "Status");
  content = content.replaceAll("name", "title");
  content = content.replaceAll("Name", "Title");
  content = content.replaceAll("role", "projectType");
  content = content.replaceAll("Role", "ProjectType");

  await file.writeAsString(content);
}
