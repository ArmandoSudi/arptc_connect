import 'dart:convert';
import 'dart:html' as html;

Future<void> downloadBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  html.AnchorElement(
    href: 'data:$mimeType;base64,${base64.encode(bytes)}',
  )
    ..setAttribute('download', fileName)
    ..click();
}

Future<void> openUrlForDownload({
  required String url,
  required String fileName,
}) async {
  html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = fileName
    ..click();
}
