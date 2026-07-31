import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';

class ConfigurationItemQuery {
  const ConfigurationItemQuery({
    this.type,
    this.operationalStatus,
    this.criticality,
    this.supportGroupId = '',
  });

  final ConfigurationItemType? type;
  final CiOperationalStatus? operationalStatus;
  final CiCriticality? criticality;
  final String supportGroupId;
}

abstract interface class CmdbRepository {
  Future<PageResult<ConfigurationItem>> fetchItemsPage({
    required ConfigurationItemQuery query,
    required PageRequest page,
  });

  Stream<ConfigurationItem?> watchItem(String configurationItemId);

  Future<PageResult<CiRelationship>> fetchOutgoingRelationships({
    required String configurationItemId,
    required PageRequest page,
  });

  Future<PageResult<CiRelationship>> fetchIncomingRelationships({
    required String configurationItemId,
    required PageRequest page,
  });
}
