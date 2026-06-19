import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ServiceInfo {
  final String id;
  final String title;
  final IconData icon;
  final String image;
  final String description;
  final List<String> features;

  const ServiceInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.image,
    required this.description,
    required this.features,
  });
}

const _services = [
  ServiceInfo(
    id: 'airport',
    title: 'Airport Transfers',
    icon: Icons.local_airport_rounded,
    image: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=1200&q=80',
    description: 'Skip the taxi queues. Our professional drivers track your flight and wait at arrivals with a personalized sign.',
    features: [
      'Flat rate pricing to your hotel',
      '60 minutes complimentary wait time',
      'Professional Chauffeurs',
    ],
  ),
  ServiceInfo(
    id: 'wedding',
    title: 'Weddings & Events',
    icon: Icons.celebration_rounded,
    image: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=1200&q=80',
    description: 'Make your special day perfect with our luxury fleet. Specialized hourly rates and chauffeur services for VIP guests.',
    features: [
      'Immaculate luxury vehicles',
      'Flexible hourly bookings',
      'Optional vehicle decorations',
    ],
  ),
  ServiceInfo(
    id: 'corporate',
    title: 'Corporate Leasing',
    icon: Icons.business_center_outlined,
    image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80',
    description: 'Long-term vehicle solutions for your business. Reliable fleet management with full maintenance and insurance included.',
    features: [
      'Discounted monthly rates',
      'Dedicated account manager',
      'Replacement vehicle guarantee',
    ],
  ),
  ServiceInfo(
    id: 'chauffeur',
    title: 'Chauffeur Services',
    icon: Icons.directions_car_filled_outlined,
    image: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=1200&q=80',
    description: 'Experience the ultimate convenience with our highly-trained chauffeurs for full-day or half-day city engagements.',
    features: [
      'Discreet & professional drivers',
      'Deep local knowledge',
      'On-call flexibility',
    ],
  ),
];

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _activeIndex = 0;

  void _showQuoteSheet(ServiceInfo service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuoteContactSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Text
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
                        TextSpan(text: 'Premium '),
                        TextSpan(
                          text: 'Services',
                          style: TextStyle(color: AppColors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Beyond standard car rentals, we offer tailored transportation solutions designed for absolute comfort and convenience.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.text3,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Custom Accordion List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final availableWidth = constraints.maxWidth - (16 * (_services.length - 1));

                  return isWide
                      ? SizedBox(
                          height: 600,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _services.asMap().entries.map((entry) {
                              return _buildPanel(entry.value, entry.key, isWide, availableWidth);
                            }).toList(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _services.asMap().entries.map((entry) {
                            return _buildPanel(entry.value, entry.key, isWide, availableWidth);
                          }).toList(),
                        );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildPanel(ServiceInfo service, int index, bool isWide, double availableWidth) {
    final isActive = _activeIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: isWide ? (isActive ? availableWidth * 0.6 : availableWidth * 0.1333) : double.infinity,
        height: isWide ? double.infinity : (isActive ? 340 : 84),
        margin: isWide
            ? EdgeInsets.only(right: index == _services.length - 1 ? 0 : 16)
            : const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.blue.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: AnimatedScale(
                  scale: isActive ? 1.05 : 1.0,
                  duration: const Duration(seconds: 4),
                  curve: Curves.easeOut,
                  child: Image.network(
                    service.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.bgDark),
                  ),
                ),
              ),
              // Overlay gradient
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(isActive ? 0.35 : 0.65),
                        Colors.black.withOpacity(isActive ? 0.85 : 0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Panel Content
              Padding(
                padding: EdgeInsets.all(isWide ? 32 : 18),
                child: isWide
                    ? _buildWideContent(service, isActive)
                    : _buildMobileContent(service, isActive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideContent(ServiceInfo service, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.blue : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            service.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          service.title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
          softWrap: false,
        ),
        if (isActive) ...[
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                  ...service.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.cyan,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              f,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: Colors.white.withOpacity(0.9),
                              ),
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
          GestureDetector(
            onTap: () => _showQuoteSheet(service),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Request a Quote',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileContent(ServiceInfo service, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row (always visible)
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? AppColors.blue : Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Icon(
                service.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                service.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isActive ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
              ),
            ),
          ],
        ),

        // Expandable segment
        if (isActive) ...[
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Feature bullets
                ...service.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.cyan,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Request Quote Button
                GestureDetector(
                  onTap: () => _showQuoteSheet(service),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Request a Quote',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 250.ms),
          ),
        ],
      ],
    );
  }
}

class _QuoteContactSheet extends StatelessWidget {
  final ServiceInfo service;
  const _QuoteContactSheet({required this.service});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contact Info (same as web app)
    const waNumber = '260962431222';
    final waMessage = 'Hi Retrix Car Rental, I\'m reaching out regarding a ${service.title} quotation request. Could you provide more details?';
    final callNumber = '+260972996902';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handlebar for sheet drag styling
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Request a Quote',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Service: ${service.title}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We are available 24/7 on WhatsApp or direct phone calls to tailor your quotation request.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.text2,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // WhatsApp Button Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF25D366).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp Booking Desk',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      Text(
                        '+$waNumber',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(
                    context,
                    'https://wa.me/$waNumber?text=${Uri.encodeComponent(waMessage)}',
                    'WhatsApp link copied to clipboard!',
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.copy_rounded, color: AppColors.text2, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Call Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call Booking Agent',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      Text(
                        callNumber,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, callNumber, 'Phone number copied to clipboard!'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.copy_rounded, color: AppColors.text2, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quote request instructions
          Text(
            '* Copy the link or number and paste in WhatsApp/dialer to chat with us immediately.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.text3,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Cancel
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bg3,
              foregroundColor: AppColors.text1,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
