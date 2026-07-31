'use strict';

const {
  ItsmCommandError,
  actorFrom,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('./itsm_permissions');
const {
  executeSupportCommand,
} = require('./itsm_support_service');
const {
  SUPPORT_COMMAND_ALLOWED_ROLES,
  validateSupportCommand,
} = require('./itsm_support_validation');

function createItsmSupportCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  timestamp,
  findAgent,
  HttpsError,
  logger,
}) {
  if (!SUPPORT_COMMAND_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(`Cannot register unknown support command: ${expectedCommand}.`);
  }

  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const command = validateSupportCommand(request.data, expectedCommand);
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, SUPPORT_COMMAND_ALLOWED_ROLES[expectedCommand]);
      const actor = actorFrom(auth, agent, role);

      return await executeSupportCommand({
        db,
        fieldValue,
        timestamp,
        actor,
        agent,
        command,
      });
    } catch (error) {
      if (error instanceof ItsmCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error('Unexpected ITSM support command failure', {
        command: expectedCommand,
        error,
      });
      throw new HttpsError(
        'internal',
        'The ITSM support command could not be completed.',
      );
    }
  };
}

module.exports = {
  createItsmSupportCallableHandler,
};
