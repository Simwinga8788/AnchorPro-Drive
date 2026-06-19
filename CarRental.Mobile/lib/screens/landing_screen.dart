import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/car.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onExploreFleet;
  final VoidCallback onExploreServices;
  const LandingScreen({
    super.key,
    required this.onExploreFleet,
    required this.onExploreServices,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<Car> _featuredCars = [];
  List<Car> _shuttleCars = [];
  bool _loading = true;
  bool _showHowItWorks = false;

  @override
  void initState() {
    super.initState();
    _loadFeaturedCars();
  }

  Future<void> _loadFeaturedCars() async {
    try {
      final cars = await ApiService.getCars();
      if (mounted) {
        setState(() {
          _featuredCars = cars.where((c) => !c.isShuttleOnly).take(3).toList();
          _shuttleCars = cars.where((c) => c.isShuttleOnly).take(3).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- HERO SECTION ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
            decoration: const BoxDecoration(
              gradient: AppColors.gradientDark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              children: [
                // Glowing background circles
                Positioned(
                  right: -40, top: -20,
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -80, bottom: -40,
                  child: Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue.withOpacity(0.06),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'Drive in\n'),
                          TextSpan(
                            text: 'Style',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.cyan,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' &\nComfort'),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'Premium vehicles for business, leisure, and adventure. From Kitwe to Livingstone.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: widget.onExploreFleet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Explore Fleet', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: widget.onExploreServices,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Our Services', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                  ],
                ),
              ],
            ),
          ),



          // --- FEATURED VEHICLES SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured Vehicles', style: GoogleFonts.spaceGrotesk(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1,
                        )),
                        const SizedBox(height: 2),
                        Text('Handpicked for you', style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.text3,
                        )),
                      ],
                    ),
                    TextButton(
                      onPressed: widget.onExploreFleet,
                      child: Text('View All', style: GoogleFonts.spaceGrotesk(color: AppColors.blue, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _loading
                    ? Column(children: [ _buildStackedShimmer(), const SizedBox(height: 16), _buildStackedShimmer() ])
                    : _featuredCars.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text('No vehicles available.', style: GoogleFonts.inter(color: AppColors.text3)),
                            ),
                          )
                        : Column(
                            children: _featuredCars.map((car) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildStackedCard(context, car),
                            )).toList(),
                          ),
              ],
            ),
          ),

          // --- SHUTTLE SERVICES SECTION ---
          if (_shuttleCars.isNotEmpty || _loading)
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shuttle Services', style: GoogleFonts.spaceGrotesk(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1,
                            )),
                            const SizedBox(height: 4),
                            Text('Exclusive vehicles for weddings, airport transfers, and executive travel.', style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.text3,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? Column(children: [ _buildStackedShimmer(), const SizedBox(height: 16), _buildStackedShimmer() ])
                      : Column(
                          children: _shuttleCars.map((car) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildShuttleCard(context, car),
                          )).toList(),
                        ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.onExploreServices,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text1,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('View All Services', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // --- CTA BANNER ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.blue.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50, top: -50,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to hit the road?',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zambia\'s premier car rental service is just a few taps away.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: widget.onExploreFleet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.bgDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Book Your Ride',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- PROCESS SECTION ("How it works") ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showHowItWorks = !_showHowItWorks;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline_rounded, color: AppColors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text('How it Works', style: GoogleFonts.spaceGrotesk(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.blue,
                        )),
                        const SizedBox(width: 4),
                        Icon(
                          _showHowItWorks ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
                        _buildStep(
                          '01',
                          Icons.search_rounded,
                          'Browse & Choose',
                          'Filter our fleet by type, location, and budget. Every car is verified and road-ready.',
                        ),
                        _buildStep(
                          '02',
                          Icons.calendar_month_outlined,
                          'Book & Confirm',
                          'Select your pickup and drop-off dates. Instant booking confirmation, no hidden fees.',
                        ),
                        _buildStep(
                          '03',
                          Icons.directions_car_filled_outlined,
                          'Drive & Enjoy',
                          'Collect your vehicle at the agreed time. Full insurance included. 24/7 roadside support.',
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _showHowItWorks ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep(String number, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withOpacity(0.15)),
            ),
            child: Icon(icon, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number . $title',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.text2, height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.bg3,
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.text3),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
      ],
    );
  }

  Widget _buildStackedCard(BuildContext context, Car car) {
    return GestureDetector(
      onTap: () => context.push('/car/${car.id}', extra: car),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: AppColors.text1.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                car.primaryImage,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.bg3,
                  child: const Icon(Icons.directions_car, color: AppColors.text3, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${car.make} ${car.model}', style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1,
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: car.status == 'Available' ? AppColors.green.withOpacity(0.1) : AppColors.text3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      car.status,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.w600, 
                        color: car.status == 'Available' ? AppColors.green : AppColors.text3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _spec(Icons.settings_outlined, car.transmission),
                        _spec(Icons.local_gas_station_outlined, car.fuelType),
                        _spec(Icons.people_outline, '${car.seats} Seats'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ZMW ${car.dailyRateZmw.toStringAsFixed(0)}', style: GoogleFonts.spaceGrotesk(
                              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.blue,
                            )),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('/day (local)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                            ),
                          ],
                        ),
                        if (car.dailyRateOutofTownZmw != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('ZMW ${car.dailyRateOutofTownZmw!.toStringAsFixed(0)}', style: GoogleFonts.spaceGrotesk(
                                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text2,
                              )),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('/day (out-of-town)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('View Vehicle', style: GoogleFonts.spaceGrotesk(
                                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                              )),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShuttleCard(BuildContext context, Car car) {
    return GestureDetector(
      onTap: () => context.push('/car/${car.id}', extra: car),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: AppColors.text1.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                car.primaryImage,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.bg3,
                  child: const Icon(Icons.directions_car, color: AppColors.text3, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${car.make} ${car.model}', style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Shuttle Only',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: car.status == 'Available' ? AppColors.green.withOpacity(0.1) : AppColors.text3.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          car.status,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11, fontWeight: FontWeight.w600, 
                            color: car.status == 'Available' ? AppColors.green : AppColors.text3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _spec(Icons.settings_outlined, car.transmission),
                        _spec(Icons.local_gas_station_outlined, car.fuelType),
                        _spec(Icons.people_outline, '${car.seats} Seats'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Custom Pricing', style: GoogleFonts.spaceGrotesk(
                          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text1,
                        )),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.push('/car/${car.id}', extra: car),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Request Quote', style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                                )),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
