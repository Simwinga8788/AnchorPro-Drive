import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(Booking booking) async {
    final pdf = pw.Document();

    final isQuote = booking.status == 'Pending' || booking.status == 'Draft';
    final documentTitle = isQuote ? 'QUOTATION' : 'INVOICE';

    // Financial calculations
    final baseRentalPrice = booking.totalPriceZmw;
    final damageFees = booking.payments?.where((p) => p.type == 'Penalty').toList() ?? [];
    final totalDamageFees = damageFees.fold(0.0, (sum, p) => sum + p.amountZmw);
    final totalCharges = baseRentalPrice + totalDamageFees;
    final completedPayments = booking.payments?.where((p) => p.status == 'Completed').toList() ?? [];
    final totalPaid = completedPayments.fold(0.0, (sum, p) => sum + p.amountZmw);
    final balanceDue = totalCharges - totalPaid;

    final days = DateTime.parse(booking.endDate).difference(DateTime.parse(booking.startDate)).inDays;
    final rentalDays = days < 1 ? 1 : days;
    final rate = baseRentalPrice / rentalDays;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Retrix Car Rental', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 8),
                      pw.Text('Lusaka, Zambia', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text('retrixrentals@gmail.com', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text('Facebook: Retrix Car Rental', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text('0962431222', style: const pw.TextStyle(color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(documentTitle, style: pw.TextStyle(fontSize: 28, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}'),
                      pw.Text('Ref #: ${booking.id.substring(0, 8).toUpperCase()}'),
                      pw.Text('Status: ${booking.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isQuote ? PdfColors.orange500 : PdfColors.green500)),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 20),

              // Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text('${booking.customer?.firstName ?? 'Guest'} ${booking.customer?.lastName ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(booking.customer?.phoneNumber ?? 'Phone not provided'),
                        pw.Text("Driver's License: ${booking.customer?.driverLicenseNumber ?? 'N/A'}"),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Rental Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text('Vehicle: ${booking.car?.make} ${booking.car?.model}'),
                        pw.Text('Dates: ${DateFormat('MM/dd/yyyy').format(DateTime.parse(booking.startDate))} to ${DateFormat('MM/dd/yyyy').format(DateTime.parse(booking.endDate))}'),
                        pw.Text('Pickup: ${booking.pickupLocation?.name ?? 'Head Office'}'),
                        pw.Text('Dropoff: ${booking.dropoffLocation?.name ?? 'Head Office'}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Line Items
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                data: [
                  ['Description', 'Days', 'Rate (ZMW)', 'Amount (ZMW)'],
                  ['Vehicle Rental (${booking.car?.make} ${booking.car?.model})', '$rentalDays', rate.toStringAsFixed(2), baseRentalPrice.toStringAsFixed(2)],
                  if (totalDamageFees > 0) ['Damage & Penalty Fees', '-', '-', totalDamageFees.toStringAsFixed(2)],
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Charges:'), pw.Text('ZMW ${totalCharges.toStringAsFixed(2)}')]),
                        pw.SizedBox(height: 4),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Paid:'), pw.Text('ZMW ${totalPaid.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.green600))]),
                        pw.Divider(),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Balance Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('ZMW ${balanceDue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red600))
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  isQuote ? 'This quotation is valid for 7 days.' : 'Thank you for choosing Retrix Car Rental!',
                  style: const pw.TextStyle(color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
