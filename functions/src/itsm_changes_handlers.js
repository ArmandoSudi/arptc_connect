'use strict';

const {
  ItsmCommandError,
  actorFrom,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('./itsm_permissions');
const { executeChangesCommand } = require('./itsm_changes_service');
const {
  CHANGES_COMMAND_ALLOWED_ROLES,
  validateChangesCommand,
} = require('./itsm_changes_validation');

function createItsmChangesCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  timestamp,
  findAgent,
  HttpsError,
  logger,
  serviceDependencies,
}) {
  if (!CHANGES_COMMAND_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(`Cannot register unknown change command: ${expectedCommand}.`);
  }
  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const command = validateChangesCommand(request.data, expectedCommand);
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, CHANGES_COMMAND_ALLOWED_ROLES[expectedCommand]);
      const actor = actorFrom(auth, agent, role);
      return await executeChangesCommand({
        db,
        fieldValue,
        timestamp,
        actor,
        command,
        dependencies: serviceDependencies,
      });
    } catch (error) {
      if (error instanceof ItsmCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error(
        'Unexpected ITSM change command failure',
        safeUnexpectedError(expectedCommand, error),
      );
      throw new HttpsError(
        'internal',
        'The ITSM change command could not be completed.',
      );
    }
  };
}

function safeUnexpectedError(command, error) {
  const stack = typeof error?.stack === 'string'
    ? error.stack.split('\n').slice(0, 20).join('\n').slice(0, 8000)
    : '';
  return {
    command,
    errorName: typeof error?.name === 'string' ? error.name.slice(0, 160) : 'Error',
    errorCode: typeof error?.code === 'string' ? error.code.slice(0, 160) : '',
    errorMessage: typeof error?.message === 'string'
      ? error.message.slice(0, 2000)
      : 'Unknown unexpected error.',
    errorStack: stack,
  };
}

module.exports = {
  createItsmChangesCallableHandler,
  safeUnexpectedError,
};
