import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  double _totalRevenue = 0;
  int _totalBookings = 0;
  int _completedBookings = 0;
  List<Map<String, dynamic>> _topVehicles = [];
  List<Map<String, dynamic>> _revenueByDay = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _loading = true);
    try {
      final bookings = await ApiService.getBookings();
      final cars = await ApiService.getCars();

      final startMs = _startDate.millisecondsSinceEpoch;
      final endMs = _endDate.add(const Duration(days: 1)).millisecondsSinceEpoch;

      double totalRev = 0;
      int completedCount = 0;
      int totalCount = 0;

      final Map<String, double> dailyRev = {};
      final Map<String, Map<String, dynamic>> vehicleStats = {};

      for (var c in cars) {
        vehicleStats[c.id] = {'make': c.make, 'model': c.model, 'rev': 0.0, 'count': 0};
      }

      for (var b in bookings) {
        if (b.createdAt != null) {
          final bDate = DateTime.parse(b.createdAt!).millisecondsSinceEpoch;
          if (bDate >= startMs && bDate < endMs) {
            totalCount++;
            if (b.status != 'Cancelled') {
              final rev = b.totalPriceZmw;
              totalRev += rev;
              if (b.status == 'Completed') completedCount++;

              final dayKey = b.createdAt!.split('T')[0];
              dailyRev[dayKey] = (dailyRev[dayKey] ?? 0) + rev;

              if (vehicleStats.containsKey(b.carId)) {
                vehicleStats[b.carId]!['rev'] = (vehicleStats[b.carId]!['rev'] as double) + rev;
                vehicleStats[b.carId]!['count'] = (vehicleStats[b.carId]!['count'] as int) + 1;
              }
            }
          }
        }
      }

      final revByDayList = dailyRev.entries.map((e) => {'date': e.key, 'Revenue': e.value}).toList();
      revByDayList.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      final topVehiclesList = vehicleStats.values.where((v) => (v['count'] as int) > 0).toList();
      topVehiclesList.sort((a, b) => (b['rev'] as double).compareTo(a['rev'] as double));

      if (mounted) {
        setState(() {
          _totalRevenue = totalRev;
          _totalBookings = totalCount;
          _completedBookings = completedCount;
          _revenueByDay = revByDayList;
          _topVehicles = topVehiclesList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load reports: $e')));
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["Retrix Reports - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"]);
      rows.add(["Date Range:", DateFormat('yyyy-MM-dd').format(_startDate), "to", DateFormat('yyyy-MM-dd').format(_endDate)]);
      rows.add([]);
      rows.add(["Total Revenue ZMW", _totalRevenue]);
      rows.add(["Total Bookings", _totalBookings]);
      rows.add(["Completed Bookings", _completedBookings]);
      rows.add([]);
      rows.add(["Top Vehicles"]);
      rows.add(["Make", "Model", "Bookings", "Revenue ZMW"]);
      
      for (var v in _topVehicles) {
        rows.add([v['make'], v['model'], v['count'], v['rev']]);
      }

      String csvString = csv.encode(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Retrix_Reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csvString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Retrix Custom Report',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) _startDate = _endDate;
        }
      });
      _fetchReportData();
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text1)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('to')),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.text3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildStatCard('Total Revenue', 'ZMW ${_totalRevenue.toStringAsFixed(0)}', Icons.attach_money, AppColors.gold),
                      const SizedBox(height: 12),
                      _buildStatCard('Total Bookings', '$_totalBookings', Icons.calendar_today, AppColors.blue),
                      const SizedBox(height: 12),
                      _buildStatCard('Completed Rentals', '$_completedBookings', Icons.check_circle_outline, AppColors.green),
                      
                      const SizedBox(height: 30),
                      const Text('Top Performing Vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text1)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: _topVehicles.isEmpty
                            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No data for this period')))
                            : Column(
                                children: _topVehicles.map((v) {
                                  return Column(
                                    children: [
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.directions_car, color: AppColors.blue),
                                        ),
                                        title: Text('${v['make']} ${v['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${v['count']} Bookings'),
                                        trailing: Text('ZMW ${v['rev'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
                                      ),
                                      if (v != _topVehicles.last) const Divider(height: 1),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
