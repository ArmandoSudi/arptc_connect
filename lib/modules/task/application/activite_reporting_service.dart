import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/services.dart';

import '../../../utils/pdf_api.dart';

class ActiviteReportingService {
  Future<void> generateReport(List<Task> tasks) async {
    final pdf = pw.Document();
    // var font = await PdfGoogleFonts.abelRegular();

    final image = (await rootBundle.load("assets/icons/app_logo.jpg"))
        .buffer
        .asUint8List();

    pdf.addPage(
      pw.MultiPage(
        header: (context) {
          return pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(
                      pw.MemoryImage(image),
                      width: 80,
                      height: 50,
                      fit: pw.BoxFit.fill,
                    ),
                    pw.SizedBox(width: 30),
                    pw.Text("Kinshasa, le ${DateTime.now().formatedDate}")
                  ],
                ),
                pw.Text(
                  'Direction des Systèmes d\'Information',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Rapport Hebdomadaire',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ]));
        },
        build: (context) => [
          pw.Text("Courriers"),
          pw.SizedBox(height: 5),
          _mailTable(context,
              tasks.where((task) => task.type == TaskType.mail).toList()),
          pw.SizedBox(height: 10),
          pw.Text("Projets / Autres traitements"),
          pw.SizedBox(height: 5),
          _projectTable(context,
              tasks.where((task) => task.type == TaskType.task).toList()),
        ],
        orientation: pw.PageOrientation.landscape,
      ),
    );

    return PdfApi.downloadDocument(pdf, title: "rapport hebdomadaire");
  }

  static pw.Widget buildEntityTitle() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Direction des Systèmes d\'Information',
          style: const pw.TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  static pw.Widget buildReportTitle() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Rapport hebdomadaire',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Generate a _contentTable with the tasks
  pw.Widget _mailTable(pw.Context context, List<Task> tasks) {
    const tableHeaders = [
      'No',
      'Date',
      'Expéditeur',
      'Objet',
      'A/R',
      'Annotations',
      'Traitement',
      'Remarque'
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 25,
      cellHeight: 40,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: tableHeaders,
      data: List<List<String>>.generate(
        tasks.length,
        (row) => [
          (row + 1).toString(), // No
          tasks[row].reportingDate.formatedDate, // Date
          tasks[row].sender.trim().isEmpty
              ? " - "
              : tasks[row].sender, // Expéditeur
          tasks[row].label, // Objet
          tasks[row].receptionDate?.formatedDate ?? " - ", // A/R
          tasks[row]
                  .annotations
                  ?.entries
                  .map((entry) => "${entry.key}: ${entry.value}")
                  .join("\n") ??
              " - ", // Annotations
          tasks[row].status.value, // Traitement
          tasks[row].observation, // Remarque
        ],
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(25), // No
        1: const pw.FixedColumnWidth(65), // Date
        2: const pw.FixedColumnWidth(80), // Expéditeur
        3: const pw.FlexColumnWidth(), // Objet
        4: const pw.FixedColumnWidth(65), // A/R
        5: const pw.FlexColumnWidth(), // Annotations
        6: const pw.FixedColumnWidth(62), // Traitement
        7: const pw.FlexColumnWidth(), // Remarque
      },
    );
  }

  pw.Widget _projectTable(pw.Context context, List<Task> tasks) {
    const tableHeaders = [
      'No',
      'Date',
      'Initiateur',
      'Objet',
      'Traitement',
      'Remarque'
    ];

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(),
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 25,
      cellHeight: 40,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: tableHeaders,
      data: List<List<String>>.generate(
        tasks.length,
        (row) => [
          (row + 1).toString(), // No
          tasks[row].reportingDate.formatedDate, // Date
          tasks[row].sender.trim().isEmpty
              ? " - "
              : tasks[row].sender, // Expéditeur
          tasks[row].label, // Objet // Annotations
          tasks[row].status.value, // Traitement
          tasks[row].observation, // Remarque
        ],
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(25), // No
        1: const pw.FixedColumnWidth(65), // Date
        2: const pw.FixedColumnWidth(80), // Expéditeur
        3: const pw.FlexColumnWidth(), // Annotations
        4: const pw.FixedColumnWidth(68), // Traitement
        5: const pw.FlexColumnWidth(), // Remarque
      },
    );
  }
}
