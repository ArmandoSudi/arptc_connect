import '../application/assets_configuration_contracts.dart';
import '../data/firestore_assets_configuration_port.dart';
import 'assets_configuration_strings.dart';

String assetsConfigurationErrorMessage(
  Object error,
  AssetsConfigurationStrings strings,
) {
  if (error is AssetsConfigurationAccessDenied) return error.message;
  if (error is AssetsConfigurationCommandException) {
    final message = error.message.trim();
    if (error.code == 'internal' &&
        (message.isEmpty || message.toLowerCase() == 'internal')) {
      return strings.assetCommandServiceUnavailable;
    }
    return message.isEmpty ? strings.unavailable : message;
  }
  final message = error.toString();
  final opening = message.indexOf('(');
  return opening >= 0 && message.endsWith(')')
      ? message.substring(opening + 1, message.length - 1)
      : message.replaceFirst(RegExp(r'^Exception:\s*'), '');
}
