'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const ITSM_SUPPORT_COMMANDS = Object.freeze({
  initializeServiceRequestDraft: 'service_request.initialize_draft',
  submitServiceRequest: 'service_request.submit',
  updateServiceRequestTask: 'service_request.task.update',
  saveKnowledgeDraft: 'knowledge.article.save_draft',
  submitKnowledgeReview: 'knowledge.article.submit_review',
  rejectKnowledgeReview: 'knowledge.article.reject',
  publishKnowledgeArticle: 'knowledge.article.publish',
  retireKnowledgeArticle: 'knowledge.article.retire',
  archiveKnowledgeArticle: 'knowledge.article.archive',
  recordKnowledgeView: 'knowledge.view',
  recordKnowledgeFeedback: 'knowledge.feedback',
});

const SELF_SERVICE_ROLES = Object.freeze([
  ITSM_ROLES.user,
  ITSM_ROLES.manager,
  ITSM_ROLES.admin,
]);
const MANAGER_ONLY = Object.freeze([ITSM_ROLES.manager]);

const SUPPORT_COMMAND_ALLOWED_ROLES = Object.freeze({
  [ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft]: SELF_SERVICE_ROLES,
  [ITSM_SUPPORT_COMMANDS.submitServiceRequest]: SELF_SERVICE_ROLES,
  [ITSM_SUPPORT_COMMANDS.updateServiceRequestTask]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.submitKnowledgeReview]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle]: MANAGER_ONLY,
  [ITSM_SUPPORT_COMMANDS.recordKnowledgeView]: SELF_SERVICE_ROLES,
  [ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback]: SELF_SERVICE_ROLES,
});

const TASK_STATUSES = Object.freeze([
  'pending',
  'in_progress',
  'completed',
  'cancelled',
]);
const KNOWLEDGE_VISIBILITIES = Object.freeze(['employee', 'dsi_only']);

const COMMON_FIELDS = new Set(['command', 'idempotencyKey', 'payload']);
const PAYLOAD_FIELDS = Object.freeze({
  [ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft]: new Set([
    'catalogueItemId',
    'requestedForUserId',
    'title',
    'description',
    'responses',
  ]),
  [ITSM_SUPPORT_COMMANDS.submitServiceRequest]: new Set([
    'requestId',
    'responses',
    'attachmentIds',
  ]),
  [ITSM_SUPPORT_COMMANDS.updateServiceRequestTask]: new Set([
    'requestId',
    'taskId',
    'status',
    'comment',
  ]),
  [ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft]: new Set([
    'articleId',
    'expectedVersionNumber',
    'categoryId',
    'title',
    'summary',
    'content',
    'languageCode',
    'visibility',
    'isFeatured',
    'relatedServiceIds',
    'relatedCatalogueItemIds',
    'relatedIncidentCategoryIds',
  ]),
  [ITSM_SUPPORT_COMMANDS.submitKnowledgeReview]: new Set([
    'articleId',
    'expectedVersionNumber',
  ]),
  [ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview]: new Set([
    'articleId',
    'expectedVersionNumber',
    'reason',
  ]),
  [ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle]: new Set([
    'articleId',
    'expectedVersionNumber',
  ]),
  [ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle]: new Set(['articleId']),
  [ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle]: new Set(['articleId']),
  [ITSM_SUPPORT_COMMANDS.recordKnowledgeView]: new Set(['articleId']),
  [ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback]: new Set([
    'articleId',
    'helpful',
    'comment',
  ]),
});

function validateSupportCommand(input, expectedCommand) {
  if (!isPlainObject(input)) {
    throw invalid('The support command must be an object.');
  }
  rejectUnknownFields(input, COMMON_FIELDS, 'support command');

  const command = normalizeString(input.command);
  if (!Object.values(ITSM_SUPPORT_COMMANDS).includes(command)) {
    throw invalid(`Unknown support command: ${command || '(empty)'}.`);
  }
  if (expectedCommand && command !== expectedCommand) {
    throw invalid(`The ${expectedCommand} endpoint cannot execute ${command}.`);
  }

  const idempotencyKey = normalizeString(input.idempotencyKey);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/.test(idempotencyKey)) {
    throw invalid('idempotencyKey must contain 8-128 safe characters.');
  }
  const payload = input.payload === undefined ? {} : input.payload;
  if (!isPlainObject(payload)) {
    throw invalid('payload must be an object.');
  }
  rejectUnknownFields(payload, PAYLOAD_FIELDS[command], `${command} payload`);

  return deepFreeze({
    command,
    idempotencyKey,
    payload: validatePayload(command, payload),
  });
}

function validatePayload(command, payload) {
  switch (command) {
    case ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft:
      return {
        catalogueItemId: requireIdentifier(
          payload.catalogueItemId,
          'catalogueItemId',
        ),
        requestedForUserId: optionalIdentifier(
          payload.requestedForUserId,
          'requestedForUserId',
        ),
        title: optionalText(payload.title, 240),
        description: optionalText(payload.description, 8000),
        responses: validateResponses(payload.responses),
      };
    case ITSM_SUPPORT_COMMANDS.submitServiceRequest:
      return {
        requestId: requireIdentifier(payload.requestId, 'requestId'),
        responses: validateResponses(payload.responses),
        attachmentIds: validateIdentifierList(
          payload.attachmentIds,
          'attachmentIds',
          20,
        ),
      };
    case ITSM_SUPPORT_COMMANDS.updateServiceRequestTask: {
      const status = normalizeString(payload.status).toLowerCase();
      if (!TASK_STATUSES.includes(status)) {
        throw invalid(`status must be one of: ${TASK_STATUSES.join(', ')}.`);
      }
      return {
        requestId: requireIdentifier(payload.requestId, 'requestId'),
        taskId: requireIdentifier(payload.taskId, 'taskId'),
        status,
        comment: optionalText(payload.comment, 4000),
      };
    }
    case ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft: {
      const visibility = normalizeString(payload.visibility || 'employee')
        .toLowerCase();
      if (!KNOWLEDGE_VISIBILITIES.includes(visibility)) {
        throw invalid('visibility must be employee or dsi_only.');
      }
      if (payload.isFeatured !== undefined &&
          typeof payload.isFeatured !== 'boolean') {
        throw invalid('isFeatured must be a boolean.');
      }
      const languageCode = normalizeString(payload.languageCode || 'en')
        .toLowerCase();
      if (!/^[a-z]{2}(?:-[a-z]{2})?$/.test(languageCode)) {
        throw invalid('languageCode must be a supported language code.');
      }
      return {
        articleId: optionalIdentifier(payload.articleId, 'articleId'),
        expectedVersionNumber: optionalPositiveInteger(
          payload.expectedVersionNumber,
          'expectedVersionNumber',
        ),
        categoryId: requireIdentifier(payload.categoryId, 'categoryId'),
        title: requireText(payload.title, 'title', 240),
        summary: optionalText(payload.summary, 1000),
        content: requireText(payload.content, 'content', 100000),
        languageCode,
        visibility,
        isFeatured: payload.isFeatured === true,
        relatedServiceIds: validateIdentifierList(
          payload.relatedServiceIds,
          'relatedServiceIds',
          50,
        ),
        relatedCatalogueItemIds: validateIdentifierList(
          payload.relatedCatalogueItemIds,
          'relatedCatalogueItemIds',
          50,
        ),
        relatedIncidentCategoryIds: validateIdentifierList(
          payload.relatedIncidentCategoryIds,
          'relatedIncidentCategoryIds',
          50,
        ),
      };
    }
    case ITSM_SUPPORT_COMMANDS.submitKnowledgeReview:
    case ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle:
      return knowledgeTransitionPayload(payload);
    case ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview:
      return {
        ...knowledgeTransitionPayload(payload),
        reason: requireText(payload.reason, 'reason', 4000),
      };
    case ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle:
    case ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle:
    case ITSM_SUPPORT_COMMANDS.recordKnowledgeView:
      return { articleId: requireIdentifier(payload.articleId, 'articleId') };
    case ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback:
      if (typeof payload.helpful !== 'boolean') {
        throw invalid('helpful must be a boolean.');
      }
      return {
        articleId: requireIdentifier(payload.articleId, 'articleId'),
        helpful: payload.helpful,
        comment: optionalText(payload.comment, 2000),
      };
    default:
      throw invalid(`Unknown support command: ${command}.`);
  }
}

function knowledgeTransitionPayload(payload) {
  return {
    articleId: requireIdentifier(payload.articleId, 'articleId'),
    expectedVersionNumber: optionalPositiveInteger(
      payload.expectedVersionNumber,
      'expectedVersionNumber',
    ),
  };
}

function validateResponses(value) {
  if (value === undefined || value === null) return {};
  if (!isPlainObject(value)) throw invalid('responses must be an object.');
  const entries = Object.entries(value);
  if (entries.length > 100) {
    throw invalid('responses cannot contain more than 100 fields.');
  }
  return Object.fromEntries(entries.map(([key, answer]) => {
    const normalizedKey = requireIdentifier(key, 'response key');
    return [normalizedKey, validateResponseValue(answer, normalizedKey)];
  }));
}

function validateResponseValue(value, fieldId) {
  if (value === null || typeof value === 'boolean' ||
      (typeof value === 'number' && Number.isFinite(value))) {
    return value;
  }
  if (typeof value === 'string') {
    if (value.length > 8000) {
      throw invalid(`Response ${fieldId} is longer than 8000 characters.`);
    }
    return value.trim();
  }
  if (Array.isArray(value) && value.length <= 50) {
    return value.map((entry) => {
      if (typeof entry !== 'string' || entry.length > 500) {
        throw invalid(`Response ${fieldId} may contain only short strings.`);
      }
      return entry.trim();
    });
  }
  throw invalid(`Response ${fieldId} has an unsupported value type.`);
}

function validateIdentifierList(value, field, maximum) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maximum) {
    throw invalid(`${field} must be an array with at most ${maximum} entries.`);
  }
  return [...new Set(value.map((entry) => requireIdentifier(entry, field)))];
}

function requireIdentifier(value, field) {
  const identifier = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(identifier)) {
    throw invalid(`${field} must be a safe identifier.`);
  }
  return identifier;
}

function optionalIdentifier(value, field) {
  const normalized = normalizeString(value);
  return normalized ? requireIdentifier(normalized, field) : '';
}

function optionalPositiveInteger(value, field) {
  if (value === undefined || value === null || value === '') return null;
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 1) {
    throw invalid(`${field} must be a positive integer.`);
  }
  return number;
}

function requireText(value, field, maxLength) {
  const text = normalizeString(value);
  if (!text || text.length > maxLength) {
    throw invalid(`${field} must contain 1-${maxLength} characters.`);
  }
  return text;
}

function optionalText(value, maxLength) {
  const text = normalizeString(value);
  if (text.length > maxLength) {
    throw invalid(`Text cannot be longer than ${maxLength} characters.`);
  }
  return text;
}

function rejectUnknownFields(value, allowed, label) {
  const unknown = Object.keys(value).filter((field) => !allowed.has(field));
  if (unknown.length > 0) {
    throw invalid(`${label} contains unsupported fields: ${unknown.join(', ')}.`);
  }
}

function isPlainObject(value) {
  return Boolean(value && typeof value === 'object' && !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype);
}

function deepFreeze(value) {
  if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
  Object.freeze(value);
  Object.values(value).forEach(deepFreeze);
  return value;
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

module.exports = {
  ITSM_SUPPORT_COMMANDS,
  KNOWLEDGE_VISIBILITIES,
  SUPPORT_COMMAND_ALLOWED_ROLES,
  TASK_STATUSES,
  deepFreeze,
  validateSupportCommand,
};
