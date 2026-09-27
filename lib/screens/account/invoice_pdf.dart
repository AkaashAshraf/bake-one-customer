import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/models.dart';

/// Builds a clean one-page invoice PDF and opens the share sheet.
Future<void> shareInvoicePdf(InvoiceDetail d, {String? customerName}) async {
  const red = PdfColor.fromInt(0xFFE1251B);
  const ink = PdfColor.fromInt(0xFF1F1A17);
  const muted = PdfColor.fromInt(0xFF5B5552);
  const line = PdfColor.fromInt(0xFFF3E3E0);
  final inv = d.invoice;

  final doc = pw.Document(title: 'Invoice ${inv.number}', author: d.business.name);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(d.business.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: red)),
                  if (d.business.address != null) pw.Text(d.business.address!, style: const pw.TextStyle(color: muted, fontSize: 9)),
                  if (d.business.phone != null) pw.Text(d.business.phone!, style: const pw.TextStyle(color: muted, fontSize: 9)),
                  if (d.business.email != null) pw.Text(d.business.email!, style: const pw.TextStyle(color: muted, fontSize: 9)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 11, letterSpacing: 3, color: muted)),
                pw.Text(inv.number, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: ink)),
                pw.Text(formatDate(inv.date), style: const pw.TextStyle(color: muted)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(color: inv.isPaid ? const PdfColor.fromInt(0xFFDCFCE7) : const PdfColor.fromInt(0xFFFFE4E1), borderRadius: pw.BorderRadius.circular(8)),
                  child: pw.Text(inv.isPaid ? 'PAID' : 'UNPAID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: inv.isPaid ? const PdfColor.fromInt(0xFF15803D) : red)),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 2, color: red),
        pw.SizedBox(height: 14),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BILLED TO', style: const pw.TextStyle(fontSize: 8, color: muted, letterSpacing: 2)),
                pw.Text(customerName ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('TYPE', style: const pw.TextStyle(fontSize: 8, color: muted, letterSpacing: 2)),
              pw.Text(inv.isCredit ? 'Credit (CR)' : 'Cash (DR)'),
            ]),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headers: const ['Product', 'Qty', 'Price', 'Line total'],
          data: [
            for (final it in d.items) [it.productName, '${it.quantity}', money(it.unitPrice), money(it.lineTotal)],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: red),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: line))),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 230,
            child: pw.Column(children: [
              _row('Total', money(inv.total), bold: true),
              _row('Paid', money(d.paid)),
              _row('Balance due', money(inv.balanceDue), color: inv.balanceDue > 0 ? red : null, bold: true),
            ]),
          ),
        ),
        if (d.notes != null) ...[
          pw.SizedBox(height: 16),
          pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(d.notes!, style: const pw.TextStyle(color: muted)),
        ],
        pw.SizedBox(height: 30),
        pw.Center(child: pw.Text('Thank you for choosing ${d.business.name}!', style: const pw.TextStyle(color: muted))),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final safe = inv.number.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final file = File('${dir.path}/Invoice-$safe.pdf');
  await file.writeAsBytes(await doc.save());
  await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')], subject: 'Invoice ${inv.number}');
}

pw.Widget _row(String label, String value, {bool bold = false, PdfColor? color}) {
  final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(children: [pw.Expanded(child: pw.Text(label, style: style)), pw.Text(value, style: style)]),
  );
}
