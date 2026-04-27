import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class TopHeader extends StatelessWidget {
  final String userName;
  final List<String> breadcrumbs;

  const TopHeader({
    super.key,
    required this.userName,
    required this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(bottom: BorderSide(color: AppTheme.slate200))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              for (int i = 0; i < breadcrumbs.length; i++) ...[
                Text(
                  breadcrumbs[i],
                  style: GoogleFonts.manrope(
                    fontSize: 13, 
                    color: i == breadcrumbs.length - 1 ? AppTheme.slate900 : AppTheme.slate500, 
                    fontWeight: i == breadcrumbs.length - 1 ? FontWeight.w700 : FontWeight.w500
                  ),
                ),
                if (i < breadcrumbs.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
                  ),
              ],
            ],
          ),
          Row(
            children: [
              Icon(Icons.notifications_none, color: AppTheme.slate500),
              const SizedBox(width: 24),
              Container(width: 1, height: 24, color: AppTheme.slate200),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(userName, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                  Text('Active User', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate500)),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.slate200, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?', 
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700)
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
