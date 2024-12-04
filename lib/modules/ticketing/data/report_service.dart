import 'dart:convert';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/ticketing/domain/ticket.dart';
import 'package:flutter/services.dart';

import '../../../utils/pdf_api.dart';

class ReportService {

  Future<void> generateReport(List<Ticket> tickets) async {
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
            child: pw.Row(children: [
              pw.Image(
                pw.MemoryImage(image),
                width: 50,
                height: 50,
                fit: pw.BoxFit.fill,
              ),
              pw.SizedBox(width: 30),
              pw.Column(children: [
                pw.Text(
                  'Direction des Systèmes d\'Information',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Rapport de support IT',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],),
            ],),
          );
        },
        build: (context) => [
          _contentTable(context, tickets)
        ],
        orientation: pw.PageOrientation.landscape,
      ),
    );

    return PdfApi.downloadDocument(pdf);
  }

  static pw.Widget buildEntityTitle() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Direction des Systèmes d\'Information',
          style: pw.TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  static pw.Widget buildReportTitle() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Rapport de support IT',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _contentTable(pw.Context context, List<Ticket> tickets) {
    const tableHeaders = [
      '#',
      'Date',
      'Intervenant',
      'Demandeur',
      'Object'
    ];

    return pw.TableHelper.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
        color: PdfColors.blue,
      ),
      headerHeight: 25,
      cellHeight: 40,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        color: PdfColors.blueGrey800,
        fontSize: 10,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blueGrey800,
            width: .5,
          ),
        ),
      ),
      headers: List<String>.generate(
        tableHeaders.length,
            (col) => tableHeaders[col],
      ),
      data: List<List<String>>.generate(
        tickets.length,
            (row) => List<String>.generate(
          tableHeaders.length,
              (col) => tickets[row].getField(row, col),
        ),
      ),
      columnWidths: {
        // Specify fixed width for each column
        0: pw.FixedColumnWidth(15), // 50 units width for the first column
        1: pw.FixedColumnWidth(80), // 80 units width for the second column
        2: pw.FixedColumnWidth(80), // 100 units width for the third column
        3: pw.FixedColumnWidth(80), // 120 units width for the fourth column
        4: pw.FlexColumnWidth(), // 150 units width for the fifth column
      },
    );
  }

}
