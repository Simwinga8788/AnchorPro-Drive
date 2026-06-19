import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/payment.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<Payment> _payments = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  int _activeTab = 0; // 0 = All, 1 = Completed, 2 = Pending / Due
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getPayments(),
        ApiService.getBookings(),
      ]);
      final payments = results[0] as List<Payment>;
      final bookings = results[1] as List<Booking>;

      // Sort payments by createdAt descending
      payments.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      if (mounted) {
        setState(() {
          _payments = payments;
          _bookings = bookings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load payments: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Payment> get _filteredPayments {
    List<Payment> filtered = _payments;
    
    if (_activeTab == 1) {
      filtered = _payments.where((p) => p.status == 'Completed').toList();
    } else if (_activeTab == 2) {
      filtered = _payments.where((p) => p.status == 'Pending' || p.status == 'Due' || p.status == 'Failed').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final customerName = p.profile != null
            ? '${p.profile!.firstName} ${p.profile!.lastName}'.toLowerCase()
            : '';
        return (p.reference?.toLowerCase().contains(query) ?? false) ||
               p.bookingId.toLowerCase().contains(query) ||
               customerName.contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildMetricCard(String title, double amount, Color color, IconData icon) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);
    
    // Calculate metrics
    final double collected = _payments
        .where((p) => p.status == 'Completed')
        .fold(0.0, (sum, p) => sum + p.amountZmw);
    
    final double bookingTotal = _bookings
        .where((b) => b.status != 'Cancelled')
        .fold(0.0, (sum, b) => sum + b.totalPriceZmw);
    
    final double outstanding = bookingTotal > collected ? bookingTotal - collected : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Payments Management',
          style: GoogleFonts.inter(
              color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by reference, booking, or customer...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            _buildMetricCard('Total Collected', collected, const Color(0xFF059669), Icons.check_circle_outline),
                            const SizedBox(width: 16),
                            _buildMetricCard('Outstanding Due', outstanding, const Color(0xFFDC2626), Icons.hourglass_empty),
                          ],
                        ),
                      ),
                      // Filter Tabs
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            _buildTabButton(0, 'All'),
                            const SizedBox(width: 8),
                            _buildTabButton(1, 'Completed'),
                            const SizedBox(width: 8),
                            _buildTabButton(2, 'Pending / Due'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filteredPayments.isEmpty
                            ? Center(
                                child: Text(
                                  'No payments found',
                                  style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 16),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadPayments,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _filteredPayments.length,
                                  itemBuilder: (context, index) {
                                    final payment = _filteredPayments[index];
                                    final date = payment.createdAt != null
                                        ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(payment.createdAt!))
                                        : 'Unknown Date';

                                    final customerName = payment.profile != null
                                        ? '${payment.profile!.firstName} ${payment.profile!.lastName}'
                                        : 'Unknown Customer';

                                    final shortRef = payment.reference != null && payment.reference!.isNotEmpty
                                        ? payment.reference!
                                        : payment.id.substring(0, 8);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  shortRef,
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: const Color(0xFF1F2937),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: payment.status == 'Completed'
                                                        ? const Color(0xFFD1FAE5)
                                                        : const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    payment.status.toUpperCase(),
                                                    style: GoogleFonts.inter(
                                                      color: payment.status == 'Completed'
                                                          ? const Color(0xFF059669)
                                                          : const Color(0xFFD97706),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                            const SizedBox(height: 16),
                                            
                                            // Customer Details
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                                                const SizedBox(width: 8),
                                                Text(customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Booking Details
                                            Row(
                                              children: [
                                                const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF6B7280)),
                                                const SizedBox(width: 8),
                                                Text('Booking #${payment.bookingId.substring(0, 8)}', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Method & Type
                                            Row(
                                              children: [
                                                const Icon(Icons.payment_outlined, size: 16, color: Color(0xFF6B7280)),
                                                const SizedBox(width: 8),
                                                Text('Method: ${payment.method}  •  Type: ${payment.type}', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Date
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                                                const SizedBox(width: 8),
                                                Text(date, style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Amount Paid', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), fontSize: 14)),
                                                Text(
                                                  currencyFormat.format(payment.amountZmw),
                                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/create-payment');
          if (result == true) {
            _loadPayments();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

