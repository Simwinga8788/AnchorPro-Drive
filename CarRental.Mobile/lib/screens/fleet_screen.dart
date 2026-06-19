import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/car.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  List<Car> _cars = [];
  bool _loading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedTransmission = 'All';
  String _selectedFuel = 'All';
  double _maxRate = 5000;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cars = await ApiService.getCars();
      if (mounted) {
        setState(() {
          _cars = cars;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load fleet. Pull down to refresh.';
        });
      }
    }
  }

  List<Car> get _filteredCars {
    return _cars.where((car) {
      final query = _searchQuery.toLowerCase();
      final matchSearch = query.isEmpty ||
          '${car.make} ${car.model}'.toLowerCase().contains(query);

      final matchStatus = _selectedStatus == 'All' ||
          car.status.toLowerCase() == _selectedStatus.toLowerCase();

      final matchTrans = _selectedTransmission == 'All' ||
          car.transmission.toLowerCase() == _selectedTransmission.toLowerCase();

      final matchFuel = _selectedFuel == 'All' ||
          car.fuelType.toLowerCase() == _selectedFuel.toLowerCase();

      final matchRate = car.dailyRateZmw <= _maxRate;

      return matchSearch && matchStatus && matchTrans && matchFuel && matchRate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.blue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                        children: const [
                          TextSpan(text: 'Our '),
                          TextSpan(
                            text: 'Fleet',
                            style: TextStyle(color: AppColors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse premium vehicles available across Zambia',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red.withOpacity(0.15)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Search and Filter Button Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search_rounded, color: AppColors.text3, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                  hintText: 'Search make, model...',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.text1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _showFilters ? AppColors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showFilters ? AppColors.blue : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: _showFilters ? Colors.white : AppColors.text2,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filters',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showFilters ? Colors.white : AppColors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Filters Drawer
            if (_showFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilterDropdown(
                          'Status',
                          _selectedStatus,
                          ['All', 'Available', 'Rented', 'In Maintenance', 'Damaged', 'Unavailable'],
                          (val) => setState(() => _selectedStatus = val!),
                        ),
                        const SizedBox(height: 14),
                        _buildFilterDropdown(
                          'Transmission',
                          _selectedTransmission,
                          ['All', 'Automatic', 'Manual'],
                          (val) => setState(() => _selectedTransmission = val!),
                        ),
                        const SizedBox(height: 14),
                        _buildFilterDropdown(
                          'Fuel Type',
                          _selectedFuel,
                          ['All', 'Petrol', 'Diesel', 'Hybrid', 'Electric'],
                          (val) => setState(() => _selectedFuel = val!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Rate',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2),
                            ),
                            Text(
                              'ZMW ${_maxRate.toStringAsFixed(0)}/day',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.blue,
                            thumbColor: AppColors.blue,
                            overlayColor: AppColors.blue.withOpacity(0.12),
                          ),
                          child: Slider(
                            min: 500,
                            max: 5000,
                            divisions: 45,
                            value: _maxRate,
                            onChanged: (val) => setState(() => _maxRate = val),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05, end: 0),
                ),
              ),

            // Results count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Showing ${_filteredCars.length} of ${_cars.length} vehicles',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // Cars grid list
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: _loading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _shimmerCard(),
                        ),
                        childCount: 4,
                      ),
                    )
                  : _filteredCars.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No vehicles match your criteria.',
                                style: GoogleFonts.inter(color: AppColors.text3, fontSize: 13),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final car = _filteredCars[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CarCard(car: car)
                                    .animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1, end: 0),
                              );
                            },
                            childCount: _filteredCars.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
      String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text1),
              items: options.map((o) {
                return DropdownMenuItem<String>(
                  value: o,
                  child: Text(o),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.bg3,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final Car car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/car/${car.id}', extra: car),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    car.primaryImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.bg3,
                      child: const Icon(Icons.directions_car, color: AppColors.text3, size: 48),
                    ),
                  ),
                ),
                // Shuttle Only Badge
                if (car.isShuttleOnly)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6), // Blue badge
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SHUTTLE ONLY',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Available text over image
                if (car.status.toLowerCase() == 'available')
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Text(
                      'AVAILABLE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF22C55E), // Green text
                        letterSpacing: 0.5,
                        shadows: [
                          const Shadow(color: Colors.black38, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _spec(Icons.speed_outlined, car.transmission),
                      const SizedBox(width: 14),
                      _spec(Icons.local_gas_station_outlined, car.fuelType),
                      const SizedBox(width: 14),
                      _spec(Icons.people_outline, '${car.seats} seats'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Pricing
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _priceRow(car.dailyRateZmw, '/day (local)'),
                          if (car.dailyRateOutofTownZmw != null) ...[
                            const SizedBox(height: 8),
                            _priceRow(car.dailyRateOutofTownZmw!, '/day (out-of-town)'),
                          ],
                        ],
                      ),
                      // Action Button
                      if (car.status.toLowerCase() == 'available')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6), // Blue button
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                car.isShuttleOnly ? 'REQUEST' : 'BOOK',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(double amount, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'K${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _spec(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
