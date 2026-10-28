import 'package:flutter/material.dart';

/// Searchable role/position selector used in the Workers module.
///
/// Keeps filtered options below the input, with a scrollable height limited
/// to the space remaining above the keyboard or the bottom of the screen.
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

    final selected = roles
        .where((r) => r['id'] == effectiveInitial)
        .firstOrNull;
    final selectedLabel = (selected?['description'] ?? '').toString();
    final fieldKey = GlobalKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Autocomplete<Map<String, dynamic>>(
            key: ValueKey('role_${effectiveInitial ?? 'none'}'),
            initialValue: TextEditingValue(text: selectedLabel),
            optionsViewOpenDirection: OptionsViewOpenDirection.down,
            displayStringForOption: (role) =>
                (role['description'] ?? '').toString(),
            optionsBuilder: (value) {
              if (!enabled) return const Iterable<Map<String, dynamic>>.empty();
              final query = value.text.trim().toLowerCase();
              return roles.where(
                (role) =>
                    query.isEmpty ||
                    value.text == selectedLabel ||
                    (role['description'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(query),
              );
            },
            onSelected: onChanged,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                TextFormField(
                  key: fieldKey,
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  decoration: InputDecoration(
                    hintText: 'Search role...',
                    labelText: 'Role / Position',
                    prefixIcon: const Icon(Icons.work_outline),
                    suffixIcon: IconButton(
                      tooltip: 'Search roles',
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: enabled
                          ? () {
                              controller.clear();
                              focusNode.requestFocus();
                            }
                          : null,
                    ),
                  ),
                  onFieldSubmitted: (_) => onSubmitted(),
                ),
            optionsViewBuilder: (context, select, options) {
              final box =
                  fieldKey.currentContext?.findRenderObject() as RenderBox?;
              final media = MediaQuery.of(context);
              final bottom = box == null
                  ? 0.0
                  : box.localToGlobal(Offset(0, box.size.height)).dy;
              final height =
                  (media.size.height -
                          media.viewInsets.bottom -
                          media.padding.bottom -
                          bottom -
                          8)
                      .clamp(0.0, 240.0);
              final matches = options.toList();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: height),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final role = matches[index];
                          return ListTile(
                            selected:
                                AutocompleteHighlightedOption.of(context) ==
                                index,
                            title: Text((role['description'] ?? '').toString()),
                            onTap: () => select(role),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
