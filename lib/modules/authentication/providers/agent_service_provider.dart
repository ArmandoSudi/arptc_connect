import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../service/agent_service.dart';

final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService(ref.read(fireStoreProvider));
});



