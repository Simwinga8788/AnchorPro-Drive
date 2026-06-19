import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/profile.dart';
import '../../models/booking.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final Profile profile;
  const AdminCustomerDetailScreen({super.key, required this.profile});

  @override
  State<AdminCustomerDetailScreen> createState() => _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  late Profile _profile;
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final allBookings = await ApiService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = allBookings.where((b) => b.customerId == _profile.id).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin() async {
    try {
      final updated = await ApiService.updateProfile(_profile.id, {
        ..._profile.toJson(),
        'isAdmin': !_profile.isAdmin,
      });
      setState(() => _profile = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin status updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _toggleSuspend() async {
    try {
      final updated = await ApiService.updateProfile(_profile.id, {
        ..._profile.toJson(),
        'isSuspended': !_profile.isSuspended,
      });
      setState(() => _profile = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suspension status updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to permanently delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteProfile(_profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.blue.withOpacity(0.1),
                    backgroundImage: _profile.avatarUrl != null ? NetworkImage(_profile.avatarUrl!) : null,
                    child: _profile.avatarUrl == null ? Text(_profile.firstName.isNotEmpty ? _profile.firstName[0] : 'U', style: const TextStyle(fontSize: 24, color: AppColors.blue, fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_profile.firstName} ${_profile.lastName}', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text1)),
                        const SizedBox(height: 4),
                        Text(_profile.email ?? 'No email', style: const TextStyle(color: AppColors.text2)),
                        const SizedBox(height: 4),
                        Text(_profile.phoneNumber ?? 'No phone', style: const TextStyle(color: AppColors.text2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleAdmin,
                    icon: const Icon(Icons.shield, size: 16),
                    label: Text(_profile.isAdmin ? 'Remove Admin' : 'Make Admin'),
                    style: ElevatedButton.styleFrom(backgroundColor: _profile.isAdmin ? Colors.orange : AppColors.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleSuspend,
                    icon: const Icon(Icons.block, size: 16),
                    label: Text(_profile.isSuspended ? 'Unsuspend' : 'Suspend'),
                    style: ElevatedButton.styleFrom(backgroundColor: _profile.isSuspended ? Colors.green : Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteProfile,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Profile', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 30),

            const Text('Booking History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? const Text('No bookings found for this customer.', style: TextStyle(color: AppColors.text3))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final b = _bookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('Booking #${b.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${DateFormat('MMM dd').format(DateTime.parse(b.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(b.endDate))}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(b.status, style: TextStyle(fontWeight: FontWeight.bold, color: b.status == 'Completed' ? Colors.green : AppColors.blue)),
                                  Text('ZMW ${b.totalPriceZmw}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
