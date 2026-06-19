import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../theme.dart';
import 'package:go_router/go_router.dart';

class AdminFleetScreen extends StatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen> {
  List<Car> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final cars = await ApiService.getCars();
      if (mounted) {
        setState(() {
          _cars = cars;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(Car car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vehicle', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${car.make} ${car.model}?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: AppColors.text2)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('Delete', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.apiService.deleteCar(carId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle deleted successfully')));
        _fetchCars();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete vehicle: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCars = _cars.where((car) =>
        car.make.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        car.model.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Fleet Management',
          style: GoogleFonts.inter(
              color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCars,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add vehicle coming soon.')));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search fleet...',
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
                : filteredCars.isEmpty
                    ? Center(
                        child: Text(
                          'No vehicles found',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280), fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCars,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCars.length,
                          itemBuilder: (context, index) {
                            final car = filteredCars[index];
                            return _buildCarCard(car);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);
    final isShuttle = car.isShuttleOnly;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: car.imageUrls != null && car.imageUrls!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(car.imageUrls!.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: car.imageUrls == null || car.imageUrls!.isEmpty
                ? const Center(
                    child: Icon(Icons.directions_car, size: 64, color: Color(0xFF9CA3AF)),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${car.make} ${car.model}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    _buildStatusBadge(car.status),
                  ],
                ),
                
                if (isShuttle)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SHUTTLE ONLY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildFeatureChip(Icons.calendar_today, car.year.toString()),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.settings, car.transmission ?? 'Auto'),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.local_gas_station, car.fuelType ?? 'Petrol'),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.people, '${car.seats ?? 4}'),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.bg2,
                            image: (car.imageUrls != null && car.imageUrls!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(car.imageUrls!.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (car.imageUrls == null || car.imageUrls!.isEmpty)
                              ? const Icon(Icons.directions_car, color: AppColors.text3, size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${car.make} ${car.model}', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                              if (car.isShuttleOnly) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'SHUTTLE ONLY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${car.transmission}  •  ${car.fuelType}  •  ${car.seats} seats',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'K${NumberFormat('#,##0.00').format(car.dailyRateZmw)} ',
                                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColors.blue, fontSize: 13),
                                    ),
                                    TextSpan(text: 'local', style: GoogleFonts.inter(color: AppColors.text3, fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (car.dailyRateOutofTownZmw != null) ...[
                                const SizedBox(height: 2),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'K${NumberFormat('#,##0.00').format(car.dailyRateOutofTownZmw!)} ',
                                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColors.blue2, fontSize: 13),
                                      ),
                                      TextSpan(text: 'out of town', style: GoogleFonts.inter(color: AppColors.text3, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: car.status == 'Available' ? AppColors.green.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  car.status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: car.status == 'Available' ? AppColors.green : AppColors.red,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.blue),
                              onPressed: () async {
                                final result = await context.push('/admin/create-car', extra: car);
                                if (result == true) _loadCars();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.red),
                              onPressed: () => _confirmDelete(car),
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
        backgroundColor: AppColors.blue,
        onPressed: () async {
          final result = await context.push('/admin/create-car');
          if (result == true) _loadCars();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
