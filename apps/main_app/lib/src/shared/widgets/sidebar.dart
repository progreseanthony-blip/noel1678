import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final String currentPath;
  final double? width;

  const Sidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.currentPath,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Icon(Icons.golf_course, color: Colors.white, size: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Golf', style: GoogleFonts.manrope(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                    Text('CONSTRUCTION', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2.5)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.group_outlined, 
                    label: 'User Management', 
                    isActive: currentPath.startsWith('/users') || currentPath == '/', 
                    onTap: () => context.go('/users')
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.request_quote_rounded, 
                    label: 'Estimates', 
                    isActive: currentPath.startsWith('/quotes'), 
                    onTap: () => context.go('/quotes')
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.rocket_launch_outlined, 
                    label: 'Projects', 
                    isActive: currentPath.startsWith('/projects'), 
                    onTap: () => context.go('/projects')
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.person_search_outlined, 
                    label: 'Customers', 
                    isActive: currentPath.startsWith('/customers'), 
                    onTap: () => context.go('/customers')
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.folder_copy_outlined, 
                    label: 'Catalogs', 
                    isActive: currentPath.startsWith('/catalogs'), 
                    onTap: () => context.go('/catalogs')
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.engineering_outlined, 
                    label: 'Workers', 
                    isActive: currentPath.startsWith('/workers'), 
                    onTap: () => context.go('/workers')
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Column(
              children: [
                _NavItem(icon: Icons.settings_outlined, label: 'Settings', isActive: false, onTap: () {}),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGreen.withOpacity(0.15), border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25))),
                        child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                            Text(userEmail, style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onLogout,
                          child: const Icon(Icons.logout, color: AppTheme.slate400, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, 
    required this.label, 
    required this.isActive, 
    required this.onTap
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppTheme.primaryGreen : (_isHovered ? Colors.white : AppTheme.slate400);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive ? AppTheme.primaryGreen.withOpacity(0.1) : (_isHovered ? Colors.white.withOpacity(0.03) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                widget.label, 
                style: GoogleFonts.manrope(
                  color: color, 
                  fontSize: 14, 
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
