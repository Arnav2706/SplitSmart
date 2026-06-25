import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/settlement.dart';

class ExportService {
  /// Generates a PDF ledger for the group and returns the file path.
  static Future<String> generatePdf({
    required Group group,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('SplitSmart Ledger: ${group.name}',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Generated on $dateStr  |  Members: ${group.members.length}  |  Currency: ${group.currency}'),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Expenses (${expenses.length})')),
            if (expenses.isEmpty)
              pw.Text('No expenses recorded.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Paid By', 'Amount (INR)'],
                data: expenses.map((e) {
                  final d = e.date;
                  final dateLabel = '${d.day}/${d.month}/${d.year}';
                  return [
                    dateLabel,
                    e.description,
                    e.category,
                    e.paidBy == 'local_user' ? 'You' : e.paidBy,
                    (e.amount / 100).toStringAsFixed(2),
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 24),
            pw.Header(level: 1, child: pw.Text('Simplified Settlements')),
            if (settlements.isEmpty)
              pw.Text('All balances are settled!')
            else
              pw.TableHelper.fromTextArray(
                headers: ['From', 'To', 'Amount (INR)', 'Status'],
                data: settlements.map((s) => [
                  s.fromUserId == 'local_user' ? 'You' : s.fromUserId,
                  s.toUserId == 'local_user' ? 'You' : s.toUserId,
                  (s.amount / 100).toStringAsFixed(2),
                  s.status,
                ]).toList(),
              ),
          ];
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/splitsmart_${group.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generates a CSV file of all expenses and returns the file path.
  static Future<String> generateCsv({
    required Group group,
    required List<Expense> expenses,
  }) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Date,Description,Category,Amount (INR),Paid By,Split Type,Group');

    // Data rows
    for (var e in expenses) {
      final d = e.date;
      final dateLabel = '${d.day}/${d.month}/${d.year}';
      final paidBy = e.paidBy == 'local_user' ? 'You' : e.paidBy;
      final amount = (e.amount / 100).toStringAsFixed(2);
      // Escape commas in description
      final desc = e.description.contains(',') ? '"${e.description}"' : e.description;
      buffer.writeln('$dateLabel,$desc,${e.category},$amount,$paidBy,${e.splitType.name},${group.name}');
    }

    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/splitsmart_${group.id}.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
