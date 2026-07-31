const { logger } = require('firebase-functions');
const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const admin = require('firebase-admin');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const {
  archiveEligibleIncidents,
} = require('./src/incident_archival');
const {
  ITSM_COMMANDS,
} = require('./src/itsm_command_validation');
const {
  createItsmCallableHandler,
} = require('./src/itsm_callable_handlers');
const {
  createItsmSupportCallableHandler,
} = require('./src/itsm_support_handlers');
const {
  ITSM_SUPPORT_COMMANDS,
} = require('./src/itsm_support_validation');
const {
  createItsmAssetsCallableHandler,
} = require('./src/itsm_assets_handlers');
const {
  ITSM_ASSETS_COMMANDS,
} = require('./src/itsm_assets_validation');
const {
  createItsmChangesCallableHandler,
} = require('./src/itsm_changes_handlers');
const {
  ITSM_CHANGES_COMMANDS,
} = require('./src/itsm_changes_validation');
const {
  createItsmSecurityComplianceCallableHandler,
} = require('./src/itsm_security_compliance_handlers');
const {
  SECURITY_COMPLIANCE_COMMANDS,
} = require('./src/itsm_security_compliance_validation');
const {
  registerItsmSecurityComplianceAttachment,
} = require('./src/itsm_security_compliance_attachment_registration');
const {
  processSoftwareLicenceExpiryNotifications,
  processSoftwareLicenceRenewalNotifications,
  processWarrantyExpiryNotifications,
} = require('./src/itsm_assets_notifications');
const {
  registerItsmAssetsAttachment,
} = require('./src/itsm_assets_attachment_registration');
const {
  processServiceRequestSlaBatch,
  processServiceRequestSlaChange,
} = require('./src/itsm_support_sla');
const {
  maintainSupportWorkItemIndex,
  notificationEventsForSupportChange,
  registerKnowledgeAttachment,
  registerServiceRequestAttachment,
  synchronizeServiceRequestApproval,
  synchronizeServiceRequestTask,
  writeSupportNotificationEvents,
} = require('./src/itsm_support_triggers');

admin.initializeApp();

const db = admin.firestore();
const COMPANY_TOPIC = 'company_all';
const DEFAULT_APP_BASE_URL = 'https://arptc-connect.web.app';
const DEFAULT_STORAGE_BUCKET =
  process.env.FIREBASE_STORAGE_BUCKET || 'arptc-connect.appspot.com';
const ANDROID_NOTIFICATION_CHANNEL_ID = 'arptc_connect_notifications';
const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);
const DEFAULT_AGENT_PASSWORD = 'Arptc@1234';
const DEFAULT_MODULE_KEYS = [
  'tasks',
  'courriers',
  'social',
  'news',
  'inventory',
  'ticketing',
  'meetinghall',
  'usermanagement',
];

function registerItsmCallable(command) {
  return onCall(
    createItsmCallableHandler({
      expectedCommand: command,
      db,
      fieldValue: FieldValue,
      findAgent: findCallerAgent,
      HttpsError,
      logger,
    }),
  );
}

exports.itsmTransitionWorkItem = registerItsmCallable(
  ITSM_COMMANDS.transitionWorkItem,
);
exports.itsmDecideApproval = registerItsmCallable(
  ITSM_COMMANDS.decideApproval,
);
exports.itsmIndexAuditEvent = registerItsmCallable(
  ITSM_COMMANDS.indexAuditEvent,
);
exports.itsmMaintainWorkItemIndex = registerItsmCallable(
  ITSM_COMMANDS.maintainWorkItemIndex,
);
exports.itsmProcessSla = registerItsmCallable(ITSM_COMMANDS.processSla);
exports.itsmCreateNotificationEvent = registerItsmCallable(
  ITSM_COMMANDS.createNotificationEvent,
);

function registerItsmSupportCallable(command) {
  return onCall(
    createItsmSupportCallableHandler({
      expectedCommand: command,
      db,
      fieldValue: FieldValue,
      timestamp: Timestamp,
      findAgent: findCallerAgent,
      HttpsError,
      logger,
    }),
  );
}

exports.itsmInitializeServiceRequestDraft = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
);
exports.itsmSubmitServiceRequest = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.submitServiceRequest,
);
exports.itsmUpdateServiceRequestTask = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.updateServiceRequestTask,
);
exports.itsmRecordKnowledgeView = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.recordKnowledgeView,
);
exports.itsmRecordKnowledgeFeedback = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback,
);
exports.itsmSaveKnowledgeDraft = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft,
);
exports.itsmSubmitKnowledgeReview = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.submitKnowledgeReview,
);
exports.itsmRejectKnowledgeReview = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview,
);
exports.itsmPublishKnowledgeArticle = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle,
);
exports.itsmRetireKnowledgeArticle = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle,
);
exports.itsmArchiveKnowledgeArticle = registerItsmSupportCallable(
  ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle,
);

function registerItsmAssetsCallable(command) {
  return onCall(
    createItsmAssetsCallableHandler({
      expectedCommand: command,
      db,
      fieldValue: FieldValue,
      findAgent: findCallerAgent,
      HttpsError,
      logger,
    }),
  );
}

exports.itsmRegisterAsset = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.registerAsset,
);
exports.itsmUpdateAsset = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.updateAsset,
);
exports.itsmTransitionAsset = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.transitionAsset,
);
exports.itsmAssignAsset = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.assignAsset,
);
exports.itsmReturnAsset = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.returnAsset,
);
exports.itsmSaveStockLocation = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveStockLocation,
);
exports.itsmSaveStockItem = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveStockItem,
);
exports.itsmReceiveStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.receiveStock,
);
exports.itsmReserveStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.reserveStock,
);
exports.itsmIssueStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.issueStock,
);
exports.itsmReturnStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.returnStock,
);
exports.itsmTransferStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.transferStock,
);
exports.itsmAdjustStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.adjustStock,
);
exports.itsmReconcileStock = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.reconcileStock,
);
exports.itsmRegisterLicence = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.registerLicence,
);
exports.itsmAllocateLicence = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.allocateLicence,
);
exports.itsmReleaseLicence = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.releaseLicence,
);
exports.itsmSaveSupplier = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveSupplier,
);
exports.itsmSaveContract = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveContract,
);
exports.itsmSaveWarranty = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveWarranty,
);
exports.itsmRecordWarrantyClaim = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.recordWarrantyClaim,
);
exports.itsmTransitionWarrantyClaim = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.transitionWarrantyClaim,
);
exports.itsmSaveConfigurationItem = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.saveConfigurationItem,
);
exports.itsmCreateCiRelationship = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.createCiRelationship,
);
exports.itsmRetireCiRelationship = registerItsmAssetsCallable(
  ITSM_ASSETS_COMMANDS.retireCiRelationship,
);

function registerItsmChangesCallable(command) {
  return onCall(
    createItsmChangesCallableHandler({
      expectedCommand: command,
      db,
      fieldValue: FieldValue,
      timestamp: Timestamp,
      findAgent: findCallerAgent,
      HttpsError,
      logger,
    }),
  );
}

exports.itsmInitializeChangeDraft = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.initializeDraft,
);
exports.itsmSaveChangeDraft = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.saveDraft,
);
exports.itsmSubmitChange = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.submit,
);
exports.itsmCancelChange = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.cancel,
);
exports.itsmAssessChange = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.assess,
);
exports.itsmRequestChangeApproval = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.requestApproval,
);
exports.itsmDecideChangeApproval = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.decideApproval,
);
exports.itsmSaveChangeCabMeeting = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.saveCabMeeting,
);
exports.itsmScheduleChange = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.schedule,
);
exports.itsmStartChangeImplementation = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.startImplementation,
);
exports.itsmRecordChangeImplementationResult = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.recordImplementationResult,
);
exports.itsmRecordChangePostImplementationReview =
  registerItsmChangesCallable(
    ITSM_CHANGES_COMMANDS.recordPostImplementationReview,
  );
exports.itsmCloseChange = registerItsmChangesCallable(
  ITSM_CHANGES_COMMANDS.close,
);

function registerItsmSecurityComplianceCallable(command) {
  return onCall(
    createItsmSecurityComplianceCallableHandler({
      expectedCommand: command,
      db,
      fieldValue: FieldValue,
      timestamp: Timestamp,
      findAgent: findCallerAgent,
      HttpsError,
      logger,
    }),
  );
}

const securityComplianceCallables = {
  itsmCreateSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.createFinding,
  itsmTriageSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.triageFinding,
  itsmAssignSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.assignFinding,
  itsmPlanSecurityFindingRemediation:
    SECURITY_COMPLIANCE_COMMANDS.planRemediation,
  itsmSubmitSecurityFindingValidation:
    SECURITY_COMPLIANCE_COMMANDS.submitFindingValidation,
  itsmValidateSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.validateFinding,
  itsmAcceptSecurityFindingRisk:
    SECURITY_COMPLIANCE_COMMANDS.acceptFindingRisk,
  itsmCloseSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.closeFinding,
  itsmCancelSecurityFinding: SECURITY_COMPLIANCE_COMMANDS.cancelFinding,
  itsmCreateSecurityException: SECURITY_COMPLIANCE_COMMANDS.createException,
  itsmSubmitSecurityException: SECURITY_COMPLIANCE_COMMANDS.submitException,
  itsmRequestSecurityExceptionApproval:
    SECURITY_COMPLIANCE_COMMANDS.requestExceptionApproval,
  itsmDecideSecurityExceptionApproval:
    SECURITY_COMPLIANCE_COMMANDS.decideExceptionApproval,
  itsmActivateSecurityException:
    SECURITY_COMPLIANCE_COMMANDS.activateException,
  itsmRenewSecurityException: SECURITY_COMPLIANCE_COMMANDS.renewException,
  itsmCloseSecurityException: SECURITY_COMPLIANCE_COMMANDS.closeException,
  itsmAssessAssetCompliance: SECURITY_COMPLIANCE_COMMANDS.assessCompliance,
  itsmCreateAccessReviewCampaign:
    SECURITY_COMPLIANCE_COMMANDS.createReviewCampaign,
  itsmActivateAccessReviewCampaign:
    SECURITY_COMPLIANCE_COMMANDS.activateReviewCampaign,
  itsmCompleteAccessReviewCampaign:
    SECURITY_COMPLIANCE_COMMANDS.completeReviewCampaign,
  itsmCreateAccessReviewItem:
    SECURITY_COMPLIANCE_COMMANDS.createReviewItem,
  itsmDecideAccessReviewItem:
    SECURITY_COMPLIANCE_COMMANDS.decideReviewItem,
  itsmRequestAccessCorrection:
    SECURITY_COMPLIANCE_COMMANDS.requestAccessCorrection,
  itsmCompleteAccessRevocationTask:
    SECURITY_COMPLIANCE_COMMANDS.completeRevocationTask,
};

for (const [exportName, command] of Object.entries(
  securityComplianceCallables,
)) {
  exports[exportName] = registerItsmSecurityComplianceCallable(command);
}

exports.itsmProcessAssetExpiryNotifications = onSchedule(
  {
    schedule: 'every day 02:00',
    timeZone: 'Africa/Kinshasa',
    region: 'us-central1',
    retryCount: 3,
  },
  async () => {
    const processors = [
      processWarrantyExpiryNotifications,
      processSoftwareLicenceRenewalNotifications,
      processSoftwareLicenceExpiryNotifications,
    ];
    const results = [];
    for (const processBatch of processors) {
      let cursor = null;
      let pageCount = 0;
      do {
        const result = await processBatch({
          db,
          fieldValue: FieldValue,
          timestamp: Timestamp,
          cursor,
          logger,
        });
        results.push(result);
        cursor = result.nextCursor;
        pageCount += 1;
      } while (cursor && pageCount < 20);
    }
    logger.info('ITSM asset expiry notification run completed', { results });
  },
);

exports.itsmRegisterServiceRequestAttachment = onObjectFinalized(
  { bucket: DEFAULT_STORAGE_BUCKET },
  async (event) => registerServiceRequestAttachment({
    db,
    fieldValue: FieldValue,
    object: event.data,
  }),
);

exports.itsmRegisterKnowledgeAttachment = onObjectFinalized(
  { bucket: DEFAULT_STORAGE_BUCKET },
  async (event) => registerKnowledgeAttachment({
    db,
    fieldValue: FieldValue,
    object: event.data,
  }),
);

exports.itsmRegisterAssetsAttachment = onObjectFinalized(
  { bucket: DEFAULT_STORAGE_BUCKET },
  async (event) => registerItsmAssetsAttachment({
    db,
    fieldValue: FieldValue,
    object: event.data,
  }),
);

exports.itsmRegisterSecurityComplianceAttachment = onObjectFinalized(
  { bucket: DEFAULT_STORAGE_BUCKET },
  async (event) => registerItsmSecurityComplianceAttachment({
    db,
    fieldValue: FieldValue,
    object: event.data,
  }),
);

exports.itsmIndexIncidentWorkItem = onDocumentWritten(
  'incidentTickets/{workItemId}',
  async (event) => maintainSupportWorkItemIndex({
    db,
    collectionName: 'incidentTickets',
    workItemId: event.params.workItemId,
    after: event.data && event.data.after,
  }),
);

exports.itsmIndexServiceRequestWorkItem = onDocumentWritten(
  'serviceRequests/{workItemId}',
  async (event) => maintainSupportWorkItemIndex({
    db,
    collectionName: 'serviceRequests',
    workItemId: event.params.workItemId,
    after: event.data && event.data.after,
  }),
);

exports.itsmNotifyServiceRequestChanges = onDocumentWritten(
  'serviceRequests/{workItemId}',
  async (event) => {
    const events = notificationEventsForSupportChange({
      collectionName: 'serviceRequests',
      workItemId: event.params.workItemId,
      before: event.data && event.data.before,
      after: event.data && event.data.after,
      sourceEventId: event.id,
      fieldValue: FieldValue,
    });
    return writeSupportNotificationEvents({ db, events });
  },
);

exports.itsmProcessServiceRequestSlaChange = onDocumentWritten(
  'serviceRequests/{workItemId}',
  async (event) => processServiceRequestSlaChange({
    db,
    fieldValue: FieldValue,
    timestamp: Timestamp,
    after: event.data && event.data.after,
  }),
);

exports.itsmProcessServiceRequestSlas = onSchedule(
  {
    schedule: 'every 5 minutes',
    timeZone: 'Africa/Kinshasa',
    region: 'us-central1',
    retryCount: 3,
  },
  async () => processServiceRequestSlaBatch({
    db,
    fieldValue: FieldValue,
    timestamp: Timestamp,
    logger,
  }),
);

exports.itsmSynchronizeServiceRequestApproval = onDocumentWritten(
  'serviceRequests/{requestId}/approvals/{approvalId}',
  async (event) => synchronizeServiceRequestApproval({
    db,
    fieldValue: FieldValue,
    requestId: event.params.requestId,
    approvalId: event.params.approvalId,
    before: event.data && event.data.before,
    after: event.data && event.data.after,
    sourceEventId: event.id,
  }),
);

exports.itsmSynchronizeServiceRequestTask = onDocumentWritten(
  'serviceRequests/{requestId}/tasks/{taskId}',
  async (event) => synchronizeServiceRequestTask({
    db,
    fieldValue: FieldValue,
    requestId: event.params.requestId,
    taskId: event.params.taskId,
    before: event.data && event.data.before,
    after: event.data && event.data.after,
    sourceEventId: event.id,
  }),
);

exports.archiveEligibleIncidents = onSchedule(
  {
    schedule: 'every day 01:00',
    timeZone: 'Africa/Kinshasa',
    region: 'us-central1',
    retryCount: 3,
  },
  async () => {
    const archivedCount = await archiveEligibleIncidents({
      db,
      fieldValue: FieldValue,
      timestamp: Timestamp,
      logger,
    });
    logger.info('Incident archival run completed', { archivedCount });
  },
);

exports.createAgentAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  const caller = await findCallerAgent(request.auth);
  const permissions = (caller && caller.modulePermissions) || {};
  const userManagementRole = normalizeString(
    permissions.usermanagement || permissions.user_management,
  ).toUpperCase();
  if (userManagementRole !== 'MANAGER') {
    throw new HttpsError(
      'permission-denied',
      'Only a User Management manager can create agent accounts.',
    );
  }

  const data = request.data || {};
  const requiredFields = [
    'firstName',
    'name',
    'postName',
    'matricule',
    'email',
    'position',
    'departmentId',
  ];
  for (const field of requiredFields) {
    if (!normalizeString(data[field])) {
      throw new HttpsError(
        'invalid-argument',
        `The ${field} field is required.`,
      );
    }
  }

  const email = normalizeString(data.email).toLowerCase();
  if (!isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  const requestedModuleKeys =
    data.modulePermissions && typeof data.modulePermissions === 'object'
      ? Object.keys(data.modulePermissions)
      : [];
  const modulePermissions = await buildDefaultAgentPermissions(
    requestedModuleKeys,
  );
  const displayName = [data.firstName, data.name, data.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');

  let authUser = null;
  try {
    authUser = await admin.auth().createUser({
      email,
      password: DEFAULT_AGENT_PASSWORD,
      displayName,
      disabled: data.isActive === false,
    });

    const now = FieldValue.serverTimestamp();
    await db.collection('agents').doc(authUser.uid).set({
      firstName: normalizeString(data.firstName),
      name: normalizeString(data.name),
      postName: normalizeString(data.postName),
      matricule: normalizeString(data.matricule),
      email,
      emailLower: email,
      profilePictureUrl: normalizeString(data.profilePictureUrl) || null,
      position: normalizeString(data.position),
      departmentId: normalizeString(data.departmentId),
      serviceId: normalizeString(data.serviceId),
      bureauId: normalizeString(data.bureauId),
      isActive: data.isActive !== false,
      modulePermissions,
      createdAt: now,
      updatedAt: now,
      genre: '',
      dob: '',
      category: '',
      direction: normalizeString(data.departmentId),
      service: normalizeString(data.serviceId),
      bureau: normalizeString(data.bureauId),
    });

    return { uid: authUser.uid };
  } catch (error) {
    if (authUser) {
      try {
        await admin.auth().deleteUser(authUser.uid);
      } catch (rollbackError) {
        logger.error('Unable to roll back agent Auth account', {
          uid: authUser.uid,
          rollbackError,
        });
      }
    }
    if (error && error.code === 'auth/email-already-exists') {
      throw new HttpsError(
        'already-exists',
        'An account already exists with this email address.',
      );
    }
    logger.error('Unable to create agent account', { email, error });
    throw new HttpsError('internal', 'Unable to create the agent account.');
  }
});

exports.dispatchNotificationEvent = onDocumentCreated(
  'notificationEvents/{eventId}',
  async (firestoreEvent) => {
    const snapshot = firestoreEvent.data;
    if (!snapshot) {
      return null;
    }

    const eventId = firestoreEvent.params.eventId;
    const event = snapshot.data() || {};
    const target = event.target || {};

    await snapshot.ref.set(
      {
        status: 'PROCESSING',
        processingStartedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    try {
      const notification = buildNotificationDocument(eventId, event);
      const targetType = normalizeString(target.type || 'USERS').toUpperCase();
      let recipientCount = 0;
      let fcmCount = 0;

      if (targetType === 'ALL') {
        await db.collection('globalNotifications').doc(eventId).set(notification, {
          merge: true,
        });
        fcmCount = await sendToCompanyTopic(eventId, event, notification);
      } else if (targetType === 'MODULE_ROLE') {
        const agents = await findAgentsByModuleRole(target, event.moduleKey);
        recipientCount = agents.length;
        fcmCount = await writePersonalNotificationsAndSend(
          agents,
          eventId,
          event,
          notification,
        );
      } else if (targetType === 'USERS') {
        const agents = await findAgentsByIdentity(target);
        recipientCount = agents.length;
        fcmCount = await writePersonalNotificationsAndSend(
          agents,
          eventId,
          event,
          notification,
        );
      } else {
        throw new Error(`Unsupported notification target type: ${targetType}`);
      }

      await snapshot.ref.set(
        {
          status: 'PROCESSED',
          recipientCount,
          fcmCount,
          processedAt: FieldValue.serverTimestamp(),
          errorMessage: '',
        },
        { merge: true },
      );
    } catch (error) {
      logger.error('Notification dispatch failed', {
        eventId,
        error,
      });
      await snapshot.ref.set(
        {
          status: 'FAILED',
          errorMessage: error.message || String(error),
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    return null;
  },
);

exports.subscribeDeviceTokenToCompanyTopic = onDocumentCreated(
  'agents/{agentId}/deviceTokens/{tokenDocId}',
  async (firestoreEvent) => {
    const snapshot = firestoreEvent.data;
    if (!snapshot) {
      return null;
    }

    const token = normalizeString(snapshot.get('token'));
    if (!token) {
      return null;
    }

    try {
      await admin.messaging().subscribeToTopic([token], COMPANY_TOPIC);
      await snapshot.ref.set(
        {
          subscribedTopics: FieldValue.arrayUnion(COMPANY_TOPIC),
          subscribedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } catch (error) {
      logger.warn('Unable to subscribe token to company topic', {
        agentId: firestoreEvent.params.agentId,
        error,
      });
    }

    return null;
  },
);

async function findCallerAgent(authContext) {
  const uid = normalizeString(authContext.uid);
  const rawEmail = normalizeString(
    authContext.token && authContext.token.email,
  );
  const email = rawEmail.toLowerCase();
  const candidateIds = [...new Set([uid, rawEmail, email].filter(Boolean))];

  for (const candidateId of candidateIds) {
    const snapshot = await db.collection('agents').doc(candidateId).get();
    if (snapshot.exists) {
      return snapshot.data() || {};
    }
  }

  if (email) {
    const byEmailLower = await db
      .collection('agents')
      .where('emailLower', '==', email)
      .limit(1)
      .get();
    if (!byEmailLower.empty) {
      return byEmailLower.docs[0].data() || {};
    }

    const byEmail = await db
      .collection('agents')
      .where('email', '==', rawEmail)
      .limit(1)
      .get();
    if (!byEmail.empty) {
      return byEmail.docs[0].data() || {};
    }
  }

  return null;
}

async function buildDefaultAgentPermissions(additionalModuleKeys = []) {
  const moduleKeys = new Set([
    ...DEFAULT_MODULE_KEYS,
    ...additionalModuleKeys.map(normalizeModuleKey).filter(Boolean),
  ]);
  const modulesSnapshot = await db.collection('modules').get();

  for (const moduleDocument of modulesSnapshot.docs) {
    const module = moduleDocument.data() || {};
    const key = normalizeModuleKey(module.key || moduleDocument.id);
    if (!key) {
      continue;
    }
    moduleKeys.add(key);
  }

  return Object.fromEntries(
    Array.from(moduleKeys).map((key) => [key, 'USER']),
  );
}

function normalizeModuleKey(value) {
  const sanitized = normalizeString(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  const aliases = {
    task: 'tasks',
    courrier: 'courriers',
    mail: 'courriers',
    mails: 'courriers',
    company_news: 'news',
    communication: 'news',
    feed: 'news',
    support: 'ticketing',
    incident: 'ticketing',
    incidents: 'ticketing',
    incident_management: 'ticketing',
    incidentmanagement: 'ticketing',
    ticket: 'ticketing',
    tickets: 'ticketing',
    meeting: 'meetinghall',
    meeting_hall: 'meetinghall',
    user_management: 'usermanagement',
    user: 'usermanagement',
    users: 'usermanagement',
    agent: 'usermanagement',
    agents: 'usermanagement',
  };
  return aliases[sanitized] || sanitized;
}

function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function buildNotificationDocument(eventId, event) {
  return {
    sourceEventId: eventId,
    eventType: normalizeString(event.eventType),
    moduleKey: normalizeString(event.moduleKey),
    title: normalizeString(event.title) || 'ARPTC Connect',
    body: normalizeString(event.body),
    entityType: normalizeString(event.entityType),
    entityId: normalizeString(event.entityId),
    route: normalizeString(event.route),
    createdByUserId: normalizeString(event.createdByUserId),
    createdByName: normalizeString(event.createdByName),
    createdByEmail: normalizeString(event.createdByEmail).toLowerCase(),
    createdAt: event.createdAt || FieldValue.serverTimestamp(),
    isRead: false,
  };
}

async function findAgentsByModuleRole(target, fallbackModuleKey) {
  const moduleKey = normalizeString(target.moduleKey || fallbackModuleKey);
  const roles = [...new Set(
    normalizeArray(target.roles).flatMap(roleStorageVariants),
  )];
  if (!moduleKey || roles.length === 0) {
    return [];
  }

  const agentsById = new Map();
  const roleChunks = chunk(roles, 10);
  const moduleKeys = modulePermissionAliases(moduleKey);
  for (const roleChunk of roleChunks) {
    for (const key of moduleKeys) {
      const querySnapshot = await db
        .collection('agents')
        .where(`modulePermissions.${key}`, 'in', roleChunk)
        .get();

      querySnapshot.docs
        .filter((doc) => doc.get('isActive') !== false)
        .forEach((doc) => agentsById.set(doc.id, doc));
    }
  }

  const approvalGroupId = normalizeString(target.approvalGroupId);
  return Array.from(agentsById.values()).filter(
    (agentDoc) => !approvalGroupId ||
      agentHasItsmGroup(agentDoc.data() || {}, approvalGroupId),
  );
}

function agentHasItsmGroup(agent, groupId) {
  const values = [
    agent.itsmGroupIds,
    agent.assignmentGroupIds,
    agent.approvalGroupIds,
    agent.groupIds,
  ].flatMap((value) => Array.isArray(value) ? value : []);
  values.push(
    agent.itsmGroupId,
    agent.assignmentGroupId,
    agent.approvalGroupId,
  );
  return values.map(normalizeString).includes(groupId);
}

function roleStorageVariants(value) {
  const upper = normalizeString(value).toUpperCase();
  if (!upper) {
    return [];
  }
  return [
    upper,
    upper.toLowerCase(),
    `${upper.charAt(0)}${upper.substring(1).toLowerCase()}`,
  ];
}

function modulePermissionAliases(moduleKey) {
  const normalized = normalizeString(moduleKey).toLowerCase();
  if (
    [
      'support',
      'ticketing',
      'incident',
      'incidents',
      'incident_management',
      'incidentmanagement',
      'ticket',
      'tickets',
    ].includes(normalized)
  ) {
    return [
      'support',
      'ticketing',
      'incident',
      'incidents',
      'incident_management',
      'incidentmanagement',
      'ticket',
      'tickets',
    ];
  }
  if (
    [
      'meeting',
      'meetinghall',
      'meeting_hall',
      'meeting-hall',
    ].includes(normalized)
  ) {
    return ['meetinghall', 'meeting_hall', 'meeting', 'meeting-hall'];
  }
  return [normalized];
}

async function findAgentsByIdentity(target) {
  const agentsById = new Map();
  const userIds = normalizeArray(target.userIds);
  const userEmails = normalizeArray(target.userEmails).map((email) =>
    email.toLowerCase(),
  );

  for (const userId of userIds) {
    const doc = await db.collection('agents').doc(userId).get();
    if (doc.exists) {
      agentsById.set(doc.id, doc);
    }
  }

  for (const emailChunk of chunk(userEmails, 10)) {
    if (emailChunk.length === 0) {
      continue;
    }

    const byEmailLower = await db
      .collection('agents')
      .where('emailLower', 'in', emailChunk)
      .get();
    byEmailLower.docs.forEach((doc) => agentsById.set(doc.id, doc));

    const byEmail = await db.collection('agents').where('email', 'in', emailChunk).get();
    byEmail.docs.forEach((doc) => agentsById.set(doc.id, doc));
  }

  return Array.from(agentsById.values());
}

async function writePersonalNotificationsAndSend(agents, eventId, event, notification) {
  const writeBatch = db.batch();
  const tokenDocs = [];

  for (const agentDoc of agents) {
    const notificationRef = agentDoc.ref.collection('notifications').doc(eventId);
    writeBatch.set(notificationRef, notification, { merge: true });

    const tokenSnapshot = await agentDoc.ref.collection('deviceTokens').get();
    tokenSnapshot.docs.forEach((tokenDoc) => {
      const token = normalizeString(tokenDoc.get('token'));
      if (token) {
        tokenDocs.push({ token, ref: tokenDoc.ref });
      }
    });
  }

  await writeBatch.commit();
  return sendToTokens(tokenDocs, eventId, event, notification);
}

async function sendToCompanyTopic(eventId, event, notification) {
  const message = {
    topic: COMPANY_TOPIC,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: buildMessageData(eventId, event, notification, true),
    android: buildAndroidOptions(notification),
    webpush: buildWebPushOptions(notification),
  };

  const response = await admin.messaging().send(message);
  logger.info('Sent company-wide notification', {
    eventId,
    response,
  });
  return 1;
}

async function sendToTokens(tokenDocs, eventId, event, notification) {
  if (tokenDocs.length === 0) {
    return 0;
  }

  let sentCount = 0;
  for (const tokenChunk of chunk(tokenDocs, 500)) {
    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokenChunk.map((entry) => entry.token),
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: buildMessageData(eventId, event, notification, false),
      android: buildAndroidOptions(notification),
      webpush: buildWebPushOptions(notification),
    });

    sentCount += response.successCount;
    const cleanupBatch = db.batch();
    let cleanupCount = 0;
    response.responses.forEach((sendResponse, index) => {
      const code = sendResponse.error && sendResponse.error.code;
      if (code && INVALID_TOKEN_CODES.has(code)) {
        cleanupBatch.delete(tokenChunk[index].ref);
        cleanupCount += 1;
      }
    });

    if (cleanupCount > 0) {
      await cleanupBatch.commit();
    }
  }

  return sentCount;
}

function buildMessageData(eventId, event, notification, isGlobal) {
  return {
    notificationId: eventId,
    eventType: notification.eventType,
    moduleKey: notification.moduleKey,
    entityType: notification.entityType,
    entityId: notification.entityId,
    route: notification.route,
    isGlobal: isGlobal ? 'true' : 'false',
    sourceEventId: eventId,
    title: notification.title,
    body: notification.body,
  };
}

function buildAndroidOptions(notification) {
  return {
    priority: 'high',
    notification: {
      channelId: ANDROID_NOTIFICATION_CHANNEL_ID,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      defaultSound: true,
      defaultVibrateTimings: true,
      priority: 'high',
      visibility: 'private',
    },
  };
}

function buildWebPushOptions(notification) {
  const route = normalizeClientRoute(notification.route);

  return {
    notification: {
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: {
        notificationId: normalizeString(notification.sourceEventId),
        moduleKey: normalizeString(notification.moduleKey),
        entityType: normalizeString(notification.entityType),
        entityId: normalizeString(notification.entityId),
        route,
      },
    },
    fcmOptions: {
      link: buildWebPushLink(route),
    },
  };
}

function buildWebPushLink(route) {
  const baseUrl = normalizeBaseUrl(
    process.env.APP_BASE_URL || DEFAULT_APP_BASE_URL,
  );
  return `${baseUrl}/#${normalizeClientRoute(route)}`;
}

function normalizeBaseUrl(value) {
  const baseUrl = normalizeString(value) || DEFAULT_APP_BASE_URL;
  return baseUrl.replace(/\/+$/, '');
}

function normalizeClientRoute(value) {
  let route = normalizeString(value) || '/home';

  if (route.startsWith('/#/')) {
    route = route.substring(2);
  } else if (route.startsWith('#/')) {
    route = route.substring(1);
  }

  if (!route.startsWith('/')) {
    route = `/${route}`;
  }

  return route;
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

function normalizeArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map(normalizeString).filter(Boolean);
}

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}
