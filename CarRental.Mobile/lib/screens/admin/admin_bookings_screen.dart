import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await ApiService.getBookings();
      // Sort bookings by createdAt descending
      bookings.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? '') ?? 0);
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await ApiService.updateBookingStatus(bookingId, newStatus);
      _loadBookings(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final startDate = booking.startDate != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.startDate!)) : '';
                  final endDate = booking.endDate != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(booking.endDate!)) : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Booking #${booking.id.substring(0, 8)}', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                            DropdownButton<String>(
                              value: booking.status,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.text2),
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.text1, fontWeight: FontWeight.w600),
                              items: ['Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled'].map((status) {
                                return DropdownMenuItem(value: status, child: Text(status));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null && val != booking.status) {
                                  _updateStatus(booking.id, val);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                            const SizedBox(width: 8),
                            Text('$startDate - $endDate', style: GoogleFonts.inter(fontSize: 14, color: AppColors.text2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: AppColors.text3),
                            const SizedBox(width: 8),
                            Text('ZMW ${booking.totalPriceZmw}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.text2)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.push('/quote/${booking.id}'),
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: const Text('View Invoice/Quote'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.blue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/create-booking');
          if (result == true) {
            _loadBookings();
          }
        },
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
