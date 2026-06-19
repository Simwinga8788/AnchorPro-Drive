import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../models/booking.dart';
import 'package:intl/intl.dart';

class QuotationScreen extends StatefulWidget {
  final String bookingId;
  const QuotationScreen({super.key, required this.bookingId});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await ApiService.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load booking: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final isQuote = _booking!.status == 'Pending' || _booking!.status == 'Draft';
    final title = isQuote ? 'Quotation' : 'Invoice';
    final currencyFormat = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

    final baseRentalPrice = _booking!.totalPriceZmw;
    final damageFees = _booking!.payments?.where((p) => p.type == 'Penalty').toList() ?? [];
    final totalDamageFees = damageFees.fold(0.0, (sum, p) => sum + p.amountZmw);
    final totalCharges = baseRentalPrice + totalDamageFees;
    
    final completedPayments = _booking!.payments?.where((p) => p.status == 'Completed').toList() ?? [];
    final totalPaid = completedPayments.fold(0.0, (sum, p) => sum + p.amountZmw);
    final balanceDue = totalCharges - totalPaid;

    final days = DateTime.parse(_booking!.endDate).difference(DateTime.parse(_booking!.startDate)).inDays;
    final rentalDays = days < 1 ? 1 : days;
    final rate = baseRentalPrice / rentalDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              final pdfBytes = await PdfService.generateInvoicePdf(_booking!);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${title}_${_booking!.id.substring(0, 8).toUpperCase()}.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retrix Car Rental', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Text('Lusaka, Zambia', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
                        Text('0962431222', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isQuote ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _booking!.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: isQuote ? const Color(0xFFD97706) : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 24),

              // Two Column Info for Desktop / Tablets, Wrapped for Mobile
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bill To', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('${_booking!.customer?.firstName ?? 'Guest'} ${_booking!.customer?.lastName ?? ''}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Text(_booking!.customer?.phoneNumber ?? 'Phone not provided', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("DL: ${_booking!.customer?.driverLicenseNumber ?? 'N/A'}", style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rental Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Ref: ${_booking!.id.substring(0, 8).toUpperCase()}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Vehicle: ${_booking!.car?.make} ${_booking!.car?.model}', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              // Line Items
              Text('Charges', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
              const SizedBox(height: 12),
              
              // Vehicle Rental Line
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle Rental', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                          Text('${_booking!.car?.make} ${_booking!.car?.model}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text('$rentalDays Days\n@ ${currencyFormat.format(rate)}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563))),
                    ),
                    Expanded(
                      child: Text(
                        currencyFormat.format(baseRentalPrice),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Damages Line
              if (totalDamageFees > 0)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('Damage & Penalty Fees', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                      ),
                      Expanded(child: Text('-', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)))),
                      Expanded(
                        child: Text(
                          currencyFormat.format(totalDamageFees),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              
              // Totals
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Charges:', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                          Text(currencyFormat.format(totalCharges), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Paid:', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                          Text(currencyFormat.format(totalPaid), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF059669))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Balance Due:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1F2937))),
                          Text(currencyFormat.format(balanceDue), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFFDC2626))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              Center(
                child: Text(
                  isQuote ? 'This quotation is valid for 7 days.' : 'Thank you for choosing Retrix Car Rental!',
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () async {
              final pdfBytes = await PdfService.generateInvoicePdf(_booking!);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${title}_${_booking!.id.substring(0, 8).toUpperCase()}.pdf',
              );
            },
            icon: const Icon(Icons.share),
            label: Text('Share / Download PDF', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
