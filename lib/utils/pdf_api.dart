// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:arptc_connect/utils/download_helper.dart';
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
    await downloadBytes(
      bytes: fileInts,
      fileName:
          "${title ?? "rapport"}_${DateTime.now().millisecondsSinceEpoch}.pdf",
      mimeType: 'application/pdf',
    );
  }

  static Future<void> downloadExcel(List<int> excelBytes,
      {String? title}) async {
    await downloadBytes(
      bytes: excelBytes,
      fileName:
          "${title ?? "report"}_${DateTime.now().millisecondsSinceEpoch}.xlsx",
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}
