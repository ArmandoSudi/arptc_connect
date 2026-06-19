Future<void> downloadBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  throw UnsupportedError('File downloads are only implemented for web.');
}

Future<void> openUrlForDownload({
  required String url,
  required String fileName,
}) async {
  throw UnsupportedError('File downloads are only implemented for web.');
}
