import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/change_order_providers.dart';
import '../../../../shared/widgets/sidebar.dart';

class ChangeOrdersListPage extends ConsumerStatefulWidget {
  final String projectId;

  const ChangeOrdersListPage({super.key, required this.projectId});

  @override
  ConsumerState<ChangeOrdersListPage> createState() => _ChangeOrdersListPageState();
}

class _ChangeOrdersListPageState extends ConsumerState<ChangeOrdersListPage> {
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    final cosAsync = ref.watch(changeOrderListProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/change-orders', onLogout: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/signin');
      }) : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(userName: userName, userEmail: userEmail, currentPath: '/projects/${widget.projectId}/change-orders', onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            }),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(child: _buildContent(cosAsync, isMobile)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String userName, bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: Row(
        children: [
          if (isMobile)
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.slate700),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/projects/${widget.projectId}'),
              child: const Icon(Icons.arrow_back, size: 18, color: AppTheme.slate500),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text('Project', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w500)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
            ),
            Flexible(
              child: Text('Change Orders', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go('/projects/${widget.projectId}/change-orders/new'),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text('New Change Order', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncValue<List<Map<String, dynamic>>> cosAsync, bool isMobile) {
    return cosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (cos) {
        if (cos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horizontal_circle_outlined, size: 64, color: AppTheme.slate200),
                const SizedBox(height: 16),
                Text('No Change Orders yet', style: GoogleFonts.manrope(fontSize: 16, color: AppTheme.slate500)),
                const SizedBox(height: 8),
                Text('Create a Change Order to modify the contract', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cos.length} Change Order${cos.length != 1 ? 's' : ''}',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
              const SizedBox(height: 16),
              if (isMobile)
                Column(children: cos.map((co) => _coCard(co)).toList())
              else
                _coTable(cos),
            ],
          ),
        );
      },
    );
  }

  Widget _coCard(Map<String, dynamic> co) {
    final adj = (co['adjustment_amount'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: InkWell(
        onTap: () => context.go('/projects/${widget.projectId}/change-orders/${co['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(co['co_number'] ?? '', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate900))),
                _statusBadge(co['status']?.toString() ?? 'draft'),
              ],
            ),
            const SizedBox(height: 4),
            Text(co['title'] ?? '', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
            const SizedBox(height: 8),
            Text('Adjustment: \$${_fmt.format(adj)}', style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: adj >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
            )),
          ],
        ),
      ),
    );
  }

  Widget _coTable(List<Map<String, dynamic>> cos) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingRowHeight: 44,
            columns: [
              const DataColumn(label: Text('CO #', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              const DataColumn(label: Text('Adjustment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), numeric: true),
              const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              const DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
            ],
            rows: cos.map((co) {
              final adj = (co['adjustment_amount'] as num?)?.toDouble() ?? 0;
              return DataRow(
                onSelectChanged: (_) => context.go('/projects/${widget.projectId}/change-orders/${co['id']}'),
                cells: [
                  DataCell(Text(co['co_number'] ?? '', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataCell(Text(co['title'] ?? '', style: GoogleFonts.manrope(fontSize: 12))),
                  DataCell(_statusBadge(co['status']?.toString() ?? 'draft')),
                  DataCell(Text('\$${_fmt.format(adj)}', style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: adj >= 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
                  ))),
                  DataCell(Text(co['executed_date']?.toString() ?? '', style: GoogleFonts.manrope(fontSize: 11))),
                  DataCell(Icon(Icons.chevron_right, size: 18, color: AppTheme.slate400)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.primaryGreen;
        break;
      case 'rejected':
        color = AppTheme.errorRed;
        break;
      case 'submitted':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = AppTheme.slate400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
      child: Text(status.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
