import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../models/profile.dart';
import '../../models/location.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';

class AdminCreateBookingScreen extends StatefulWidget {
  const AdminCreateBookingScreen({super.key});

  @override
  State<AdminCreateBookingScreen> createState() => _AdminCreateBookingScreenState();
}

class _AdminCreateBookingScreenState extends State<AdminCreateBookingScreen> {
  List<Car> _cars = [];
  List<Profile> _profiles = [];
  List<Location> _locations = [];
  bool _loading = true;
  bool _submitting = false;

  String? _selectedCarId;
  String? _selectedProfileId;
  String? _selectedPickupId;
  String? _selectedDropoffId;
  String _bookingType = 'Standard';
  String _status = 'Pending';
  String _paymentStatus = 'Pending';
  final TextEditingController _priceController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cars = await ApiService.getCars();
      final profiles = await ApiService.getProfiles();
      final locations = await ApiService.getLocations();
      if (mounted) {
        setState(() {
          _cars = cars;
          _profiles = profiles;
          _locations = locations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          if (picked.isAfter(_startDate)) {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCarId == null || _selectedProfileId == null || _selectedPickupId == null || _selectedDropoffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all required fields')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final car = _cars.firstWhere((c) => c.id == _selectedCarId);
      final days = _endDate.difference(_startDate).inDays;
      final rentalDays = days < 1 ? 1 : days;
      final totalPrice = car.pricePerDayZmw * rentalDays;

      final data = {
        'carId': _selectedCarId,
        'customerId': _selectedProfileId,
        'pickupLocationId': _selectedPickupId,
        'dropoffLocationId': _selectedDropoffId,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'totalPriceZmw': _priceController.text.isNotEmpty ? double.parse(_priceController.text) : totalPrice,
        'totalPriceUsd': (_priceController.text.isNotEmpty ? double.parse(_priceController.text) : totalPrice) / 25.0,
        'status': _status,
        'paymentStatus': _paymentStatus,
        'bookingType': _bookingType
      };

      await ApiService.createCustomBooking(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create booking: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg2,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Create Custom Booking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Booking Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        value: _bookingType,
                        items: ['Standard', 'Airport Transfer', 'Wedding', 'Chauffeur'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _bookingType = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Custom Price (ZMW)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Leave empty for auto', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              hint: const Text('Select Customer'),
              value: _selectedProfileId,
              items: _profiles.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.firstName} ${p.lastName} (${p.email})'))).toList(),
              onChanged: (val) => setState(() => _selectedProfileId = val),
            ),
            const SizedBox(height: 20),

            const Text('Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              hint: const Text('Select Vehicle'),
              value: _selectedCarId,
              items: _cars.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.make} ${c.model} - ${c.licensePlate}'))).toList(),
              onChanged: (val) => setState(() => _selectedCarId = val),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              hint: const Text('Select Pickup Location'),
              value: _selectedPickupId,
              items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (val) => setState(() => _selectedPickupId = val),
            ),
            const SizedBox(height: 20),

            const Text('Dropoff Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              hint: const Text('Select Dropoff Location'),
              value: _selectedDropoffId,
              items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (val) => setState(() => _selectedDropoffId = val),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status (Quote vs Invoice)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: 'Pending', child: Text('Pending (Quotation)')),
                          DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed (Invoice)')),
                        ],
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        value: _paymentStatus,
                        items: ['Pending', 'Paid'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _paymentStatus = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
