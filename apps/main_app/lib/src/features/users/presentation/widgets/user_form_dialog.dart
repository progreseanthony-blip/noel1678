import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? userToEdit;

  const UserFormDialog({super.key, this.userToEdit});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleSearchController;

  String? _selectedRole;
  List<String> _availableRoles = [];
  List<String> _filteredRoles = [];
  bool _loadingRoles = true;
  bool _isSaving = false;
  bool _showRoleDropdown = false;
  final FocusNode _roleFocusNode = FocusNode();
  final LayerLink _roleLayerLink = LayerLink();
  OverlayEntry? _roleOverlayEntry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userToEdit?['name']);
    _emailController = TextEditingController(text: widget.userToEdit?['email']);
    _selectedRole = widget.userToEdit?['role']?.toString();
    _roleSearchController = TextEditingController(text: _selectedRole ?? '');
    _loadRoles();

    _roleFocusNode.addListener(() {
      if (_roleFocusNode.hasFocus) {
        _showRoleOverlay();
      } else {
        // Small delay to allow click on dropdown item
        Future.delayed(const Duration(milliseconds: 200), () {
          _hideRoleOverlay();
        });
      }
    });
  }

  Future<void> _loadRoles() async {
    try {
      final response = await Supabase.instance.client
          .from('roles')
          .select('name')
          .order('name');
      final roles = List<Map<String, dynamic>>.from(response ?? [])
          .map((r) => r['name'].toString())
          .toList();
      setState(() {
        _availableRoles = roles;
        _filteredRoles = roles;
        _loadingRoles = false;
        if (_selectedRole != null && !_availableRoles.contains(_selectedRole)) {
          _availableRoles.insert(0, _selectedRole!);
          _filteredRoles = List.from(_availableRoles);
        }
      });
    } catch (_) {
      setState(() {
        _availableRoles = ['Admin', 'Employee'];
        _filteredRoles = List.from(_availableRoles);
        _loadingRoles = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleSearchController.dispose();
    _roleFocusNode.dispose();
    _hideRoleOverlay();
    super.dispose();
  }

  bool get _isEditing => widget.userToEdit != null;

  void _filterRoles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRoles = List.from(_availableRoles);
      } else {
        _filteredRoles = _availableRoles
            .where((r) => r.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    // Update overlay
    _roleOverlayEntry?.markNeedsBuild();
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      _roleSearchController.text = role;
      _showRoleDropdown = false;
    });
    _roleFocusNode.unfocus();
    _hideRoleOverlay();
  }

  void _showRoleOverlay() {
    _hideRoleOverlay();
    _roleOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getRoleFieldWidth(),
        child: CompositedTransformFollower(
          link: _roleLayerLink,
          offset: const Offset(0, 52),
          showWhenUnlinked: false,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: _buildRoleDropdownOverlay(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_roleOverlayEntry!);
    setState(() => _showRoleDropdown = true);
  }

  void _hideRoleOverlay() {
    _roleOverlayEntry?.remove();
    _roleOverlayEntry = null;
    if (mounted) setState(() => _showRoleDropdown = false);
  }

  double _getRoleFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 300;
    // Approximate—full form width minus padding
    return (renderBox.size.width - 64).clamp(200, 500);
  }

  Widget _buildRoleDropdownOverlay() {
    final roles = _filteredRoles;
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: roles.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No roles found',
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                final isSelected = role == _selectedRole;
                return _RoleDropdownItem(
                  role: role,
                  isSelected: isSelected,
                  onTap: () => _selectRole(role),
                );
              },
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a role', style: GoogleFonts.manrope()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        // Update existing user profile and return updated row
        final result = await Supabase.instance.client
            .from('profiles')
            .update({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.userToEdit!['id'])
            .select();

        if (result.isEmpty) {
          // RLS blocked the update — no rows affected
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Permission denied: you may not have rights to update this profile.',
                  style: GoogleFonts.manrope(),
                ),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
          return;
        }
      } else {
        await Supabase.instance.client.from('profiles').insert({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'User updated successfully' : 'User added successfully',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.manrope()),
            backgroundColor: AppTheme.errorRed,
          ),
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
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMobile) ...[
                          _buildTextInput(
                            label: 'Full Name',
                            hint: 'e.g. Robert Smith',
                            icon: Icons.badge_outlined,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 24),
                          _buildTextInput(
                            label: 'Professional Email',
                            hint: 'r.smith@globalgolf.com',
                            icon: Icons.mail_outline,
                            controller: _emailController,
                            isEmail: true,
                          ),
                          const SizedBox(height: 24),
                          _buildRoleSearchField(),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextInput(
                                  label: 'Full Name',
                                  hint: 'e.g. Robert Smith',
                                  icon: Icons.badge_outlined,
                                  controller: _nameController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTextInput(
                                  label: 'Professional Email',
                                  hint: 'r.smith@globalgolf.com',
                                  icon: Icons.mail_outline,
                                  controller: _emailController,
                                  isEmail: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildRoleSearchField(),
                        ],
                        const SizedBox(height: 24),
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
              ),
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
          Expanded(
            child: Row(
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
                      _isEditing ? Icons.edit_outlined : Icons.person_add_outlined,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit User' : 'Add New User',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditing
                            ? 'Modify details for this member'
                            : 'Invite a new member to the Global Golf platform',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.slate500,
                          height: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildTextInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isEmail = false,
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
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required field';
            if (isEmail && !value.contains('@')) return 'Invalid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700),
        ),
        const SizedBox(height: 8),
        _loadingRoles
            ? Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                  ),
                ),
              )
            : CompositedTransformTarget(
                link: _roleLayerLink,
                child: TextFormField(
                  controller: _roleSearchController,
                  focusNode: _roleFocusNode,
                  style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate900),
                  onChanged: (v) {
                    _filterRoles(v);
                    // If user types and clears, reset selection
                    if (v.isEmpty) {
                      setState(() => _selectedRole = null);
                    }
                  },
                  onTap: () {
                    // Select all text for easy replacement
                    _roleSearchController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _roleSearchController.text.length,
                    );
                    _filterRoles('');
                  },
                  decoration: InputDecoration(
                    hintText: 'Search or select a role...',
                    hintStyle: GoogleFonts.manrope(color: AppTheme.slate400),
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.slate400, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedRole != null)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = null;
                                  _roleSearchController.clear();
                                });
                              },
                              child: const Icon(Icons.close, color: AppTheme.slate400, size: 18),
                            ),
                          ),
                        Icon(
                          _showRoleDropdown ? Icons.expand_less : Icons.expand_more,
                          color: AppTheme.slate400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _selectedRole != null
                            ? AppTheme.primaryGreen.withOpacity(0.5)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
                    ),
                  ),
                  validator: (_) {
                    if (_selectedRole == null || _selectedRole!.isEmpty) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing
                  ? "Modifying this user's details will immediately update their access levels across the platform."
                  : "The new user will receive an automated invitation email with login instructions once you click 'Add User'.",
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          // Cancel
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
          // Save / Add
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
                      _isEditing ? 'Save Changes' : 'Add User',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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
//  ROLE DROPDOWN ITEM
// ══════════════════════════════════════════════════════════════
class _RoleDropdownItem extends StatefulWidget {
  final String role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleDropdownItem({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleDropdownItem> createState() => _RoleDropdownItemState();
}

class _RoleDropdownItemState extends State<_RoleDropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _hovered
              ? const Color(0xFFF1F5F9)
              : widget.isSelected
                  ? AppTheme.primaryGreen.withOpacity(0.05)
                  : Colors.white,
          child: Row(
            children: [
              // Role initial badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    widget.role.isNotEmpty ? widget.role[0].toUpperCase() : '?',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected ? AppTheme.primaryGreen : AppTheme.slate500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.role,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected ? AppTheme.primaryGreen : AppTheme.slate900,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
