import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car.dart';
import '../models/booking.dart';
import '../models/profile.dart';
import '../models/location.dart';
import '../models/damage.dart';
import '../models/payment.dart';
class ApiService {
  static const String _supabaseUrl = 'https://ncibebzdxtuglmlfbsmq.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jaWJlYnpkeHR1Z2xtbGZic21xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwNDY4NTYsImV4cCI6MjA5NDYyMjg1Nn0.4-Jmc3rODzud-rvcNKwVtfjX44W_GVnjZyqxrMRLpjw';
  static const String _apiBaseUrl = 'http://10.0.2.2:5265/api';

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  // --- Auth Actions ---

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = data['access_token'] as String;
        final userId = data['user']['id'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userIdKey, userId);

        // Trigger Profile Get/Create on backend to ensure profile matches JWT user
        try {
          await getMeWithToken(token);
        } catch (_) {}

        return {'success': true};
      } else {
        return {
          'success': false,
          'error': data['error_description'] ?? data['msg'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: Could not reach authentication server.'};
    }
  }

  static Future<Map<String, dynamic>> signUp(
      String email, String password, String firstName, String lastName, String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final session = data['session'];
        if (session != null) {
          final token = session['access_token'] as String;
          final userId = session['user']['id'] as String;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userIdKey, userId);

          await createProfile(Profile(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
          ));
        } else {
          final user = data['user'];
          if (user != null) {
            final userId = user['id'] as String;
            await createProfile(Profile(
              id: userId,
              firstName: firstName,
              lastName: lastName,
              email: email,
              phoneNumber: phoneNumber,
            ));
          }
        }
        return {'success': true};
      } else {
        return {'success': false, 'error': data['msg'] ?? data['error_description'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: Could not reach registration server.'};
    }
  }

  // --- API Actions ---

  static Future<Profile> getMeWithToken(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/Profiles/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  static Future<Profile> getMe() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    return getMeWithToken(token);
  }

  static Future<List<Car>> getCars() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/cars'));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Car.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cars');
    }
  }

  static Future<Car> createCar(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/cars'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Car.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create car: ${response.body}');
    }
  }

  static Future<Car> updateCar(String id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/cars/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return Car.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update car: ${response.body}');
    }
  }

  static Future<void> deleteCar(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/cars/$id'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete car');
    }
  }

  static Future<List<Location>> getLocations() async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/locations'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Location.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }

  static Future<Location> createLocation(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/locations'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Location.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create location: ${response.body}');
    }
  }

  static Future<void> deleteLocation(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/locations/$id'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete location');
    }
  }

  static Future<List<Booking>> getBookings() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/bookings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Booking.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  static Future<Booking> getBooking(String id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/bookings/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load booking');
    }
  }

  static Future<Booking> createCustomBooking(Map<String, dynamic> bookingData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bookingData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create booking: ${response.body}');
    }
  }

  static Future<List<Payment>> getPayments() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/payments'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Payment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load payments');
    }
  }

  static Future<Payment> createPayment(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/payments'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Payment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  static Future<List<Damage>> getDamages() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/damages'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Damage.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load damages');
    }
  }

  static Future<Damage> createDamage(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/damages'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Damage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create damage: ${response.body}');
    }
  }

  static Future<String> uploadDamageImage(List<int> bytes, String fileName, String mimeType) async {
    final response = await http.post(
      Uri.parse('$_supabaseUrl/storage/v1/object/cars/damages/$fileName'),
      headers: {
        'Authorization': 'Bearer $_supabaseAnonKey',
        'apikey': _supabaseAnonKey,
        'Content-Type': mimeType,
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return '$_supabaseUrl/storage/v1/object/public/cars/damages/$fileName';
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  static Future<Profile> createProfile(Profile p) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/Profiles'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(p.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create profile: ${response.body}');
    }
  }

  static Future<Booking> checkoutBooking({
    required String carId,
    required String startDate,
    required String endDate,
    required String pickupLocationId,
    required String dropoffLocationId,
    required String paymentMethod,
    String? mobileNumber,
    String? provider,
  }) async {
    final token = await getToken();
    final userId = await getUserId();
    if (token == null || userId == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      'booking': {
        'id': '00000000-0000-0000-0000-000000000000',
        'carId': carId,
        'customerId': userId,
        'startDate': startDate,
        'endDate': endDate,
        'pickupLocationId': pickupLocationId,
        'dropoffLocationId': dropoffLocationId,
        'status': 'Pending',
        'paymentStatus': 'Pending',
        'totalPriceZmw': 0.0,
      },
      'paymentMethod': paymentMethod,
    };
    if (mobileNumber != null) {
      payload['mobileNumber'] = mobileNumber;
    }
    if (provider != null) {
      payload['provider'] = provider;
    }

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/bookings/checkout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Checkout failed');
    }
  }

  static Future<Profile> updateProfile(String id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/profiles/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return Profile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  static Future<void> deleteProfile(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/profiles/$id'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete profile: ${response.body}');
    }
  }

  static Future<void> cleanupOrphans() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/profiles/cleanup-orphans'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cleanup orphans: ${response.body}');
    }
  }
}

  // --- Admin Actions ---

  static Future<List<Damage>> getDamages() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/damages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Damage.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load damages');
    }
  }

  static Future<List<Profile>> getProfiles() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/profiles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Profile.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load profiles');
    }
  }

  static Future<void> updateBookingStatus(String bookingId, String status) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/bookings/$bookingId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(status),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update booking status');
    }
  }

  // --- CMS Settings ---

  static Future<List<String>> getHeroImages() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/settings/hero-images'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<void> updateHeroImages(List<String> urls) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/settings/hero-images'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(urls),
    );
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to update hero images');
  }

  static Future<Map<String, dynamic>> getHeroVideo() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/settings/hero-video'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'url': ''};
  }

  static Future<void> updateHeroVideo(String url) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/settings/hero-video'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'url': url}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to update hero video');
  }

  static Future<void> deleteHeroVideo() async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/settings/hero-video'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Failed to delete hero video');
  }
}
