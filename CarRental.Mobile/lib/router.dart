import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/car_detail_screen.dart';
import 'screens/admin/admin_layout.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_fleet_screen.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/admin_customers_screen.dart';
import 'screens/admin/admin_create_booking_screen.dart';
import 'screens/admin/admin_payments_screen.dart';
import 'screens/admin/admin_create_payment_screen.dart';
import 'screens/admin/admin_damages_screen.dart';
import 'screens/admin/admin_create_damage_screen.dart';
import 'screens/admin/admin_locations_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/admin/admin_create_car_screen.dart';
import 'screens/admin/admin_customer_detail_screen.dart';
import 'models/car.dart';
import 'models/profile.dart';
import 'screens/quotation_screen.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/car/:id',
      builder: (context, state) => CarDetailScreen(carId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/quote/:id',
      builder: (context, state) => QuotationScreen(bookingId: state.pathParameters['id']!),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminLayout(child: child),
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final isAdmin = prefs.getBool('auth_is_admin') ?? false;
        
        if (!isAdmin) {
          // If not cached as admin, try to fetch the profile to be sure
          try {
            final profile = await ApiService.getMe();
            if (profile.isAdmin) {
              await prefs.setBool('auth_is_admin', true);
              return null; // allow access
            }
          } catch (_) {}
          
          // Not admin or not logged in, redirect to home
          return '/home';
        }
        
        return null;
      },
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
        GoRoute(path: '/admin/fleet', builder: (context, state) => const AdminFleetScreen()),
        GoRoute(path: '/admin/bookings', builder: (context, state) => const AdminBookingsScreen()),
        GoRoute(path: '/admin/customers', builder: (context, state) => const AdminCustomersScreen()),
        GoRoute(path: '/admin/create-booking', builder: (context, state) => const AdminCreateBookingScreen()),
        GoRoute(path: '/admin/payments', builder: (context, state) => const AdminPaymentsScreen()),
        GoRoute(path: '/admin/create-payment', builder: (context, state) => const AdminCreatePaymentScreen()),
        GoRoute(path: '/admin/damages', builder: (context, state) => const AdminDamagesScreen()),
        GoRoute(path: '/admin/create-damage', builder: (context, state) => const AdminCreateDamageScreen()),
        GoRoute(path: '/admin/locations', builder: (context, state) => const AdminLocationsScreen()),
        GoRoute(path: '/admin/settings', builder: (context, state) => const AdminSettingsScreen()),
        GoRoute(path: '/admin/reports', builder: (context, state) => const AdminReportsScreen()),
        GoRoute(
          path: '/admin/create-car',
          builder: (context, state) {
            final car = state.extra as Car?;
            return AdminCreateCarScreen(car: car);
          },
        ),
        GoRoute(
          path: '/admin/customer-detail',
          builder: (context, state) {
            final profile = state.extra as Profile;
            return AdminCustomerDetailScreen(profile: profile);
          },
        ),
      ],
    ),
  ],
);
