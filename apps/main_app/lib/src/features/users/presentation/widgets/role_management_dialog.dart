import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

/// Dialog to manage roles: list, add, edit, and delete.
class RoleManagementDialog extends StatefulWidget {
  const RoleManagementDialog({super.key});

  @override
  State<RoleManagementDialog> createState() => _RoleManagementDialogState();
}

class _RoleManagementDialogState extends State<RoleManagementDialog> {
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final response = await Supabase.instance.client
          .from('roles')
          .select()
          .order('name');
      setState(() {
        _roles = List<Map<String, dynamic>>.from(response ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRole() async {
    final result = await showSafeDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => const _RoleFormDialog(),
    );
    if (result == true) _loadRoles();
  }

  Future<void> _editRole(Map<String, dynamic> role) async {
    final result = await showSafeDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => _RoleFormDialog(roleToEdit: role),
    );
    if (result == true) _loadRoles();
  }

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(roleName: role['name'] ?? ''),
    );
    if (confirmed == true) {
      await Supabase.instance.client
          .from('roles')
          .delete()
          .eq('id', role['id']);
      _loadRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                )
              else
                Flexible(child: _buildRolesList()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Roles',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add, edit, or remove roles for your organization',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.slate500,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    if (_roles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 48, color: AppTheme.slate400),
            const SizedBox(height: 12),
            Text(
              'No roles created yet',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.slate900),
            ),
            const SizedBox(height: 4),
            Text(
              'Click "Add Role" to create your first role.',
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final role = _roles[index];
        return _RoleListItem(
          name: role['name'] ?? '',
          description: role['description'] ?? '',
          onEdit: () => _editRole(role),
          onDelete: () => _deleteRole(role),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_roles.length} role${_roles.length == 1 ? '' : 's'}',
            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _addRole,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Add Role',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ROLE LIST ITEM
// ══════════════════════════════════════════════════════════════
class _RoleListItem extends StatefulWidget {
  final String name;
  final String description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleListItem({
    required this.name,
    required this.description,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RoleListItem> createState() => _RoleListItemState();
}

class _RoleListItemState extends State<_RoleListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? const Color(0xFFFAFAFB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            // Role icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions (visible on hover)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _hovered ? 1.0 : 0.0,
              child: Row(
                children: [
                  _ActionIcon(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF475569),
                    hoverColor: AppTheme.slate200,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionIcon(
                    icon: Icons.delete_outline,
                    color: AppTheme.errorRed,
                    hoverColor: const Color(0xFFFEF2F2),
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ROLE FORM DIALOG (Add / Edit)
// ══════════════════════════════════════════════════════════════
class _RoleFormDialog extends StatefulWidget {
  final Map<String, dynamic>? roleToEdit;

  const _RoleFormDialog({this.roleToEdit});

  @override
  State<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<_RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isSaving = false;

  bool get _isEditing => widget.roleToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.roleToEdit?['name']);
    _descController = TextEditingController(text: widget.roleToEdit?['description']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await Supabase.instance.client.from('roles').update({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.roleToEdit!['id']);
      } else {
        await Supabase.instance.client.from('roles').insert({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isEditing ? 'Edit Role' : 'Add New Role',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: AppTheme.slate400, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Role Name
                      _buildField(
                        label: 'Role Name',
                        hint: 'e.g. Project Manager',
                        icon: Icons.badge_outlined,
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      // Description
                      _buildField(
                        label: 'Description',
                        hint: 'Brief description of this role',
                        icon: Icons.notes_outlined,
                        controller: _descController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isSaving ? null : _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSaving ? AppTheme.slate400 : AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.check, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Save Changes' : 'Add Role',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
            prefixIcon: Icon(icon, color: AppTheme.slate400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DELETE CONFIRM DIALOG
// ══════════════════════════════════════════════════════════════
class _DeleteConfirmDialog extends StatelessWidget {
  final String roleName;

  const _DeleteConfirmDialog({required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 24),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete "$roleName"?',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. Users assigned to this role will not be affected.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Delete',
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Icon Button ──
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _h ? widget.hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}
