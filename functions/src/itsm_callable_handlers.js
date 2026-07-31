const {
  COMMAND_ALLOWED_ROLES,
  validateCommandEnvelope,
} = require('./itsm_command_validation');
const {
  ItsmCommandError,
  actorFrom,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('./itsm_permissions');
const { executeItsmCommand } = require('./itsm_command_service');

function createItsmCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  findAgent,
  HttpsError,
  logger,
}) {
  if (!COMMAND_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(`Cannot register unknown ITSM command: ${expectedCommand}.`);
  }

  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const envelope = validateCommandEnvelope(
        request.data,
        expectedCommand,
      );
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, COMMAND_ALLOWED_ROLES[expectedCommand]);
      const actor = actorFrom(auth, agent, role);

      return await executeItsmCommand({
        db,
        fieldValue,
        actor,
        envelope,
      });
    } catch (error) {
      if (error instanceof ItsmCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error('Unexpected ITSM command failure', {
        command: expectedCommand,
        error,
      });
      throw new HttpsError(
        'internal',
        'The ITSM command could not be completed.',
      );
    }
  };
}

module.exports = {
  createItsmCallableHandler,
};
