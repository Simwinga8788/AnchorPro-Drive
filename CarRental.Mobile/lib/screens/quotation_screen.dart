import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class QuotationScreen extends StatefulWidget {
  final String bookingId;
  const QuotationScreen({super.key, required this.bookingId});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  Booking? _booking;
  bool _loading = true;

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
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load booking: $e')));
      }
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

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final isQuote = _booking!.status == 'Pending' || _booking!.status == 'Draft';
    final title = isQuote ? 'Quotation' : 'Invoice';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateInvoicePdf(_booking!),
        pdfFileName: '${title}_${_booking!.id.substring(0, 8).toUpperCase()}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        previewPageMargin: const EdgeInsets.all(16),
      ),
    );
  }
}
