import 'dart:convert';
import 'dart:html';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';

class PdfApi {

  // static Future<File> saveDocument({
  //   required String name,
  //   required Document pdf,
  // }) async {
  //   final bytes = await pdf.save();
  //   var dir;
  //
  //   // Getting the directory differs based on the platform
  //   if (Platform.isIOS) {
  //     dir = await getApplicationDocumentsDirectory();
  //   } else {
  //     dir = await getExternalStorageDirectory();
  //   }
  //
  //   // FOR ANDROID
  //   // final dir = await getExternalStorageDirectory();
  //
  //   final file = File('${dir!.path}/$name');
  //   log("SAVED FILE PATH ==> ${file.path}");
  //
  //   await file.writeAsBytes(bytes);
  //
  //   return file;
  // }

  // static Future openFile(File file) async {
  //   final url = file.path;
  //   log("OPEN FILE PATH ==> $url");
  //   try {
  //     var openResult = await OpenFile.open(url);
  //     log("OPEN RESULT :: ${openResult.message}");
  //   } catch(e) {
  //     log("OPEN FILE ERROR:: $e");
  //   }
  // }

  // Future<String> localPath() async {
  //   final directory = await getApplicationDocumentsDirectory();
  //
  //   return directory.path;
  // }

  // Future<File>  localFile() async {
  //   final path = await localPath();
  //   return File('$path/invoice.pdf');
  // }

  static Future<void> downloadDocument(Document pdf, {String? title}) async {
    var savedFile = await pdf.save();
    List<int> fileInts = List.from(savedFile);

    // Download document
    AnchorElement(href: 'data:application/octet-stream;base64,${base64.encode(fileInts)}')
      ..setAttribute('download', "${title ?? "rapport"}_${DateTime.now().millisecondsSinceEpoch}.pdf")
      ..click();
  }

  static Future<void> downloadExcel(List<int> excelBytes, {String? title}) async {
    // Convert the Excel bytes to a Base64 string
    final base64Excel = base64.encode(excelBytes);

    // Create a downloadable link
    AnchorElement(href: 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Excel')
      ..setAttribute('download', "${title ?? "report"}_${DateTime.now().millisecondsSinceEpoch}.xlsx")
      ..click();
  }
}
