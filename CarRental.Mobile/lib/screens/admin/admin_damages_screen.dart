import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/damage.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminDamagesScreen extends StatefulWidget {
  const AdminDamagesScreen({super.key});

  @override
  State<AdminDamagesScreen> createState() => _AdminDamagesScreenState();
}

class _AdminDamagesScreenState extends State<AdminDamagesScreen> {
  List<Damage> _damages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDamages();
  }

  Future<void> _loadDamages() async {
    setState(() => _isLoading = true);
    try {
      final damages = await ApiService.getDamages();
      if (mounted) {
        setState(() {
          _damages = damages;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load damages: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'Minor':
        return const Color(0xFF2563EB); // blue
      case 'Moderate':
        return const Color(0xFFD97706); // amber
      case 'Major':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF059669); // green
      case 'In Progress':
        return const Color(0xFF2563EB); // blue
      case 'Pending':
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

    final filteredDamages = _damages.where((d) {
      final query = _searchQuery.toLowerCase();
      final vehicleName = d.car != null ? '${d.car!.make} ${d.car!.model}'.toLowerCase() : '';
      return vehicleName.contains(query) || d.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Damages Management',
          style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDamages,
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
                hintText: 'Search by vehicle or description...',
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
                : filteredDamages.isEmpty
                    ? Center(
                        child: Text(
                          'No damages found',
                          style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDamages,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDamages.length,
                          itemBuilder: (context, index) {
                            final damage = filteredDamages[index];
                            final date = damage.createdAt != null
                                ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(damage.createdAt!))
                                : 'Unknown Date';

                            final vehicleName = damage.car != null
                                ? '${damage.car!.make} ${damage.car!.model}'
                                : 'Car ID: ${damage.carId.substring(0, 8)}';

                            final customerName = damage.booking?.customer != null
                                ? '${damage.booking!.customer!.firstName} ${damage.booking!.customer!.lastName}'
                                : (damage.bookingId != null ? 'Booking: #${damage.bookingId!.substring(0, 8)}' : 'Reported By: Admin');

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
                                        Expanded(
                                          child: Text(
                                            vehicleName,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: const Color(0xFF1F2937),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            // Severity Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getSeverityColor(damage.severity).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (damage.severity ?? 'Minor').toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  color: _getSeverityColor(damage.severity),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Repair Status Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(damage.repairStatus).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (damage.repairStatus ?? 'Pending').toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  color: _getStatusColor(damage.repairStatus),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                    const SizedBox(height: 16),
                                    
                                    // Customer / Booking Info
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 8),
                                        Text(customerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Description
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.description_outlined, size: 16, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(damage.description, style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13))),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Date
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 8),
                                        Text('Reported: $date', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
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
                                                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                    
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Est. Repair Cost', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), fontSize: 14)),
                                        Text(
                                          damage.repairCostEstimate != null ? currencyFormat.format(damage.repairCostEstimate!) : 'TBD',
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/admin/create-damage');
          if (result == true) {
            _loadDamages();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

