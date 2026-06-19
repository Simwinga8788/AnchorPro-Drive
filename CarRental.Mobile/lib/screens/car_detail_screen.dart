import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/car.dart';
import '../models/location.dart';

class CarDetailScreen extends StatefulWidget {
  final String carId;
  const CarDetailScreen({super.key, required this.carId});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  Car? _car;
  List<Location> _locations = [];
  bool _loading = true;
  String? _errorMessage;

  DateTimeRange? _selectedRange;
  int _days = 0;
  String? _pickupLocId;
  String? _dropoffLocId;
  String _paymentMethod = 'Pay Later';
  bool _isOutofTown = false;
  bool _bookingInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadCarAndLocations();
  }

  Future<void> _loadCarAndLocations() async {
    try {
      final cars = await ApiService.getCars();
      final locations = await ApiService.getLocations();
      final car = cars.firstWhere((c) => c.id == widget.carId);
      
      if (mounted) {
        setState(() {
          _car = car;
          _locations = locations;
          _loading = false;
          
          // Default locations
          if (car.locationId != null) {
            _pickupLocId = car.locationId;
            _dropoffLocId = car.locationId;
          } else if (locations.isNotEmpty) {
            _pickupLocId = locations.first.id;
            _dropoffLocId = locations.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load vehicle details. Please try again.';
        });
      }
    }
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blue),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _selectedRange = range;
        _days = range.end.difference(range.start).inDays;
        if (_days < 1) _days = 1;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates first')),
      );
      return;
    }
    if (_pickupLocId == null || _dropoffLocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    setState(() => _bookingInProgress = true);

    try {
      final formattedStart = _selectedRange!.start.toIso8601String().split('T').first;
      final formattedEnd = _selectedRange!.end.toIso8601String().split('T').first;

      final car = _car!;
      final activeRate = (_isOutofTown && car.dailyRateOutofTownZmw != null)
          ? car.dailyRateOutofTownZmw!
          : car.dailyRateZmw;
      final totalCost = _days * activeRate;

      await ApiService.checkoutBooking(
        carId: widget.carId,
        startDate: formattedStart,
        endDate: formattedEnd,
        pickupLocationId: _pickupLocId!,
        dropoffLocationId: _dropoffLocId!,
        paymentMethod: _paymentMethod,
        totalPriceZmw: totalCost,
        isOutofTown: _isOutofTown,
      );

      if (mounted) {
        setState(() => _bookingInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _bookingInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    final car = _car;
    if (car == null || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Car not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCarAndLocations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final activeRate = (_isOutofTown && car.dailyRateOutofTownZmw != null)
        ? car.dailyRateOutofTownZmw!
        : car.dailyRateZmw;
    final totalCost = _days * activeRate;

    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero image app bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.bg,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.text1),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    car.primaryImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: AppColors.border,
                        highlightColor: AppColors.bg3,
                        child: Container(color: AppColors.bg),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.bg3,
                      child: const Icon(Icons.directions_car, color: AppColors.text3, size: 64),
                    ),
                  ),
                ),
              ),

              // Car info
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.bg2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    // Custom category mapping heuristic
                                    child: Text(
                                      car.seats >= 7 ? 'SUV' : 'Sedan',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${car.make} ${car.model}', style: GoogleFonts.spaceGrotesk(
                                    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text1,
                                  )),
                                  Text(car.year != null ? '${car.year}' : 'Recent Model', style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.text3,
                                  )),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('ZMW ${activeRate.toStringAsFixed(0)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.blue,
                                  )),
                                Text('per day', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),

                        const SizedBox(height: 20),

                        // Spec chips
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: [
                            _specChip(Icons.people_outline, '${car.seats} Seats'),
                            _specChip(Icons.settings_outlined, car.transmission),
                            _specChip(Icons.local_gas_station_outlined, car.fuelType),
                            _specChip(Icons.check_circle_outline,
                              car.available ? 'Available' : 'Unavailable',
                              color: car.available ? AppColors.green : AppColors.red,
                            ),
                          ],
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 24),

                        // Description
                        Text('About this car', style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1,
                        )),
                        const SizedBox(height: 8),
                        Text(
                          car.features != null && car.features!.isNotEmpty
                              ? 'This premium vehicle features ${car.features!.join(", ")} and is kept in excellent condition.'
                              : 'A premium, comfortable vehicle perfect for business or leisure travels.',
                          style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.text2, height: 1.7,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        if (car.isShuttleOnly) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.blue.withOpacity(0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blue.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.airport_shuttle_outlined, color: AppColors.blue, size: 30),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Shuttle Service Only',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'This ${car.make} ${car.model} is reserved exclusively for our premium chauffeur and shuttle services. Pricing is determined by your specific route and requirements.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.text2,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        'https://wa.me/260962431222?text=Hi! I am interested in booking the ${car.make} ${car.model} for a shuttle service.'
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not launch WhatsApp')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('Request Quote via WhatsApp'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          Text('Select Trip Type', style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1,
                          )),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isOutofTown = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: !_isOutofTown ? AppColors.blue.withOpacity(0.05) : AppColors.bg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !_isOutofTown ? AppColors.blue : AppColors.border,
                                        width: !_isOutofTown ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LOCAL',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: !_isOutofTown ? AppColors.blue : AppColors.text3,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'ZMW ${car.dailyRateZmw.toStringAsFixed(0)}',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text1,
                                          ),
                                        ),
                                        Text(
                                          '/day',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.text3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: car.dailyRateOutofTownZmw != null
                                      ? () => setState(() => _isOutofTown = true)
                                      : null,
                                  child: Opacity(
                                    opacity: car.dailyRateOutofTownZmw != null ? 1.0 : 0.5,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _isOutofTown ? AppColors.blue.withOpacity(0.05) : AppColors.bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isOutofTown ? AppColors.blue : AppColors.border,
                                          width: _isOutofTown ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'OUT OF TOWN',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _isOutofTown ? AppColors.blue : AppColors.text3,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            car.dailyRateOutofTownZmw != null
                                                ? 'ZMW ${car.dailyRateOutofTownZmw!.toStringAsFixed(0)}'
                                                : 'Not Set',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.text1,
                                            ),
                                          ),
                                          Text(
                                            '/day',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.text3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (car.available) ...[
                            const SizedBox(height: 24),
                            // Location Pickers
                            Text('Select Locations', style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1,
                            )),
                            const SizedBox(height: 12),
                            _buildLabel('Pickup Location'),
                            const SizedBox(height: 6),
                            _buildLocationDropdown(
                              value: _pickupLocId,
                              onChanged: (val) => setState(() => _pickupLocId = val),
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Dropoff Location'),
                            const SizedBox(height: 6),
                            _buildLocationDropdown(
                              value: _dropoffLocId,
                              onChanged: (val) => setState(() => _dropoffLocId = val),
                            ),
                            const SizedBox(height: 24),
                            // Date picker
                            Text('Select Rental Period', style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1,
                            )),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickDates,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selectedRange != null ? AppColors.blue : AppColors.border,
                                    width: _selectedRange != null ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, color: AppColors.blue, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _selectedRange == null
                                        ? Text('Tap to select dates', style: GoogleFonts.inter(
                                            fontSize: 14, color: AppColors.text3,
                                          ))
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${_formatDate(_selectedRange!.start)} → ${_formatDate(_selectedRange!.end)}',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1,
                                                )),
                                              Text('$_days day${_days == 1 ? '' : 's'}',
                                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                                            ],
                                          ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.text3),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                            if (_selectedRange != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Cost ($_days days)', style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.white.withOpacity(0.85),
                                    )),
                                    Text('ZMW ${totalCost.toStringAsFixed(0)}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                                      )),
                                  ],
                                ),
                              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                            ],
                          ],
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (car.available && !car.isShuttleOnly)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  border: const Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(color: AppColors.text1.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: GestureDetector(
                  onTap: _bookingInProgress ? null : _confirmBooking,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _bookingInProgress ? null : AppColors.gradient,
                      color: _bookingInProgress ? AppColors.border : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _bookingInProgress ? [] : [
                        BoxShadow(color: AppColors.blue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: _bookingInProgress
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text('Confirm Booking', style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                            )),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1, end: 0, delay: 400.ms, duration: 400.ms),
            ),
        ],
      ),
    );
  }

  Widget _specChip(IconData icon, String label, {Color color = AppColors.text2}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2),
      );

  Widget _buildLocationDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text('Select location', style: GoogleFonts.inter(color: AppColors.text3, fontSize: 14)),
          items: _locations.map((loc) {
            return DropdownMenuItem<String>(
              value: loc.id,
              child: Text(loc.name, style: GoogleFonts.inter(fontSize: 14, color: AppColors.text1)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
