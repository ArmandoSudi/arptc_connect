import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import 'assets_configuration_contracts.dart';

class AssetsConfigurationAccessPolicy {
  const AssetsConfigurationAccessPolicy();

  bool canReadMyAssets(ItsmSession session) => session.userId.trim().isNotEmpty;

  bool canOperate(ItsmSession session) => session.role == ItsmRole.manager;

  void authorizeMyAssets(ItsmSession session) {
    if (!canReadMyAssets(session)) {
      throw const AssetsConfigurationAccessDenied(
        'An authenticated ITSM session is required.',
      );
    }
  }

  void authorizeOperational(ItsmSession session) {
    if (!canOperate(session)) {
      throw const AssetsConfigurationAccessDenied(
        'Only a MANAGER can access Assets & Configuration operations.',
      );
    }
  }
}
