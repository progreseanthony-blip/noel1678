import 'package:flutter/material.dart';

/// Searchable role/position selector used in the Workers module.
///
/// Wraps Material 3 [DropdownMenu] so the user can type to filter roles
/// (built-in search field) and the options menu opens **below** the field
/// instead of covering it (unlike [DropdownButtonFormField], whose overlay
/// often opens on top of the anchor inside narrow dialogs).
class SearchableRoleField extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final String? initialRoleId;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final String? errorText;
  final bool enabled;

  const SearchableRoleField({
    super.key,
    required this.roles,
    required this.onChanged,
    this.initialRoleId,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ids = roles.map((r) => r['id'] as String).toSet();
    final effectiveInitial = ids.contains(initialRoleId) ? initialRoleId : null;

    final entries = roles
        .map(
          (r) => DropdownMenuEntry<String>(
            value: r['id'] as String,
            label: (r['description'] ?? '').toString(),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownMenu<String>(
          key: ValueKey('role_${effectiveInitial ?? 'none'}'),
          enabled: enabled,
          expandedInsets: EdgeInsets.zero,
          enableSearch: true,
          enableFilter: true,
          requestFocusOnTap: true,
          menuHeight: 280,
          hintText: 'Search role...',
          label: const Text('Role / Position'),
          leadingIcon: const Icon(Icons.work_outline),
          initialSelection: effectiveInitial,
          filterCallback: (entries, filter) {
            final q = filter.toLowerCase();
            if (q.isEmpty) return entries;
            return entries
                .where((e) => e.label.toLowerCase().contains(q))
                .toList();
          },
          dropdownMenuEntries: entries,
          onSelected: (id) {
            if (id == null) {
              onChanged(null);
            } else {
              try {
                onChanged(roles.firstWhere((r) => r['id'] == id));
              } catch (_) {
                onChanged(null);
              }
            }
          },
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
