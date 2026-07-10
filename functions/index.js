const { logger } = require('firebase-functions');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const COMPANY_TOPIC = 'company_all';
const DEFAULT_APP_BASE_URL = 'https://arptc-connect.web.app';
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

    const now = admin.firestore.FieldValue.serverTimestamp();
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
        processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
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
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
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
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
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
          subscribedTopics: admin.firestore.FieldValue.arrayUnion(COMPANY_TOPIC),
          subscribedAt: admin.firestore.FieldValue.serverTimestamp(),
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
    createdAt: event.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  };
}

async function findAgentsByModuleRole(target, fallbackModuleKey) {
  const moduleKey = normalizeString(target.moduleKey || fallbackModuleKey);
  const roles = normalizeArray(target.roles).map((role) => role.toUpperCase());
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

  return Array.from(agentsById.values());
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
