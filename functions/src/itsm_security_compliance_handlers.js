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
  executeSecurityComplianceCommand,
} = require('./itsm_security_compliance_service');
const {
  SECURITY_COMPLIANCE_ALLOWED_ROLES,
  validateSecurityComplianceCommand,
} = require('./itsm_security_compliance_validation');

function createItsmSecurityComplianceCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  timestamp,
  findAgent,
  HttpsError,
  logger,
  serviceDependencies,
}) {
  if (!SECURITY_COMPLIANCE_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(`Cannot register unknown security command: ${expectedCommand}.`);
  }
  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const command = validateSecurityComplianceCommand(
        request.data,
        expectedCommand,
      );
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, SECURITY_COMPLIANCE_ALLOWED_ROLES[expectedCommand]);
      const actor = actorFrom(auth, agent, role);
      return await executeSecurityComplianceCommand({
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
        'Unexpected ITSM security command failure',
        safeUnexpectedError(expectedCommand, error),
      );
      throw new HttpsError(
        'internal',
        'The ITSM security command could not be completed.',
      );
    }
  };
}

function safeUnexpectedError(command, error) {
  return {
    command,
    errorName: typeof error?.name === 'string'
      ? error.name.slice(0, 160)
      : 'Error',
    errorCode: typeof error?.code === 'string'
      ? error.code.slice(0, 160)
      : '',
    errorMessage: typeof error?.message === 'string'
      ? error.message.slice(0, 2000)
      : 'Unknown unexpected error.',
    errorStack: typeof error?.stack === 'string'
      ? error.stack.split('\n').slice(0, 20).join('\n').slice(0, 8000)
      : '',
  };
}

module.exports = {
  createItsmSecurityComplianceCallableHandler,
  safeUnexpectedError,
};
