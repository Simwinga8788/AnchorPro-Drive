import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../models/booking.dart';
import '../../theme.dart';
import 'package:mime/mime.dart';

class AdminCreateDamageScreen extends StatefulWidget {
  const AdminCreateDamageScreen({super.key});

  @override
  State<AdminCreateDamageScreen> createState() => _AdminCreateDamageScreenState();
}

class _AdminCreateDamageScreenState extends State<AdminCreateDamageScreen> {
  List<Car> _cars = [];
  List<Booking> _bookings = [];
  bool _loading = true;
  bool _submitting = false;

  String? _selectedCarId;
  String? _selectedBookingId;
  String _severity = 'Minor';
  String _repairStatus = 'Pending';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cars = await ApiService.getCars();
      final bookings = await ApiService.getBookings();
      if (mounted) {
        setState(() {
          _cars = cars;
          _bookings = bookings;
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCarId == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a car and enter a description')));
      return;
    }

    setState(() => _submitting = true);
    try {
      List<String> uploadedUrls = [];

      // 1. Upload Images
      for (var image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final mimeType = lookupMimeType(image.name) ?? 'image/jpeg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        
        final url = await ApiService.uploadDamageImage(bytes.toList(), fileName, mimeType);
        uploadedUrls.add(url);
      }

      // 2. Create Damage Record
      final cost = double.tryParse(_costController.text);
      
      final data = {
        'carId': _selectedCarId,
        'bookingId': _selectedBookingId,
        'severity': _severity,
        'repairStatus': _repairStatus,
        'description': _descriptionController.text,
        'repairCostEstimate': cost,
        'imageUrls': uploadedUrls,
      };

      final newDamage = await ApiService.createDamage(data);

      // 3. (Optional) Mirror the web's auto-charge functionality if there's a cost and booking
      if (cost != null && cost > 0 && _selectedBookingId != null) {
         final selectedBooking = _bookings.firstWhere((b) => b.id == _selectedBookingId);
         await ApiService.createPayment({
            'bookingId': _selectedBookingId,
            'profileId': selectedBooking.customerId,
            'amountZmw': cost,
            'amountUsd': cost / 25.0,
            'paymentMethod': 'Bank Transfer', // Pending Penalty
            'status': 'Pending',
            'type': 'Penalty',
            'transactionId': 'DMG-${newDamage.id.substring(0, 8).toUpperCase()}',
         });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Damage reported successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report damage: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.bg2, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Report Damage', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              hint: const Text('Select Vehicle'),
              value: _selectedCarId,
              items: _cars.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.make} ${c.model} (${c.year})'))).toList(),
              onChanged: (val) => setState(() => _selectedCarId = val),
            ),
            const SizedBox(height: 20),

            const Text('Associated Booking (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              hint: const Text('General Maintenance (None)'),
              value: _selectedBookingId,
              items: [
                const DropdownMenuItem(value: null, child: Text('General Maintenance (None)')),
                ..._bookings.map((b) => DropdownMenuItem(value: b.id, child: Text('Booking #${b.id.substring(0, 8)}'))),
              ],
              onChanged: (val) => setState(() => _selectedBookingId = val),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        value: _severity,
                        items: ['Minor', 'Moderate', 'Major'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _severity = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repair Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        value: _repairStatus,
                        items: ['Pending', 'In Progress', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _repairStatus = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Description*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(hintText: 'Describe the damage...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),

            const Text('Repair Cost Estimate (ZMW)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'e.g. 5000', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),

            const Text('Photographic Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedImages.map((img) => Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Icon(Icons.image, color: Colors.grey)), // Simplified preview for xFile since Mobile/Web differ
                )),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_a_photo, color: AppColors.text3),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _submitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
