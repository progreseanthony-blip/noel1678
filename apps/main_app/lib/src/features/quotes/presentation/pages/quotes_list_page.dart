import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import '../widgets/quote_form_dialog.dart';

class QuotesListPage extends ConsumerStatefulWidget {
  const QuotesListPage({super.key});

  @override
  ConsumerState<QuotesListPage> createState() => _QuotesListPageState();
}

class _QuotesListPageState extends ConsumerState<QuotesListPage> {
  List<Map<String, dynamic>>? _quotes;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 10;
  
  // Mobile filter state
  String _mobileFilter = 'all'; // 'all', 'draft', 'sent', 'accepted'
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final response = await Supabase.instance.client
          .from('quotes')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _quotes = List<Map<String, dynamic>>.from(response ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredQuotes {
    if (_quotes == null) return [];
    var base = _quotes!;
    
    if (_mobileFilter != 'all') {
      base = base.where((q) => (q['status'] ?? '').toString().toLowerCase() == _mobileFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((u) {
        final title = (u['title'] ?? '').toString().toLowerCase();
        final id = (u['id'] ?? '').toString().toLowerCase();
        return title.contains(q) || id.contains(q);
      }).toList();
    }
    return base;
  }

  List<Map<String, dynamic>> get _paginatedQuotes {
    final filtered = _filteredQuotes;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredQuotes.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileLayout(userName, userEmail);
    }
    return _buildDesktopLayout(userName, userEmail);
  }

  // ══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          _Sidebar(
            userName: userName,
            userEmail: userEmail,
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                _TopHeader(userName: userName),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? _buildErrorState()
                          : _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: _Sidebar(
          userName: userName,
          userEmail: userEmail,
          onLogout: () async {
            Navigator.of(context).pop();
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ),
      body: Column(
        children: [
          _buildMobileHeader(userName),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                : _error != null
                    ? _buildErrorState()
                    : _buildMobileContent(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showQuoteForm(),
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.slate200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               _buildBottomNavItem(Icons.group_outlined, 'Users', false, () => context.go('/users')),
               _buildBottomNavItem(Icons.request_quote, 'Quotes', true, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(String userName) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.sports_golf, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Global Golf',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.slate200,
              border: Border.all(color: AppTheme.primaryGreen.withAlpha(50)),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? AppTheme.primaryGreen : AppTheme.slate400),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isActive ? AppTheme.primaryGreen : AppTheme.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent() {
    final items = _paginatedQuotes;
    final total = _quotes?.length ?? 0;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),
        Text(
          'Quotes Management',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.slate900,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterTab('All ($total)', 'all'),
              const SizedBox(width: 8),
              _buildFilterTab('Draft', 'draft'),
              const SizedBox(width: 8),
              _buildFilterTab('Sent', 'sent'),
              const SizedBox(width: 8),
              _buildFilterTab('Accepted', 'accepted'),
              const SizedBox(width: 8),
              _buildFilterTab('Rejected', 'rejected'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text("No quotes found.")),
          )
        else
          ...items.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileCard(q),
          )),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _mobileFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _mobileFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isSelected ? null : Border.all(color: AppTheme.slate200),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> quote) {
    final title = quote['title'] ?? 'Sin Titulo';
    final status = quote['status'] ?? 'draft';
    final date = quote['created_at'] != null 
      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(quote['created_at']))
      : '-';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/quotes/${quote['id']}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
                  _buildStatusBadge(status),
                ],
              ),
              Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(quote['client_name'] ?? 'No client', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700, fontWeight: FontWeight.w600)),
                       const SizedBox(height: 2),
                       Text('\$${NumberFormat('#,##0.00', 'en_US').format(quote['total_amount'] ?? 0)}', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                     ],
                   ),
                   GestureDetector(
                    onTap: () => _showQuoteForm(quote),
                    child: Row(
                     children: [
                        Icon(Icons.edit, size: 16, color: AppTheme.slate400),
                        const SizedBox(width: 8),
                        Text('Edit Quote', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
                     ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  DESKTOP MAIN CONTENT
  // ══════════════════════════════════════════════════════════════
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quotes Management',
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create, manage and track your job proposals directly here.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppTheme.slate500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showQuoteForm(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF0F172A), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Create Quote',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchFilters(),
          const SizedBox(height: 24),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by title...',
                  hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.slate400, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final items = _paginatedQuotes;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(flex: 25, child: _colHeader('TITLE')),
                Expanded(flex: 20, child: _colHeader('CLIENT')),
                Expanded(flex: 20, child: _colHeader('CREATED DATE')),
                Expanded(flex: 15, child: _colHeader('TOTAL')),
                Expanded(flex: 12, child: _colHeader('STATUS')),
                Expanded(flex: 8, child: _colHeader('ACTIONS')),
              ],
            ),
          ),
          if (items.isEmpty)
             const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No quotes found")))
          else
            ...items.map((q) => _buildTableRow(q)),
            
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${items.isEmpty ? 0 : (_currentPage - 1) * _pageSize + 1}-${(_currentPage - 1) * _pageSize + items.length} of ${_filteredQuotes.length} results',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _buildPageButton(Icons.chevron_left, _currentPage > 1 ? () {
                      setState(() => _currentPage--);
                    } : null),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currentPage',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPageButton(Icons.chevron_right, _currentPage < _totalPages ? () {
                      setState(() => _currentPage++);
                    } : null),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppTheme.slate500,
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> quote) {
    final title = quote['title'] ?? 'N/A';
    final status = quote['status'] ?? 'draft';
    final date = quote['created_at'] != null 
      ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(quote['created_at']).toLocal())
      : '-';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/quotes/${quote['id']}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(flex: 25, child: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900))),
              Expanded(flex: 20, child: Text(quote['client_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700))),
              Expanded(flex: 20, child: Text(date, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500))),
              Expanded(flex: 15, child: Text('\$${NumberFormat('#,##0.00', 'en_US').format(quote['total_amount'] ?? 0)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen))),
              Expanded(flex: 12, child: _buildStatusBadge(status)),
              Expanded(flex: 8, child: Align(alignment: Alignment.centerLeft, child: Row(mainAxisSize: MainAxisSize.min, children: [_editIconButton(quote), const SizedBox(width: 6), _deleteIconButton(quote)]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editIconButton(Map<String, dynamic> quote) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showQuoteForm(quote),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.slate500),
        ),
      ),
    );
  }

  Widget _deleteIconButton(Map<String, dynamic> quote) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _confirmDeleteQuote(quote),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch(status.toLowerCase()) {
      case 'accepted': bg = AppTheme.primaryGreen.withOpacity(0.1); text = AppTheme.primaryGreen; break;
      case 'sent': bg = Colors.blue.withOpacity(0.1); text = Colors.blue; break;
      case 'rejected': bg = AppTheme.errorRed.withOpacity(0.1); text = AppTheme.errorRed; break;
      default: bg = AppTheme.slate200; text = AppTheme.slate700; break;
    }
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onTap) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Icon(icon, size: 16, color: onTap != null ? AppTheme.slate700 : AppTheme.slate400),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteQuote(Map<String, dynamic> quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 24),
            const SizedBox(width: 10),
            Text('Delete Quote', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${quote['title']}"?\n\nThis will permanently remove all services, machinery, and labor data associated with this quote.',
          style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('quotes').delete().eq('id', quote['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quote deleted successfully', style: GoogleFonts.manrope(color: Colors.white)), backgroundColor: AppTheme.primaryGreen),
          );
          _loadQuotes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  void _showQuoteForm([Map<String, dynamic>? quote]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => QuoteFormDialog(quoteToEdit: quote),
    ).then((updated) {
      if (updated == true) {
        _loadQuotes();
      }
    });
  }

  Widget _buildErrorState() {
    return Center(child: Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red)));
  }
}

// ══════════════════════════════════════════════════════════════
//  SIDEBAR
// ══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final double? width;

  const _Sidebar({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
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
                  _NavItem(icon: Icons.group_outlined, label: 'User Management', isActive: false, onTap: () => context.go('/users')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.request_quote_rounded, label: 'Quotes', isActive: true, onTap: () => context.go('/quotes')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.folder_copy_outlined, label: 'Catalogs', isActive: false, onTap: () => context.go('/catalogs')),
                  const SizedBox(height: 4),
                  _NavItem(icon: Icons.engineering_outlined, label: 'Workers', isActive: false, onTap: () => context.go('/workers')),
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
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});
  @override State<_NavItem> createState() => _NavItemState();
}
class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;
  @override Widget build(BuildContext context) {
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
              Text(widget.label, style: GoogleFonts.manrope(color: color, fontSize: 14, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOP HEADER (Desktop)
// ══════════════════════════════════════════════════════════════
class _TopHeader extends StatelessWidget {
  final String userName;
  const _TopHeader({required this.userName});
  @override Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.slate200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Administration', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500, fontWeight: FontWeight.w500)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.chevron_right, size: 16, color: AppTheme.slate400),
              ),
              Text('Quotes', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900, fontWeight: FontWeight.w700)),
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
                decoration: BoxDecoration(color: AppTheme.slate200, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))),
                child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate700))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
