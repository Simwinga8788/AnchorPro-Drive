import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../theme.dart';
import 'package:go_router/go_router.dart';

class AdminFleetScreen extends StatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen> {
  List<Car> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final cars = await ApiService.getCars();
      if (mounted) {
        setState(() {
          _cars = cars;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : RefreshIndicator(
              onRefresh: _loadCars,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _cars.length,
                itemBuilder: (context, index) {
                  final car = _cars[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.bg2,
                            image: (car.imageUrls != null && car.imageUrls!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(car.imageUrls!.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (car.imageUrls == null || car.imageUrls!.isEmpty)
                              ? const Icon(Icons.directions_car, color: AppColors.text3)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${car.make} ${car.model}', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                              const SizedBox(height: 4),
                              Text(car.licensePlate ?? 'No License Plate', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: car.status == 'Available' ? AppColors.green.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  car.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: car.status == 'Available' ? AppColors.green : AppColors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.blue),
                          onPressed: () async {
                            final result = await context.push('/admin/create-car', extra: car);
                            if (result == true) _loadCars();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () async {
          final result = await context.push('/admin/create-car');
          if (result == true) _loadCars();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
