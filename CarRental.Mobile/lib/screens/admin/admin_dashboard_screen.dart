import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../models/booking.dart';
import '../../models/damage.dart';
import '../../theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _carCount = 0;
  int _bookingCount = 0;
  int _damageCount = 0;
  double _revenue = 0.0;
  int _availableCars = 0;
  double _utilRate = 0.0;
  
  List<Booking> _allBookings = [];
  List<Car> _allCars = [];
  List<Booking> _recentBookings = [];
  List<double> _revenueData = List.filled(6, 0.0);
  Map<String, int> _fleetStatusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        ApiService.getCars(),
        ApiService.getBookings(),
        ApiService.getDamages(),
      ]);

      final cars = results[0] as List<Car>;
      final bookings = results[1] as List<Booking>;
      final damages = results[2] as List<Damage>;

      double totalRev = 0;
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          totalRev += b.totalPriceZmw;
        }
      }

      int available = cars.where((c) => c.status == 'Available').length;
      double util = cars.isEmpty ? 0 : ((cars.length - available) / cars.length) * 100;
      
      // Calculate 6 month revenue
      final now = DateTime.now();
      final List<double> revs = List.filled(6, 0.0);
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          final d = DateTime.parse(b.startDate);
          // simple month diff
          int monthDiff = (now.year - d.year) * 12 + now.month - d.month;
          if (monthDiff >= 0 && monthDiff < 6) {
            revs[5 - monthDiff] += b.totalPriceZmw; // index 5 is current month
          }
        }
      }

      // Fleet statuses
      final Map<String, int> statusCounts = {};
      for (var c in cars) {
        statusCounts[c.status] = (statusCounts[c.status] ?? 0) + 1;
      }

      bookings.sort((a, b) => DateTime.parse(b.createdAt ?? b.startDate).compareTo(DateTime.parse(a.createdAt ?? a.startDate)));

      if (mounted) {
        setState(() {
          _allCars = cars;
          _allBookings = bookings;
          _carCount = cars.length;
          _bookingCount = bookings.length;
          _damageCount = damages.length;
          _revenue = totalRev;
          _availableCars = available;
          _utilRate = util;
          _revenueData = revs;
          _fleetStatusCounts = statusCounts;
          _recentBookings = bookings.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["Retrix Daily Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"]);
      rows.add([]);
      rows.add(["ID", "Booking Date", "Customer ID", "Car ID", "Status", "Price ZMW"]);
      
      for (var b in _allBookings) {
        rows.add([
          b.id,
          DateFormat('yyyy-MM-dd').format(DateTime.parse(b.createdAt ?? b.startDate)),
          b.customerId,
          b.carId,
          b.status,
          b.totalPriceZmw
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Retrix_Report.csv');
      await file.writeAsString(csv);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Retrix Daily Report',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Revenue', value: 'ZMW ${_revenue.toStringAsFixed(0)}', icon: Icons.attach_money, color: AppColors.green)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Bookings', value: '$_bookingCount', icon: Icons.calendar_today, color: AppColors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Total Cars', value: '$_carCount', icon: Icons.directions_car, color: AppColors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Available', value: '$_availableCars', icon: Icons.check_circle_outline, color: AppColors.cyan)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Damages', value: '$_damageCount', icon: Icons.warning_amber_rounded, color: AppColors.red)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Utilization', value: '${_utilRate.toStringAsFixed(1)}%', icon: Icons.pie_chart_outline, color: Colors.purple)),
              ],
            ),
            
            const SizedBox(height: 30),
            Text('Revenue Trends (Last 6 Months)', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val < 0 || val > 5) return const SizedBox();
                          final d = DateTime(now.year, now.month - (5 - val.toInt()));
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MMM').format(d), style: const TextStyle(fontSize: 10)));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(6, (index) => FlSpot(index.toDouble(), _revenueData[index])),
                      isCurved: true,
                      color: AppColors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.blue.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Text('Fleet Status', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _fleetStatusCounts.entries.map((e) {
                          Color color;
                          if (e.key == 'Available') color = AppColors.green;
                          else if (e.key == 'Rented') color = AppColors.blue;
                          else if (e.key == 'Damaged') color = AppColors.red;
                          else color = AppColors.amber;
                          
                          return PieChartSectionData(
                            color: color,
                            value: e.value.toDouble(),
                            title: e.value.toString(),
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _fleetStatusCounts.entries.map((e) {
                        Color color;
                        if (e.key == 'Available') color = AppColors.green;
                        else if (e.key == 'Rented') color = AppColors.blue;
                        else if (e.key == 'Damaged') color = AppColors.red;
                        else color = AppColors.amber;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text('Recent Bookings', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
            const SizedBox(height: 16),
            ..._recentBookings.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('Booking #${b.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${DateFormat('MMM dd').format(DateTime.parse(b.startDate))} - ${DateFormat('MMM dd').format(DateTime.parse(b.endDate))}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(b.status, style: TextStyle(color: b.status == 'Completed' ? Colors.green : AppColors.blue, fontWeight: FontWeight.bold)),
                    Text('ZMW ${b.totalPriceZmw}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text1)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
        ],
      ),
    );
  }
}
