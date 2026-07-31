'use strict';

const {
  ItsmCommandError,
  actorFrom,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('./itsm_permissions');
const { executeAssetsCommand } = require('./itsm_assets_service');
const {
  ASSETS_COMMAND_ALLOWED_ROLES,
  validateAssetsCommand,
} = require('./itsm_assets_validation');

function createItsmAssetsCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  findAgent,
  HttpsError,
  logger,
}) {
  if (!ASSETS_COMMAND_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(`Cannot register unknown assets command: ${expectedCommand}.`);
  }

  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const command = validateAssetsCommand(request.data, expectedCommand);
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, ASSETS_COMMAND_ALLOWED_ROLES[expectedCommand]);
      const actor = actorFrom(auth, agent, role);
      return await executeAssetsCommand({ db, fieldValue, actor, command });
    } catch (error) {
      if (error instanceof ItsmCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error(
        'Unexpected ITSM assets command failure',
        safeUnexpectedError(expectedCommand, error),
      );
      throw new HttpsError(
        'internal',
        'The ITSM assets command could not be completed.',
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

module.exports = { createItsmAssetsCallableHandler, safeUnexpectedError };
