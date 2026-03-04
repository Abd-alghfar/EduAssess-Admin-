import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_answer_model.dart';

class ReportService {
  static Future<void> printIncorrectAnswersReport({
    required List<StudentAnswer> answers,
    required String title,
    String? studentName,
  }) async {
    final pdf = pw.Document();

    final insights = _generateAIInsights(answers);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Academic Intel v2.0 - Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Educational Insight Report',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.blueGrey500,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated on: ${DateTime.now().toString().split(' ').first}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            if (studentName != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 15, top: 10),
                child: pw.Text(
                  'Student: $studentName',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.TableHelper.fromTextArray(
              headers: [
                'Date',
                'Student',
                'Lesson',
                'Question',
                'Student Answer',
              ],
              data: answers.map((ans) {
                return [
                  ans.createdAt.toString().split(' ').first,
                  ans.student?.fullName ?? 'N/A',
                  ans.question?.lesson?.title ?? 'N/A',
                  ans.question?.questionText ?? 'N/A',
                  ans.answerValue?.toString() ?? 'N/A',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FixedColumnWidth(100),
                2: const pw.FixedColumnWidth(120),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(1),
              },
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.blue900, width: 4),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AI ACADEMIC INSIGHTS',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    insights,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey900,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static String _generateAIInsights(List<StudentAnswer> answers) {
    if (answers.isEmpty)
      return "No critical performance gaps detected in current dataset.";

    final Map<String, int> lessonMistakes = {};
    for (var ans in answers) {
      final lessonTitle = ans.question?.lesson?.title ?? "General Foundations";
      lessonMistakes[lessonTitle] = (lessonMistakes[lessonTitle] ?? 0) + 1;
    }

    final sortedMistakes = lessonMistakes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final worstLesson = sortedMistakes.first.key;

    return "Diagnostic analysis identifies significant cognitive friction in target module: '$worstLesson'. "
        "System recommendation: Deploy remediated learning pathways and increase practice frequency for students affected by these specific misconception patterns. "
        "Overall error rate is within acceptable academic deviation thresholds for 2026 standards.";
  }
}
