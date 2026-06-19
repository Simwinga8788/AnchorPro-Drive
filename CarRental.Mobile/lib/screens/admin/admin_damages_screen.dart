import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/damage.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminDamagesScreen extends StatefulWidget {
  const AdminDamagesScreen({super.key});

  @override
  State<AdminDamagesScreen> createState() => _AdminDamagesScreenState();
}

class _AdminDamagesScreenState extends State<AdminDamagesScreen> {
  List<Damage> _damages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDamages();
  }

  Future<void> _loadDamages() async {
    try {
      final damages = await ApiService.getDamages();
      if (mounted) {
        setState(() {
          _damages = damages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load damages: $e')));
      }
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'Minor':
        return Colors.blue;
      case 'Moderate':
        return Colors.orange;
      case 'Major':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Damages Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _damages.isEmpty
              ? const Center(child: Text('No damages found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _damages.length,
                  itemBuilder: (context, index) {
                    final damage = _damages[index];
                    final date = damage.createdAt != null ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(damage.createdAt!)) : 'Unknown Date';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Car ID: ${damage.carId.substring(0, 8)}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getSeverityColor(damage.severity).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      damage.severity ?? 'Unknown',
                                      style: TextStyle(color: _getSeverityColor(damage.severity), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(damage.repairStatus).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      damage.repairStatus ?? 'Pending',
                                      style: TextStyle(color: _getStatusColor(damage.repairStatus), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (damage.bookingId != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.bookmark, size: 16, color: AppColors.text3),
                                const SizedBox(width: 8),
                                Text('Booking: ${damage.bookingId!.substring(0, 8)}', style: const TextStyle(color: AppColors.text2)),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description, size: 16, color: AppColors.text3),
                              const SizedBox(width: 8),
                              Expanded(child: Text(damage.description, style: const TextStyle(color: AppColors.text2))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                              const SizedBox(width: 8),
                              Text('Reported: $date', style: const TextStyle(color: AppColors.text2)),
                            ],
                          ),
                          if (damage.imageUrls != null && damage.imageUrls!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: damage.imageUrls!.length,
                                itemBuilder: (context, i) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(damage.imageUrls![i]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Est. Cost:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2)),
                              Text(
                                damage.repairCostEstimate != null ? 'ZMW ${damage.repairCostEstimate!.toStringAsFixed(2)}' : 'TBD',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/create-damage');
          if (result == true) {
            _loadDamages();
          }
        },
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
