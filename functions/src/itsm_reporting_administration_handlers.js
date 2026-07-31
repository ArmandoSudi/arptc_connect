'use strict';

const {
  ItsmCommandError,
  actorFrom,
  normalizeString,
  requireActiveAgent,
  requireAuthentication,
  requireRole,
  resolveItsmRole,
} = require('./itsm_permissions');
const {
  executeReportingAdministrationCommand,
} = require('./itsm_reporting_administration_service');
const {
  REPORTING_ADMINISTRATION_ALLOWED_ROLES,
  validateReportingAdministrationCommand,
} = require('./itsm_reporting_administration_validation');

function createItsmReportingAdministrationCallableHandler({
  expectedCommand,
  db,
  fieldValue,
  timestamp,
  findAgent,
  HttpsError,
  logger,
}) {
  if (!REPORTING_ADMINISTRATION_ALLOWED_ROLES[expectedCommand]) {
    throw new Error(
      `Cannot register unknown Reporting & Administration command: ${expectedCommand}.`,
    );
  }
  return async (request) => {
    try {
      const auth = requireAuthentication(request.auth);
      const command = validateReportingAdministrationCommand(
        {
          ...(request.data || {}),
          command: request.data && request.data.command || expectedCommand,
        },
        expectedCommand,
      );
      const agent = requireActiveAgent(await findAgent(auth));
      const role = resolveItsmRole(agent);
      requireRole(role, REPORTING_ADMINISTRATION_ALLOWED_ROLES[expectedCommand]);
      const trustedActor = actorFrom(auth, agent, role);
      const actor = Object.freeze({
        ...trustedActor,
        departmentId: normalizeString(agent.departmentId || agent.department),
      });
      return await executeReportingAdministrationCommand({
        db,
        fieldValue,
        timestamp,
        actor,
        command,
      });
    } catch (error) {
      if (error instanceof ItsmCommandError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      logger?.error(
        'Unexpected ITSM Reporting & Administration command failure',
        safeUnexpectedError(expectedCommand, error),
      );
      throw new HttpsError(
        'internal',
        'The ITSM Reporting & Administration command could not be completed.',
      );
    }
  };
}

function safeUnexpectedError(command, error) {
  return {
    command,
    errorName: normalizeString(error && error.name).slice(0, 160) || 'Error',
    errorCode: normalizeString(error && error.code).slice(0, 160),
    errorMessage: normalizeString(error && error.message).slice(0, 2000) ||
      'Unknown unexpected error.',
    errorStack: normalizeString(error && error.stack)
      .split('\n')
      .slice(0, 20)
      .join('\n')
      .slice(0, 8000),
  };
}

module.exports = {
  createItsmReportingAdministrationCallableHandler,
  safeUnexpectedError,
};
