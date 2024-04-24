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
  // Future<void> printTicketReport(List<Ticket> tickets) async {
  //   PdfDocument document = PdfDocument();
  //   document.pageSettings.orientation = PdfPageOrientation.landscape;
  //   PdfGrid grid = PdfGrid();
  //
  //
  //   grid.columns.add(count: 5);
  //
  //   // Add header to the grid
  //   grid.headers.add(1);
  //
  //   PdfGridRow header = grid.headers[0];
  //   header.cells[0].value = 'Date';
  //   header.cells[1].value = 'Intervenant';
  //   header.cells[2].value = 'Agent';
  //   header.cells[3].value = 'Problème';
  //   header.cells[4].value = 'Solution';
  //
  //   header.style = PdfGridCellStyle(
  //     backgroundBrush: PdfSolidBrush(PdfColor(68, 114, 196)),
  //     textBrush: PdfBrushes.white,
  //     font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
  //   );
  //
  //   for (Ticket ticket in tickets) {
  //     PdfGridRow row = grid.rows.add();
  //     row.cells[0].value = ticket.creationDate.formatedDate;
  //     row.cells[1].value = ticket.author;
  //     row.cells[2].value = ticket.agent;
  //     row.cells[3].value = ticket.subject;
  //     row.cells[4].value = ticket.solution;
  //   }
  //
  //   grid.style = PdfGridStyle(
  //     cellPadding: PdfPaddings(left: 2, right: 2, top: 2, bottom: 2),
  //   );
  //
  //   //Adds a page to the document
  //   PdfPage page = document.pages.add();
  //
  //   final imageData = await rootBundle.load('assets/icons/app_logo.jpg'); // Assuming image in assets folder
  //   final imageBytes = imageData.buffer.asUint8List();
  //   final pdfImage = PdfBitmap(imageBytes);
  //
  //   page.graphics.drawImage(
  //       pdfImage,
  //       Rect.fromLTWH(
  //           0, 0, page.getClientSize().width, page.getClientSize().height));
  //
  //   grid.draw(
  //     page: document.pages.add(),
  //     bounds: Rect.fromLTWH(0, 0, 0, 0),
  //   );
  //
  //   List<int> bytes = await document.save();
  //
  //   // Download document
  //   AnchorElement(href: 'data:application/octet-stream;base64,${base64.encode(bytes)}')
  //     ..setAttribute('download', 'ticket_report.pdf')
  //     ..click();
  //
  //   // Dispose the document
  //    document.dispose();
  // }

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
          style: pw.TextStyle(fontSize: 12),
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
              (col) => tickets[row].getIndex(col),
        ),
      ),
    );
  }

}
