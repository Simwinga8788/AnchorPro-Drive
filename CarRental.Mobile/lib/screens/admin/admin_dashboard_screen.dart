import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../../models/car.dart';
import '../../models/booking.dart';
import '../../models/damage.dart';

class CarRevenue {
  final Car car;
  final int bookingsCount;
  final double totalRevenue;
  CarRevenue({required this.car, required this.bookingsCount, required this.totalRevenue});
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _bookingCount = 0;
  int _damageCount = 0;
  double _revenue = 0.0;
  double _revenueMonth = 0.0;
  double _revenueWeek = 0.0;
  int _availableCars = 0;
  double _utilRate = 0.0;
  double _avgDuration = 0.0;
  double _repeatRate = 0.0;

  List<Booking> _allBookings = [];
  List<Car> _allCars = [];
  List<Booking> _recentBookings = [];
  List<CarRevenue> _topPerforming = [];
  List<double> _revenueData = List.filled(6, 0.0);
  Map<String, int> _fleetStatusCounts = {};

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

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
      double revMonth = 0;
      double revWeek = 0;
      final now = DateTime.now();

      // Week-to-date calculation (Monday is start of week)
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          totalRev += b.totalPriceZmw;
          try {
            final date = DateTime.parse(b.startDate);
            // Month matching
            if (date.year == now.year && date.month == now.month) {
              revMonth += b.totalPriceZmw;
            }
            // Week matching
            if (date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek)) {
              revWeek += b.totalPriceZmw;
            }
          } catch (_) {}
        }
      }

      int available = cars.where((c) => c.status == 'Available').length;
      int activeCars = cars.length - available;
      double util = cars.isEmpty ? 0 : (activeCars / cars.length) * 100;

      // Average duration calculation
      int totalDays = 0;
      int nonCancelledCount = 0;
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          try {
            final start = DateTime.parse(b.startDate);
            final end = DateTime.parse(b.endDate);
            totalDays += end.difference(start).inDays + 1;
            nonCancelledCount++;
          } catch (_) {}
        }
      }
      double avgDuration = nonCancelledCount == 0 ? 0.0 : totalDays / nonCancelledCount;

      // Customer repeat rate calculation
      final Map<String, int> customerBookingCounts = {};
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          customerBookingCounts[b.customerId] = (customerBookingCounts[b.customerId] ?? 0) + 1;
        }
      }
      int totalCustomers = customerBookingCounts.length;
      int repeatCustomers = customerBookingCounts.values.where((count) => count > 1).length;
      double repeatRate = totalCustomers == 0 ? 0.0 : (repeatCustomers / totalCustomers) * 100;

      // Calculate 6 month revenue
      final List<double> revs = List.filled(6, 0.0);
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          final d = DateTime.parse(b.startDate);
          int monthDiff = (now.year - d.year) * 12 + now.month - d.month;
          if (monthDiff >= 0 && monthDiff < 6) {
            revs[5 - monthDiff] += b.totalPriceZmw;
          }
        }
      }

      // Fleet statuses
      final Map<String, int> statusCounts = {};
      for (var c in cars) {
        statusCounts[c.status] = (statusCounts[c.status] ?? 0) + 1;
      }

      // Top Performing Vehicles
      final Map<String, double> carRevenues = {};
      final Map<String, int> carBookings = {};
      for (var b in bookings) {
        if (b.status != 'Cancelled') {
          carRevenues[b.carId] = (carRevenues[b.carId] ?? 0.0) + b.totalPriceZmw;
          carBookings[b.carId] = (carBookings[b.carId] ?? 0) + 1;
        }
      }

      final List<CarRevenue> performingCars = [];
      for (var car in cars) {
        final rev = carRevenues[car.id] ?? 0.0;
        final count = carBookings[car.id] ?? 0;
        performingCars.add(CarRevenue(car: car, bookingsCount: count, totalRevenue: rev));
      }
      performingCars.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      bookings.sort((a, b) => DateTime.parse(b.createdAt ?? b.startDate).compareTo(DateTime.parse(a.createdAt ?? a.startDate)));

      if (mounted) {
        setState(() {
          _allCars = cars;
          _allBookings = bookings;
          _bookingCount = bookings.length;
          _damageCount = damages.length;
          _revenue = totalRev;
          _revenueMonth = revMonth;
          _revenueWeek = revWeek;
          _availableCars = available;
          _utilRate = util;
          _avgDuration = avgDuration;
          _repeatRate = repeatRate;
          _revenueData = revs;
          _fleetStatusCounts = statusCounts;
          _topPerforming = performingCars.take(5).toList();
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

      String csvStr = csv_pkg.csv.encode(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Retrix_Report.csv');
      await file.writeAsString(csvStr);

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
        title: Text('Dashboard', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.table_view_outlined, size: 18),
            label: const Text('Export Excel'),
            onPressed: _exportCsv,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.blue,
              textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 4 Premium Metric Cards
            _MetricCard(
              title: 'Total Earnings',
              value: _currencyFormat.format(_revenue),
              icon: Icons.credit_card,
              color: AppColors.blue,
              subText: 'This Month: ${_currencyFormat.format(_revenueMonth)} | This Week: ${_currencyFormat.format(_revenueWeek)}',
            ),
            _MetricCard(
              title: 'Fleet Status',
              value: '${_allCars.length - _availableCars}/${_allCars.length} Active',
              icon: Icons.directions_car,
              color: AppColors.blueLight,
              subText: '${_utilRate.toStringAsFixed(0)}% utilization rate',
            ),
            _MetricCard(
              title: 'Booking Volume',
              value: '$_bookingCount Bookings',
              icon: Icons.calendar_today,
              color: AppColors.green,
              subText: 'Avg. Duration: ${_avgDuration.toStringAsFixed(0)} days',
            ),
            _MetricCard(
              title: 'Fleet Health',
              value: '$_damageCount Incidents',
              icon: Icons.warning_amber_rounded,
              color: AppColors.amber,
              subText: '${_repeatRate.toStringAsFixed(0)}% customer repeat rate',
            ),

            const SizedBox(height: 24),
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
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MMM').format(d), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3)));
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

            const SizedBox(height: 24),
            Text('Fleet Status Breakdown', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
            const SizedBox(height: 16),
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
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
                            radius: 25,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),

            // Top Performing Vehicles Section
            if (_topPerforming.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Top Performing Vehicles', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
              const SizedBox(height: 16),
              ..._topPerforming.map((tp) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car, color: AppColors.blue, size: 24),
                  ),
                  title: Text(
                    '${tp.car.make} ${tp.car.model}',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text1),
                  ),
                  subtitle: Text(
                    '${tp.bookingsCount} bookings',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3),
                  ),
                  trailing: Text(
                    _currencyFormat.format(tp.totalRevenue),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.green),
                  ),
                ),
              )),
            ],

            const SizedBox(height: 24),
            Text('Recent Bookings', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
            const SizedBox(height: 16),
            ..._recentBookings.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('Booking #${b.id.substring(0, 8)}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColors.text1)),
                subtitle: Text('${DateFormat('MMM dd').format(DateTime.parse(b.startDate))} - ${DateFormat('MMM dd').format(DateTime.parse(b.endDate))}', style: GoogleFonts.inter(color: AppColors.text3, fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(b.status, style: TextStyle(color: b.status == 'Completed' ? AppColors.green : AppColors.blue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_currencyFormat.format(b.totalPriceZmw), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subText;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text3,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF047857),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
