import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Admin Portal',
          style: GoogleFonts.spaceGrotesk(color: AppColors.text1, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.text1),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.bg,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.blue),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Retrix Admin',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/admin'),
            _drawerItem(context, Icons.directions_car, 'Fleet', '/admin/fleet'),
            _drawerItem(context, Icons.calendar_today, 'Bookings', '/admin/bookings'),
            _drawerItem(context, Icons.people, 'Customers', '/admin/customers'),
            _drawerItem(context, Icons.payment, 'Payments', '/admin/payments'),
            _drawerItem(context, Icons.car_crash, 'Damages', '/admin/damages'),
            _drawerItem(context, Icons.pin_drop, 'Locations', '/admin/locations'),
            _drawerItem(context, Icons.bar_chart, 'Reports', '/admin/reports'),
            _drawerItem(context, Icons.settings, 'Settings', '/admin/settings'),
            const Spacer(),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppColors.text3),
              title: Text('Exit Admin', style: GoogleFonts.inter(color: AppColors.text2)),
              onTap: () {
                context.go('/home');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route) {
    final isActive = GoRouterState.of(context).uri.toString() == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.blue : AppColors.text3),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: isActive ? AppColors.blue : AppColors.text2,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.blue.withOpacity(0.1),
      onTap: () {
        context.pop(); // Close drawer
        context.go(route);
      },
    );
  }
}
