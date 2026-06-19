import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
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
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load reports: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

      String csvStr = csv_pkg.csv.encode(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Retrix_Reports_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csvStr);

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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
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
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_startDate), style: GoogleFonts.inter(color: const Color(0xFF374151))),
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('to', style: TextStyle(color: Color(0xFF6B7280))),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM dd, yyyy').format(_endDate), style: GoogleFonts.inter(color: const Color(0xFF374151))),
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatCard('Total Revenue', currencyFormat.format(_totalRevenue), Icons.attach_money, const Color(0xFF059669)),
                      const SizedBox(height: 12),
                      _buildStatCard('Total Bookings', '$_totalBookings', Icons.calendar_today, const Color(0xFF2563EB)),
                      const SizedBox(height: 12),
                      _buildStatCard('Completed Rentals', '$_completedBookings', Icons.check_circle_outline, const Color(0xFFD97706)),
                      
                      const SizedBox(height: 30),
                      Text(
                        'Top Performing Vehicles',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: _topVehicles.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text('No data for this period', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                                ),
                              )
                            : Column(
                                children: _topVehicles.map((v) {
                                  return Column(
                                    children: [
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.directions_car, color: Color(0xFF2563EB)),
                                        ),
                                        title: Text('${v['make']} ${v['model']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                                        subtitle: Text('${v['count']} Bookings', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                                        trailing: Text(
                                          currencyFormat.format(v['rev']),
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                                        ),
                                      ),
                                      if (v != _topVehicles.last) const Divider(height: 1, color: Color(0xFFE5E7EB)),
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

