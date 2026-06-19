import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/booking.dart';
import '../models/profile.dart';
import 'landing_screen.dart';
import 'fleet_screen.dart';
import 'services_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0; // 0: Home/Landing, 1: Fleet, 2: Services, 3: Bookings, 4: Profile
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (_) {
      // Ignore if not logged in
    }
  }

  void _changeTab(int index) {
    setState(() {
      _navIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      LandingScreen(
        onExploreFleet: () => _changeTab(1),
        onExploreServices: () => _changeTab(2),
      ),
      const FleetScreen(),
      const ServicesScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    final screenTitles = [
      'RETRIX CAR RENTAL',
      'OUR FLEET',
      'SERVICES',
      'MY BOOKINGS',
      'MY PROFILE',
    ];

    final userName = _profile != null && _profile!.firstName.isNotEmpty
        ? '${_profile!.firstName} ${_profile!.lastName}'
        : 'Retrix User';
    final userEmail = _profile?.email ?? 'user@retrix.com';

    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Turn off default leading hamburger menu
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: AppColors.blue),
            ),
            const SizedBox(width: 10),
            Text(
              _navIndex == 0 ? 'RETRIX' : screenTitles[_navIndex],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text1,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.text1, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.25),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
              ),
              accountName: Text(
                userName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                userEmail,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
            
            // Drawer Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _drawerItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _drawerItem(1, Icons.directions_car_outlined, Icons.directions_car_rounded, 'Our Fleet'),
                  _drawerItem(2, Icons.support_agent_outlined, Icons.support_agent_rounded, 'Services'),
                  _drawerItem(3, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'My Bookings'),
                  _drawerItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'My Profile'),
                  if (_profile?.isAdmin == true) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: AppColors.border),
                    ),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.gold, size: 24),
                      title: Text(
                        'Admin Panel',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text1,
                        ),
                      ),
                      onTap: () {
                        context.pop(); // close drawer
                        context.go('/admin'); // navigate to admin
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ],
              ),
            ),

            // Sign In/Out Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () async {
                  if (_profile != null) {
                    await ApiService.logout();
                  }
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _profile == null ? AppColors.blue : AppColors.red,
                  side: BorderSide(color: (_profile == null ? AppColors.blue : AppColors.red).withOpacity(0.4), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_profile == null ? Icons.login_rounded : Icons.logout_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _profile == null ? 'Sign In' : 'Sign Out',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_navIndex],
      ),
    );
  }

  Widget _drawerItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _navIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.blue.withOpacity(0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        leading: Icon(
          isSelected ? solidIcon : outlineIcon,
          color: isSelected ? AppColors.blue : AppColors.text2,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.blue : AppColors.text1,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          _changeTab(index);
          Navigator.pop(context); // Close drawer
        },
      ),
      ),
    );
  }
}

// Inline screens for bottom nav
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final list = await ApiService.getBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load bookings. Pull down to refresh.';
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return AppColors.green;
      case 'pending':
      case 'draft':
        return AppColors.amber;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('My Bookings'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        color: AppColors.blue,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Text(_error!, style: GoogleFonts.inter(color: AppColors.text3)),
                      ),
                    ],
                  )
                : _bookings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.blue, size: 36),
                                ),
                                const SizedBox(height: 16),
                                Text('No bookings yet', style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1,
                                )),
                                const SizedBox(height: 8),
                                Text('Your rental history will appear here', style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.text3,
                                )),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _bookings.length,
                        itemBuilder: (context, i) {
                          final booking = _bookings[i];
                          final start = DateTime.tryParse(booking.startDate);
                          final end = DateTime.tryParse(booking.endDate);
                          final dateRangeStr = (start != null && end != null)
                              ? '${DateFormat('MMM dd, yyyy').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}'
                              : '${booking.startDate} - ${booking.endDate}';
                              
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          booking.car != null
                                              ? '${booking.car!.make} ${booking.car!.model}'
                                              : 'Rental Vehicle',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text1,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          booking.status,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(booking.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateRangeStr,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2),
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total Price', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                                          Text(
                                            'ZMW ${booking.totalPriceZmw.toStringAsFixed(0)}',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            booking.paymentStatus.toLowerCase() == 'paid'
                                                ? Icons.check_circle_outline
                                                : Icons.pending_actions_outlined,
                                            size: 14,
                                            color: booking.paymentStatus.toLowerCase() == 'paid'
                                                ? AppColors.green
                                                : AppColors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            booking.paymentStatus.toLowerCase() == 'paid' ? 'Paid' : 'Unpaid',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: booking.paymentStatus.toLowerCase() == 'paid'
                                                  ? AppColors.green
                                                  : AppColors.amber,
                                            ),
                                          ),
                                        ],
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
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _profile = p;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profile != null ? '${_profile!.firstName} ${_profile!.lastName}' : 'Guest User';
    final email = _profile?.email ?? 'Please log in to manage your account';

    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            fullName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          ),
                    Text(email, style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white.withOpacity(0.75),
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (_profile?.isAdmin == true)
                    _profileItem(Icons.admin_panel_settings, 'Admin Portal', AppColors.gold, onTap: () {
                      context.push('/admin');
                    }),
                  _profileItem(Icons.receipt_long_outlined, 'My Bookings', AppColors.blue),
                  _profileItem(Icons.favorite_outline, 'Saved Cars', AppColors.red),
                  _profileItem(Icons.support_agent_outlined, 'Support', AppColors.cyan),
                  _profileItem(Icons.settings_outlined, 'Settings', AppColors.text2),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await ApiService.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: (_profile == null ? AppColors.blue : AppColors.red).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (_profile == null ? AppColors.blue : AppColors.red).withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_profile == null ? Icons.login_rounded : Icons.logout_rounded, 
                                 color: _profile == null ? AppColors.blue : AppColors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(_profile == null ? 'Sign In' : 'Sign Out', style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w600, 
                              color: _profile == null ? AppColors.blue : AppColors.red,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1,
            ))),
            const Icon(Icons.chevron_right, color: AppColors.text3, size: 18),
          ],
        ),
      ),
    );
  }
}
