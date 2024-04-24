import 'dart:convert';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:arptc_connect/modules/ticketing/domain/ticket.dart';
import 'package:flutter/services.dart';

import '../../../../utils/pdf_api.dart';
import '../../../administration/domain/models/agent.dart';

class VoucherService {
  Future<void> generateVoucher(Agent agent) async {
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
            child: pw.Column(
              children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(
                        pw.MemoryImage(image),
                        width: 50,
                        height: 50,
                        fit: pw.BoxFit.fill,
                      ),
                      pw.Text(
                        'Kinshasa, le ${DateTime.now().formatedDate}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ]),
                pw.Text(
                  'Bon Médical no: 1234',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 45),
              ],
            ),
          );
        },
        build: (context) => [_content(context, agent)],
        // orientation: pw.PageOrientation.landscape,
      ),
    );

    return PdfApi.downloadDocument(pdf);
  }


  pw.Widget _content(pw.Context context, Agent agent) {
    const tableHeaders = ['#', 'Date', 'Intervenant', 'Demandeur', 'Object'];

    return pw.Column(
      children: [
        pw.Text(
            "Nom de l'agent ${agent.name} avec le matricule AR08/201, Quittant le travail le ${DateTime.now().formatedDate}"),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Signature du demandeur"),
            pw.Text("Signature autorisée"),
          ],
        ),
      ],
    );
  }
}
