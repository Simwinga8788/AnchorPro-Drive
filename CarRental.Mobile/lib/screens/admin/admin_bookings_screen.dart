import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await ApiService.getBookings();
      // Sort bookings by createdAt descending
      bookings.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? '') ?? 0);
      if (mounted) {
        setState(() {
          _bookings = bookings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load bookings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await ApiService.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Status updated to $newStatus')));
      }
      _loadBookings(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _bookings.where((b) {
      final query = _searchQuery.toLowerCase();
      final customerName = b.customer != null
          ? '${b.customer!.firstName} ${b.customer!.lastName}'.toLowerCase()
          : '';
      final carModel = b.car != null
          ? '${b.car!.make} ${b.car!.model}'.toLowerCase()
          : '';
      return b.id.toLowerCase().contains(query) ||
             customerName.contains(query) ||
             carModel.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: GoogleFonts.inter(
              color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
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
                hintText: 'Search by ID, customer, or vehicle...',
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
                : filteredBookings.isEmpty
                    ? Center(
                        child: Text(
                          'No bookings found',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280), fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            return _buildBookingCard(filteredBookings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/create-booking');
          if (result == true) {
            _loadBookings();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);
    final startDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.startDate));
    final endDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.endDate));

    final customerName = booking.customer != null
        ? '${booking.customer!.firstName} ${booking.customer!.lastName}'
        : 'Customer ID: ${booking.customerId.substring(0, 8)}';

    final vehicleName = booking.car != null
        ? '${booking.car!.make} ${booking.car!.model}'
        : 'Car ID: ${booking.carId.substring(0, 8)}';

    final isOutTown = booking.isOutofTown ?? false;

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
                  '#${booking.id.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                _buildStatusDropdown(booking),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),

            _buildDetailRow(Icons.person_outline, customerName),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.directions_car_outlined, vehicleName),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today_outlined, '$startDate - $endDate'),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(booking.totalPriceZmw),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutTown ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOutTown ? 'OUT OF TOWN' : 'LOCAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOutTown ? const Color(0xFF1D4ED8) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (booking.paymentStatus == 'Paid' || booking.paymentStatus == 'Completed')
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PAYMENT: ${booking.paymentStatus.toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (booking.paymentStatus == 'Paid' || booking.paymentStatus == 'Completed')
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/quote/${booking.id}'),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Invoice'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(Booking booking) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'Confirmed': return const Color(0xFF059669);
        case 'Active': return const Color(0xFF2563EB);
        case 'Completed': return const Color(0xFF4B5563);
        case 'Cancelled': return const Color(0xFFDC2626);
        default: return const Color(0xFFD97706);
      }
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: booking.status,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4B5563)),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: getStatusColor(booking.status),
          ),
          items: ['Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled']
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: getStatusColor(status)),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null && val != booking.status) {
              _updateStatus(booking.id, val);
            }
          },
        ),
      ),
    );
  }
}
