
import 'package:pdf/widgets.dart' as pw;

import 'package:arptc_connect/extensions/date_extension.dart';
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

    return PdfApi.downloadDocument(pdf, title: "bon_medical_${agent.name}");
  }

  Future<void> generateAttestation(Agent agent) async {
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
                        width: 80,
                        height: 50,
                        fit: pw.BoxFit.fill,
                      ),
                    ]),
                pw.SizedBox(height: 10),
                pw.Text(
                  'ATTESTATION DE SERVICE',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold),
                ),
                // pw.SizedBox(height: 10),
                pw.Text(
                  'No ARPTC/DRH/003/02/2025',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold
                  ),
                ),
                pw.SizedBox(height: 10),


              ],
            ),
          );
        },
        build: (context) => [_content(context, agent)],
        // orientation: pw.PageOrientation.landscape,
      ),
    );

    return PdfApi.downloadDocument(pdf, title: "attestation_${agent.name}");
  }

  pw.Widget _content(pw.Context context, Agent agent) {
    const tableHeaders = ['#', 'Date', 'Intervenant', 'Demandeur', 'Object'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Text(
          "Je soussigné MUTOMBO AGE Papy, Directeur des Ressources "
              "Humaines a.i à l'Autorité de Régulations de la Poste et des "
              "Télécommunications du Congo ARPTC en sigle,"
              " atteste par la présente que Monsieur ${agent.name}, "
              "Cadre à la Direction des Systèmes d'Information, fait partie "
              "du personnel de cet organe de régulation",
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 14, lineSpacing: 2.0),
        ),
        pw.SizedBox(height: 10),
        pw.Text("Son contrat est à durée inderterminée sous le numéro matricule AR/00201/18 depuis 2018",
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 14,),
        ),
        pw.SizedBox(height: 10),
        pw.Text("La présente attestation est délivrée à l'intéressé pour servir et valoir ce que de droit.",
          style: const pw.TextStyle(fontSize: 14,),),
        pw.SizedBox(height: 20),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                "Fait à Kinshasa, le ${DateTime.now().formatedDate}",
                style: const pw.TextStyle(fontSize: 14),
              ),
            ]
        ),
        pw.SizedBox(height: 25),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    "MUTOMBO AGE Papy",
                    style: pw.TextStyle(fontSize: 12,fontWeight: pw.FontWeight.bold,),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Directeur a.i.",
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ]
              )
            ]
        ),
      ],
    );
  }

}
