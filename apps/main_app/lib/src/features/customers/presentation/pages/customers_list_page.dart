import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/customer_form_dialog.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  List<Map<String, dynamic>>? _customers;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 10;
  
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await ref.read(customersServiceProvider).getCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_customers == null) return [];
    if (_searchQuery.isEmpty) return _customers!;
    final q = _searchQuery.toLowerCase();
    return _customers!.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final ein = (c['ein'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || ein.contains(q) || email.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedCustomers {
    final filtered = _filteredCustomers;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredCustomers.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250; // Using the same breakpoint as quotes

    if (isMobile) {
      return _buildMobileLayout(userName, userEmail);
    }
    return _buildDesktopLayout(userName, userEmail);
  }

  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/customers',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Administration', 'Customers']),
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

  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/customers',
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
          onPressed: () => _showCustomerForm(),
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.person_add, color: Color(0xFF0F172A), size: 28),
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
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Customers',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const Spacer(),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.slate200),
            child: Center(
              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Management',
                    style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create and manage your client database for quotes and projects.',
                    style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.slate500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCustomerForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      child: TextField(
        onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
        decoration: InputDecoration(
          hintText: 'Search by name, EIN or email...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.slate400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final items = _paginatedCustomers;
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
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              children: [
                Expanded(flex: 30, child: _colHeader('NAME')),
                Expanded(flex: 15, child: _colHeader('EIN')),
                Expanded(flex: 25, child: _colHeader('EMAIL')),
                Expanded(flex: 20, child: _colHeader('PHONE')),
                Expanded(flex: 10, child: _colHeader('ACTIONS')),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No customers found")))
          else
            ...items.map((c) => _buildTableRow(c)),
        ],
      ),
    );
  }

  Widget _colHeader(String title) {
    return Text(title, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 0.5));
  }

  Widget _buildTableRow(Map<String, dynamic> c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(flex: 30, child: Text(c['name'] ?? '', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900))),
          Expanded(flex: 15, child: Text(c['ein'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700))),
          Expanded(flex: 25, child: Text(c['email'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700))),
          Expanded(flex: 20, child: Text(c['phone'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700))),
          Expanded(flex: 10, child: Row(
            children: [
              IconButton(onPressed: () => _showCustomerForm(c), icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.slate500)),
              IconButton(onPressed: () => _confirmDelete(c), icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    final items = _paginatedCustomers;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final c = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${c['ein'] ?? ''}\n${c['email'] ?? ''}'),
            trailing: IconButton(onPressed: () => _showCustomerForm(c), icon: const Icon(Icons.edit)),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(child: Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red)));
  }

  void _showCustomerForm([Map<String, dynamic>? customer]) {
    showSafeDialog(
      context: context,
      builder: (context) => CustomerFormDialog(customerToEdit: customer),
    ).then((updated) {
      if (updated == true) _loadCustomers();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> customer) async {
    final confirmed = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(customersServiceProvider).deleteCustomer(customer['id']);
        _loadCustomers();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
