import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class AdminCreateCarScreen extends StatefulWidget {
  final Car? car;
  const AdminCreateCarScreen({super.key, this.car});

  @override
  State<AdminCreateCarScreen> createState() => _AdminCreateCarScreenState();
}

class _AdminCreateCarScreenState extends State<AdminCreateCarScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  late TextEditingController _makeCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _licensePlateCtrl;
  late TextEditingController _vinCtrl;
  late TextEditingController _seatsCtrl;
  late TextEditingController _dailyRateZmwCtrl;
  late TextEditingController _dailyRateUsdCtrl;

  String _transmission = 'Automatic';
  String _fuelType = 'Petrol';
  String _status = 'Available';

  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _makeCtrl = TextEditingController(text: widget.car?.make ?? '');
    _modelCtrl = TextEditingController(text: widget.car?.model ?? '');
    _licensePlateCtrl = TextEditingController(text: widget.car?.licensePlate ?? '');
    _vinCtrl = TextEditingController(text: widget.car?.vin ?? '');
    _seatsCtrl = TextEditingController(text: widget.car?.seats.toString() ?? '5');
    _dailyRateZmwCtrl = TextEditingController(text: widget.car?.dailyRateZmw.toString() ?? '');
    _dailyRateUsdCtrl = TextEditingController(text: widget.car?.dailyRateUsd?.toString() ?? '');

    if (widget.car != null) {
      _transmission = widget.car!.transmission;
      _fuelType = widget.car!.fuelType;
      _status = widget.car!.status;
      _existingImages = List.from(widget.car!.imageUrls ?? []);
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      List<String> finalImageUrls = List.from(_existingImages);

      for (var image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final mimeType = lookupMimeType(image.name) ?? 'image/jpeg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        
        final url = await ApiService.uploadDamageImage(bytes.toList(), fileName, mimeType); // reused for cars
        finalImageUrls.add(url);
      }

      final data = {
        'make': _makeCtrl.text,
        'model': _modelCtrl.text,
        'licensePlate': _licensePlateCtrl.text.isEmpty ? null : _licensePlateCtrl.text,
        'vin': _vinCtrl.text.isEmpty ? null : _vinCtrl.text,
        'seats': int.parse(_seatsCtrl.text),
        'dailyRateZmw': double.parse(_dailyRateZmwCtrl.text),
        'dailyRateUsd': _dailyRateUsdCtrl.text.isEmpty ? (double.parse(_dailyRateZmwCtrl.text) / 25.0) : double.parse(_dailyRateUsdCtrl.text),
        'transmission': _transmission,
        'fuelType': _fuelType,
        'status': _status,
        'imageUrls': finalImageUrls,
      };

      if (widget.car == null) {
        await ApiService.createCar(data);
      } else {
        await ApiService.updateCar(widget.car!.id, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle saved successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save vehicle: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: Text(widget.car == null ? 'Add Vehicle' : 'Edit Vehicle', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makeCtrl,
                      decoration: const InputDecoration(labelText: 'Make*', filled: true, fillColor: Colors.white),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(labelText: 'Model*', filled: true, fillColor: Colors.white),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _licensePlateCtrl,
                      decoration: const InputDecoration(labelText: 'License Plate', filled: true, fillColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vinCtrl,
                      decoration: const InputDecoration(labelText: 'VIN', filled: true, fillColor: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seatsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Seats', filled: true, fillColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _transmission,
                      decoration: const InputDecoration(labelText: 'Transmission', filled: true, fillColor: Colors.white),
                      items: ['Automatic', 'Manual'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _transmission = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dailyRateZmwCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Rate (ZMW)*', filled: true, fillColor: Colors.white),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', filled: true, fillColor: Colors.white),
                      items: ['Available', 'Rented', 'In Maintenance', 'Damaged', 'Unavailable'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._existingImages.map((url) => Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 0, top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _existingImages.remove(url)),
                          child: Container(color: Colors.red, child: const Icon(Icons.close, color: Colors.white, size: 16)),
                        ),
                      )
                    ],
                  )),
                  ..._selectedImages.map((img) => Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Icon(Icons.image, color: Colors.grey)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _submitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Vehicle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
