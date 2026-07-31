// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';

class S {
  S._(this.localeName, this._messages);

  final String localeName;
  final Map<String, String> _messages;
  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize S.delegate.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) async {
    final localeName = _supportedLanguageCodes.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    final instance = S._(
      localeName,
      _localizedValues[localeName] ?? _localizedValues['en']!,
    );
    _current = instance;
    return instance;
  }

  static S of(BuildContext context) {
    final instance = maybeOf(context);
    assert(
      instance != null,
      'No S instance is present. Add S.delegate to localizationsDelegates.',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) => Localizations.of<S>(context, S);

  String _text(String key) =>
      _messages[key] ?? _localizedValues['en']?[key] ?? key;

  String lookup(String key) => _text(key);

  String _format(String key, Map<String, Object?> values) {
    var result = _text(key);
    for (final entry in values.entries) {
      result = result.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }
    return result;
  }

  String get appName => _text('appName');
  String get appTitle => _text('appTitle');
  String get appShortName => _text('appShortName');
  String get notAvailable => _text('notAvailable');
  String get dash => _text('dash');
  String get yes => _text('yes');
  String get no => _text('no');
  String get ok => _text('ok');
  String get cancel => _text('cancel');
  String get confirm => _text('confirm');
  String get confirmation => _text('confirmation');
  String get save => _text('save');
  String get saving => _text('saving');
  String get delete => _text('delete');
  String get edit => _text('edit');
  String get add => _text('add');
  String get create => _text('create');
  String get update => _text('update');
  String get submit => _text('submit');
  String get close => _text('close');
  String get archive => _text('archive');
  String get refresh => _text('refresh');
  String get retry => _text('retry');
  String get search => _text('search');
  String get filter => _text('filter');
  String get clear => _text('clear');
  String get select => _text('select');
  String get viewAll => _text('viewAll');
  String get back => _text('back');
  String get next => _text('next');
  String get previous => _text('previous');
  String get loading => _text('loading');
  String get error => _text('error');
  String get somethingWentWrong => _text('somethingWentWrong');
  String get unableToLoad => _text('unableToLoad');
  String get noDataAvailable => _text('noDataAvailable');
  String get noDataDescription => _text('noDataDescription');
  String get active => _text('active');
  String get inactive => _text('inactive');
  String get enabled => _text('enabled');
  String get disabled => _text('disabled');
  String get approved => _text('approved');
  String get pending => _text('pending');
  String get rejected => _text('rejected');
  String get archived => _text('archived');
  String get all => _text('all');
  String get allStatuses => _text('allStatuses');
  String get status => _text('status');
  String get type => _text('type');
  String get date => _text('date');
  String get createdAt => _text('createdAt');
  String get updatedAt => _text('updatedAt');
  String get createdBy => _text('createdBy');
  String get assignedTo => _text('assignedTo');
  String get unassigned => _text('unassigned');
  String get description => _text('description');
  String get title => _text('title');
  String get name => _text('name');
  String get firstName => _text('firstName');
  String get lastName => _text('lastName');
  String get postName => _text('postName');
  String get fullName => _text('fullName');
  String get email => _text('email');
  String get noEmail => _text('noEmail');
  String get phone => _text('phone');
  String get matricule => _text('matricule');
  String get position => _text('position');
  String get category => _text('category');
  String get subcategory => _text('subcategory');
  String get department => _text('department');
  String get departments => _text('departments');
  String get service => _text('service');
  String get services => _text('services');
  String get bureau => _text('bureau');
  String get bureaux => _text('bureaux');
  String get agent => _text('agent');
  String get agents => _text('agents');
  String get user => _text('user');
  String get users => _text('users');
  String get module => _text('module');
  String get modules => _text('modules');
  String get role => _text('role');
  String get roles => _text('roles');
  String get permissions => _text('permissions');
  String get modulePermissions => _text('modulePermissions');
  String get profilePicture => _text('profilePicture');
  String get language => _text('language');
  String get english => _text('english');
  String get french => _text('french');
  String get system => _text('system');
  String get light => _text('light');
  String get dark => _text('dark');
  String get navigationHome => _text('navigationHome');
  String get navigationServices => _text('navigationServices');
  String get navigationCourrier => _text('navigationCourrier');
  String get navigationCourriers => _text('navigationCourriers');
  String get navigationDashboard => _text('navigationDashboard');
  String get navigationProfile => _text('navigationProfile');
  String get navigationAccount => _text('navigationAccount');
  String get navigationAdministration => _text('navigationAdministration');
  String get signIn => _text('signIn');
  String get signOut => _text('signOut');
  String get signingIn => _text('signingIn');
  String get emailOrPasswordIncorrect => _text('emailOrPasswordIncorrect');
  String get errorOccurred => _text('errorOccurred');
  String get emailAlreadyInUse => _text('emailAlreadyInUse');
  String get resetPassword => _text('resetPassword');
  String get password => _text('password');
  String get homeNewsTitle => _text('homeNewsTitle');
  String get homeNewsDescription => _text('homeNewsDescription');
  String get companyNews => _text('companyNews');
  String get noCompanyNewsYet => _text('noCompanyNewsYet');
  String get publishedInformationWillAppearHere =>
      _text('publishedInformationWillAppearHere');
  String get loadingCompanyNews => _text('loadingCompanyNews');
  String get unableToLoadCompanyNews => _text('unableToLoadCompanyNews');
  String get news => _text('news');
  String get newPost => _text('newPost');
  String get postDetails => _text('postDetails');
  String get newsEditor => _text('newsEditor');
  String get newsReview => _text('newsReview');
  String get reviewPost => _text('reviewPost');
  String get publishPost => _text('publishPost');
  String get archivePost => _text('archivePost');
  String get submitForReview => _text('submitForReview');
  String get acceptPost => _text('acceptPost');
  String get rejectPost => _text('rejectPost');
  String get rejectionComment => _text('rejectionComment');
  String get draft => _text('draft');
  String get accepted => _text('accepted');
  String get published => _text('published');
  String get serviceWelcome => _text('serviceWelcome');
  String get loadingModules => _text('loadingModules');
  String get noAuthorizedModule => _text('noAuthorizedModule');
  String get noAuthorizedModuleDescription =>
      _text('noAuthorizedModuleDescription');
  String get moduleTasksName => _text('moduleTasksName');
  String get moduleTasksDescription => _text('moduleTasksDescription');
  String get moduleInventoryName => _text('moduleInventoryName');
  String get moduleInventoryDescription => _text('moduleInventoryDescription');
  String get moduleIncidentName => _text('moduleIncidentName');
  String get moduleIncidentDescription => _text('moduleIncidentDescription');
  String get moduleItsmName => _text('moduleItsmName');
  String get moduleItsmDescription => _text('moduleItsmDescription');
  String get itsmLandingTitle => _text('itsmLandingTitle');
  String get itsmLandingDescription => _text('itsmLandingDescription');
  String get itsmSupport => _text('itsmSupport');
  String get itsmSupportDescription => _text('itsmSupportDescription');
  String get itsmAssetsConfiguration => _text('itsmAssetsConfiguration');
  String get itsmAssetsConfigurationDescription =>
      _text('itsmAssetsConfigurationDescription');
  String get itsmChanges => _text('itsmChanges');
  String get itsmChangesDescription => _text('itsmChangesDescription');
  String get itsmSecurityCompliance => _text('itsmSecurityCompliance');
  String get itsmSecurityComplianceDescription =>
      _text('itsmSecurityComplianceDescription');
  String get itsmReportingAdministration =>
      _text('itsmReportingAdministration');
  String get itsmReportingAdministrationDescription =>
      _text('itsmReportingAdministrationDescription');
  String get itsmIncidents => _text('itsmIncidents');
  String get itsmServiceRequests => _text('itsmServiceRequests');
  String get itsmMyRequests => _text('itsmMyRequests');
  String get itsmSearchWorkItems => _text('itsmSearchWorkItems');
  String get itsmWorkItemType => _text('itsmWorkItemType');
  String get itsmFilterByDate => _text('itsmFilterByDate');
  String get itsmLoadMore => _text('itsmLoadMore');
  String get itsmAddComment => _text('itsmAddComment');
  String get itsmLinkedRecords => _text('itsmLinkedRecords');
  String get itsmLinkRecord => _text('itsmLinkRecord');
  String get itsmUpdateTask => _text('itsmUpdateTask');
  String get itsmStartFulfilment => _text('itsmStartFulfilment');
  String get itsmMarkFulfilled => _text('itsmMarkFulfilled');
  String get itsmConfirmCompletion => _text('itsmConfirmCompletion');
  String get itsmCancelRequest => _text('itsmCancelRequest');
  String get itsmRejectRequest => _text('itsmRejectRequest');
  String get itsmConfirmStatusChange => _text('itsmConfirmStatusChange');
  String get itsmActionCompleted => _text('itsmActionCompleted');
  String get itsmAssignRequest => _text('itsmAssignRequest');
  String get actions => _text('actions');
  String get assign => _text('assign');
  String get reason => _text('reason');
  String get visibility => _text('visibility');
  String get id => _text('id');
  String get reference => _text('reference');
  String get itsmKnowledgeBase => _text('itsmKnowledgeBase');
  String get itsmAssets => _text('itsmAssets');
  String get itsmStock => _text('itsmStock');
  String get itsmLicences => _text('itsmLicences');
  String get itsmSuppliersWarranties => _text('itsmSuppliersWarranties');
  String get itsmCmdb => _text('itsmCmdb');
  String get itsmChangeRequests => _text('itsmChangeRequests');
  String get itsmApprovalsCab => _text('itsmApprovalsCab');
  String get itsmChangeCalendar => _text('itsmChangeCalendar');
  String get itsmSecurityFindings => _text('itsmSecurityFindings');
  String get itsmSecurityExceptions => _text('itsmSecurityExceptions');
  String get itsmAssetCompliance => _text('itsmAssetCompliance');
  String get itsmAccessReviews => _text('itsmAccessReviews');
  String get itsmDashboards => _text('itsmDashboards');
  String get itsmSla => _text('itsmSla');
  String get itsmServiceCatalogue => _text('itsmServiceCatalogue');
  String get itsmWorkflowConfiguration => _text('itsmWorkflowConfiguration');
  String get itsmAuditLogs => _text('itsmAuditLogs');
  String get itsmFeatureCardDescription => _text('itsmFeatureCardDescription');
  String get itsmFeatureUnavailableDescription =>
      _text('itsmFeatureUnavailableDescription');
  String get itsmAccessDeniedTitle => _text('itsmAccessDeniedTitle');
  String get itsmAccessDeniedDescription =>
      _text('itsmAccessDeniedDescription');
  String get itsmLoadingAccess => _text('itsmLoadingAccess');
  String get itsmUnableToLoadAccess => _text('itsmUnableToLoadAccess');
  String get moduleUserManagementName => _text('moduleUserManagementName');
  String get moduleUserManagementDescription =>
      _text('moduleUserManagementDescription');
  String get moduleNewsName => _text('moduleNewsName');
  String get moduleNewsDescription => _text('moduleNewsDescription');
  String get moduleCourrierName => _text('moduleCourrierName');
  String get moduleCourrierDescription => _text('moduleCourrierDescription');
  String get profile => _text('profile');
  String get profileUnavailable => _text('profileUnavailable');
  String get profileUnavailableDescription =>
      _text('profileUnavailableDescription');
  String get connectedAgentInformation => _text('connectedAgentInformation');
  String get agentInformation => _text('agentInformation');
  String get noFields => _text('noFields');
  String get noProfileFieldsAvailable => _text('noProfileFieldsAvailable');
  String get refreshProfile => _text('refreshProfile');
  String get loadingProfile => _text('loadingProfile');
  String get unableToLoadProfile => _text('unableToLoadProfile');
  String get enableNotifications => _text('enableNotifications');
  String get notificationsEnabled => _text('notificationsEnabled');
  String get notificationPermissionNotGranted =>
      _text('notificationPermissionNotGranted');
  String get unableToEnableNotifications =>
      _text('unableToEnableNotifications');
  String get webPushNotConfigured => _text('webPushNotConfigured');
  String get webPushNotConfiguredDescription =>
      _text('webPushNotConfiguredDescription');
  String get webPushNotConfiguredAction => _text('webPushNotConfiguredAction');
  String get disableNotifications => _text('disableNotifications');
  String get notificationsBlocked => _text('notificationsBlocked');
  String notificationsEnabledForPlatform(Object? platform) =>
      _format('notificationsEnabledForPlatform', {
        'platform': platform,
      });
  String get notificationsProvisionallyEnabled =>
      _text('notificationsProvisionallyEnabled');
  String notificationsBlockedForPlatform(Object? platform) =>
      _format('notificationsBlockedForPlatform', {
        'platform': platform,
      });
  String get allowNotificationsPrompt => _text('allowNotificationsPrompt');
  String get disableNotificationsWindows =>
      _text('disableNotificationsWindows');
  String get disableNotificationsMac => _text('disableNotificationsMac');
  String get disableNotificationsWeb => _text('disableNotificationsWeb');
  String get disableNotificationsDevice => _text('disableNotificationsDevice');
  String get blockedNotificationsWindows =>
      _text('blockedNotificationsWindows');
  String get blockedNotificationsMac => _text('blockedNotificationsMac');
  String get blockedNotificationsWeb => _text('blockedNotificationsWeb');
  String get blockedNotificationsDevice => _text('blockedNotificationsDevice');
  String get notifications => _text('notifications');
  String get noNotificationsYet => _text('noNotificationsYet');
  String get noNotificationsDescription => _text('noNotificationsDescription');
  String get loadingNotifications => _text('loadingNotifications');
  String get unableToLoadNotifications => _text('unableToLoadNotifications');
  String get clearAllNotifications => _text('clearAllNotifications');
  String get notificationsCleared => _text('notificationsCleared');
  String get unableToClearNotifications => _text('unableToClearNotifications');
  String get everyone => _text('everyone');
  String get forYou => _text('forYou');
  String get erp => _text('erp');
  String get incidentManagement => _text('incidentManagement');
  String get incidentSupport => _text('incidentSupport');
  String get incidentOperations => _text('incidentOperations');
  String get incidentOperationsDescription =>
      _text('incidentOperationsDescription');
  String get incidentSupervision => _text('incidentSupervision');
  String get incidentSupervisionDescription =>
      _text('incidentSupervisionDescription');
  String get newIncident => _text('newIncident');
  String get newSupportIncident => _text('newSupportIncident');
  String get submitSupportTicket => _text('submitSupportTicket');
  String get submitTicket => _text('submitTicket');
  String get submitting => _text('submitting');
  String get createIncidentManagerDescription =>
      _text('createIncidentManagerDescription');
  String get createIncidentUserDescription =>
      _text('createIncidentUserDescription');
  String get readOnlyIncidentAccess => _text('readOnlyIncidentAccess');
  String get onlyUsersAndManagersCreateIncidents =>
      _text('onlyUsersAndManagersCreateIncidents');
  String get titleExampleEmailAccess => _text('titleExampleEmailAccess');
  String get shortDescription => _text('shortDescription');
  String get describeIssue => _text('describeIssue');
  String get describeIssueAndWork => _text('describeIssueAndWork');
  String get affectedItService => _text('affectedItService');
  String get selectAffectedService => _text('selectAffectedService');
  String get thisIssueBlocksMyWork => _text('thisIssueBlocksMyWork');
  String get blockingWorkDescription => _text('blockingWorkDescription');
  String get managerCategorization => _text('managerCategorization');
  String get managerCategorizationDescription =>
      _text('managerCategorizationDescription');
  String get affectedAgent => _text('affectedAgent');
  String get searchAffectedAgentHint => _text('searchAffectedAgentHint');
  String get searchByNameEmailMatricule => _text('searchByNameEmailMatricule');
  String get location => _text('location');
  String get locationHint => _text('locationHint');
  String get deviceType => _text('deviceType');
  String get deviceTypeHint => _text('deviceTypeHint');
  String get assetId => _text('assetId');
  String get assetIdHint => _text('assetIdHint');
  String get impact => _text('impact');
  String get urgency => _text('urgency');
  String get impactDescription => _text('impactDescription');
  String get impactDescriptionHint => _text('impactDescriptionHint');
  String get selectCategory => _text('selectCategory');
  String get selectImpact => _text('selectImpact');
  String get selectUrgency => _text('selectUrgency');
  String get completeCategoryImpactUrgency =>
      _text('completeCategoryImpactUrgency');
  String get openTickets => _text('openTickets');
  String get openTicketsSubtitle => _text('openTicketsSubtitle');
  String get unassignedTickets => _text('unassignedTickets');
  String get unassignedTicketsSubtitle => _text('unassignedTicketsSubtitle');
  String get assignedToMe => _text('assignedToMe');
  String get solvedTickets => _text('solvedTickets');
  String get solvedTicketsSubtitle => _text('solvedTicketsSubtitle');
  String get criticalTickets => _text('criticalTickets');
  String get criticalTicketsSubtitle => _text('criticalTicketsSubtitle');
  String get closedThisWeek => _text('closedThisWeek');
  String get parameters => _text('parameters');
  String get operationalQueue => _text('operationalQueue');
  String get operationalQueueDescription =>
      _text('operationalQueueDescription');
  String get noActiveIncident => _text('noActiveIncident');
  String get newOperationalTicketsWillAppearHere =>
      _text('newOperationalTicketsWillAppearHere');
  String get myAssignedTickets => _text('myAssignedTickets');
  String get myAssignedTicketsDescription =>
      _text('myAssignedTicketsDescription');
  String get ticketsByPriority => _text('ticketsByPriority');
  String get ticketsByStatus => _text('ticketsByStatus');
  String get ticketsByAffectedService => _text('ticketsByAffectedService');
  String get agingTickets => _text('agingTickets');
  String get ticket => _text('ticket');
  String get priority => _text('priority');
  String get age => _text('age');
  String get createdAtColumn => _text('createdAtColumn');
  String get openTicketsQueueDescription =>
      _text('openTicketsQueueDescription');
  String get unassignedTicketsQueueDescription =>
      _text('unassignedTicketsQueueDescription');
  String get assignedToMeQueueDescription =>
      _text('assignedToMeQueueDescription');
  String get solvedTicketsQueueDescription =>
      _text('solvedTicketsQueueDescription');
  String get closedTicketHistory => _text('closedTicketHistory');
  String get closedTicketHistoryDescription =>
      _text('closedTicketHistoryDescription');
  String get noClosedTicketsHistory => _text('noClosedTicketsHistory');
  String get noClosedTicketsHistoryDescription =>
      _text('noClosedTicketsHistoryDescription');
  String get noTicketsFound => _text('noTicketsFound');
  String get queueEmpty => _text('queueEmpty');
  String get tryAnotherSearchOrStatus => _text('tryAnotherSearchOrStatus');
  String thereIsNoQueueItem(Object? queueLabel) =>
      _format('thereIsNoQueueItem', {
        'queueLabel': queueLabel,
      });
  String get searchIncidents => _text('searchIncidents');
  String get ticketDetails => _text('ticketDetails');
  String get incidentNotFound => _text('incidentNotFound');
  String get loadingIncident => _text('loadingIncident');
  String get unableToLoadIncident => _text('unableToLoadIncident');
  String get timeline => _text('timeline');
  String get requester => _text('requester');
  String get affectedService => _text('affectedService');
  String get blocking => _text('blocking');
  String get resolutionSummary => _text('resolutionSummary');
  String get resolutionSummaryHint => _text('resolutionSummaryHint');
  String get resolutionCode => _text('resolutionCode');
  String get resolutionCodeHint => _text('resolutionCodeHint');
  String get resolutionCodes => _text('resolutionCodes');
  String get selectResolutionCode => _text('selectResolutionCode');
  String get selectResolutionCodeBeforeSolved =>
      _text('selectResolutionCodeBeforeSolved');
  String get selectResolutionCodeBeforeClosing =>
      _text('selectResolutionCodeBeforeClosing');
  String get closedAt => _text('closedAt');
  String get archiveEligible => _text('archiveEligible');
  String get internalNotes => _text('internalNotes');
  String get addNote => _text('addNote');
  String get addInternalNoteHint => _text('addInternalNoteHint');
  String get adding => _text('adding');
  String get internalNoteAdded => _text('internalNoteAdded');
  String get workflowStepSubmitTicket => _text('workflowStepSubmitTicket');
  String get workflowStepSubmitTicketDescription =>
      _text('workflowStepSubmitTicketDescription');
  String get workflowStepCategorizeTicket =>
      _text('workflowStepCategorizeTicket');
  String get workflowStepCategorizeOpenDescription =>
      _text('workflowStepCategorizeOpenDescription');
  String get workflowStepCategorizeActiveDescription =>
      _text('workflowStepCategorizeActiveDescription');
  String get workflowStepAssignTicket => _text('workflowStepAssignTicket');
  String get workflowStepAssignTicketDescription =>
      _text('workflowStepAssignTicketDescription');
  String get workflowStepSolveTicket => _text('workflowStepSolveTicket');
  String get workflowStepSolveTicketDescription =>
      _text('workflowStepSolveTicketDescription');
  String get workflowStepCloseTicket => _text('workflowStepCloseTicket');
  String get workflowStepCloseTicketDescription =>
      _text('workflowStepCloseTicketDescription');
  String get categorizeTicket => _text('categorizeTicket');
  String get categorizing => _text('categorizing');
  String get ticketCategorized => _text('ticketCategorized');
  String get assignTicket => _text('assignTicket');
  String get assigning => _text('assigning');
  String get ticketAssigned => _text('ticketAssigned');
  String get markTicketSolved => _text('markTicketSolved');
  String get markingSolved => _text('markingSolved');
  String get ticketMarkedSolved => _text('ticketMarkedSolved');
  String get markTicketClosed => _text('markTicketClosed');
  String get closing => _text('closing');
  String get ticketClosed => _text('ticketClosed');
  String get cancelTicket => _text('cancelTicket');
  String get cancelThisTicket => _text('cancelThisTicket');
  String get cancelTicketWarning => _text('cancelTicketWarning');
  String get keepTicket => _text('keepTicket');
  String get cancelling => _text('cancelling');
  String get ticketCancelled => _text('ticketCancelled');
  String get selectServiceCategoryImpactUrgency =>
      _text('selectServiceCategoryImpactUrgency');
  String get selectItStaffAssignee => _text('selectItStaffAssignee');
  String get enterResolutionSummaryBeforeSolved =>
      _text('enterResolutionSummaryBeforeSolved');
  String get enterResolutionSummaryBeforeClosing =>
      _text('enterResolutionSummaryBeforeClosing');
  String get myIncidents => _text('myIncidents');
  String get createAndFollowIncidents => _text('createAndFollowIncidents');
  String get activeIncidents => _text('activeIncidents');
  String get closedAndArchived => _text('closedAndArchived');
  String get noActiveIncidentUserDescription =>
      _text('noActiveIncidentUserDescription');
  String get noClosedIncident => _text('noClosedIncident');
  String get closedAndArchivedDescription =>
      _text('closedAndArchivedDescription');
  String get loadingIncidents => _text('loadingIncidents');
  String get unableToLoadIncidents => _text('unableToLoadIncidents');
  String get incidentAccessUnavailable => _text('incidentAccessUnavailable');
  String get incidentAccessUnavailableDescription =>
      _text('incidentAccessUnavailableDescription');
  String get noIncidentDashboardAccess => _text('noIncidentDashboardAccess');
  String get loadingIncidentAccess => _text('loadingIncidentAccess');
  String get loadingIncidentDashboardAccess =>
      _text('loadingIncidentDashboardAccess');
  String get unableToLoadIncidentAccess => _text('unableToLoadIncidentAccess');
  String get unableToLoadIncidentDashboardAccess =>
      _text('unableToLoadIncidentDashboardAccess');
  String get incidentParameters => _text('incidentParameters');
  String get incidentParametersDescription =>
      _text('incidentParametersDescription');
  String get addItService => _text('addItService');
  String get addCategory => _text('addCategory');
  String get addResolutionCode => _text('addResolutionCode');
  String get editResolutionCode => _text('editResolutionCode');
  String get noResolutionCodes => _text('noResolutionCodes');
  String get resolutionCodeIdentifier => _text('resolutionCodeIdentifier');
  String get resolutionCodeIdentifierHint =>
      _text('resolutionCodeIdentifierHint');
  String get resolutionCodeLabelEnglish => _text('resolutionCodeLabelEnglish');
  String get resolutionCodeLabelFrench => _text('resolutionCodeLabelFrench');
  String get totalIncidentsThisMonth => _text('totalIncidentsThisMonth');
  String get averageResolutionTime => _text('averageResolutionTime');
  String get monthlyIncidentTrend => _text('monthlyIncidentTrend');
  String get ticketsByService => _text('ticketsByService');
  String get ticketsByCategory => _text('ticketsByCategory');
  String get ticketsByDepartment => _text('ticketsByDepartment');
  String get recentCriticalTickets => _text('recentCriticalTickets');
  String get recentCriticalTicketsDescription =>
      _text('recentCriticalTicketsDescription');
  String get criticalTicketsWillAppearHere =>
      _text('criticalTicketsWillAppearHere');
  String get adminReadOnly => _text('adminReadOnly');
  String get incidentStatusOpen => _text('incidentStatusOpen');
  String get incidentStatusCategorized => _text('incidentStatusCategorized');
  String get incidentStatusAssigned => _text('incidentStatusAssigned');
  String get incidentStatusInProgress => _text('incidentStatusInProgress');
  String get incidentStatusResolved => _text('incidentStatusResolved');
  String get incidentStatusClosed => _text('incidentStatusClosed');
  String get incidentStatusArchived => _text('incidentStatusArchived');
  String get incidentStatusCancelled => _text('incidentStatusCancelled');
  String get incidentLifecycleActive => _text('incidentLifecycleActive');
  String get incidentLifecycleClosed => _text('incidentLifecycleClosed');
  String get incidentLifecycleArchived => _text('incidentLifecycleArchived');
  String get incidentImpactLow => _text('incidentImpactLow');
  String get incidentImpactMedium => _text('incidentImpactMedium');
  String get incidentImpactHigh => _text('incidentImpactHigh');
  String get incidentUrgencyLow => _text('incidentUrgencyLow');
  String get incidentUrgencyMedium => _text('incidentUrgencyMedium');
  String get incidentUrgencyHigh => _text('incidentUrgencyHigh');
  String get incidentPriorityUnprioritized =>
      _text('incidentPriorityUnprioritized');
  String get incidentRoleNoAccess => _text('incidentRoleNoAccess');
  String get incidentRoleUser => _text('incidentRoleUser');
  String get incidentRoleManager => _text('incidentRoleManager');
  String get incidentRoleAdmin => _text('incidentRoleAdmin');
  String get userManagement => _text('userManagement');
  String get manageDepartmentsServicesBureauxAgents =>
      _text('manageDepartmentsServicesBureauxAgents');
  String get addDepartment => _text('addDepartment');
  String get addService => _text('addService');
  String get addBureau => _text('addBureau');
  String get addAgent => _text('addAgent');
  String get addModule => _text('addModule');
  String get editDepartment => _text('editDepartment');
  String get editService => _text('editService');
  String get editBureau => _text('editBureau');
  String get editAgent => _text('editAgent');
  String get editModule => _text('editModule');
  String get departmentDetails => _text('departmentDetails');
  String get serviceDetails => _text('serviceDetails');
  String get bureauDetails => _text('bureauDetails');
  String get agentDetails => _text('agentDetails');
  String get moduleDetails => _text('moduleDetails');
  String get deleteDepartment => _text('deleteDepartment');
  String get deleteService => _text('deleteService');
  String get deleteBureau => _text('deleteBureau');
  String get deleteAgent => _text('deleteAgent');
  String get deleteModule => _text('deleteModule');
  String get selectDepartment => _text('selectDepartment');
  String get selectService => _text('selectService');
  String get selectBureau => _text('selectBureau');
  String get searchAgents => _text('searchAgents');
  String get searchDepartments => _text('searchDepartments');
  String get searchServices => _text('searchServices');
  String get searchBureaux => _text('searchBureaux');
  String get headOfDepartment => _text('headOfDepartment');
  String get headOfService => _text('headOfService');
  String get headOfBureau => _text('headOfBureau');
  String get bureauAttache => _text('bureauAttache');
  String get inventory => _text('inventory');
  String get cart => _text('cart');
  String get cartDescription => _text('cartDescription');
  String get deliver => _text('deliver');
  String get restock => _text('restock');
  String totalArticles(Object? count) => _format('totalArticles', {
        'count': count,
      });
  String get selectDirection => _text('selectDirection');
  String get selectBeneficiaryDirection => _text('selectBeneficiaryDirection');
  String get createNewItem => _text('createNewItem');
  String get itemToAddToCart => _text('itemToAddToCart');
  String get article => _text('article');
  String get articles => _text('articles');
  String get quantity => _text('quantity');
  String get stock => _text('stock');
  String get tasks => _text('tasks');
  String get tasksDescription => _text('tasksDescription');
  String get newTask => _text('newTask');
  String get editTask => _text('editTask');
  String get taskDetails => _text('taskDetails');
  String get taskInformation => _text('taskInformation');
  String get taskIdentifier => _text('taskIdentifier');
  String get departmentIdentifier => _text('departmentIdentifier');
  String get creatorIdentifier => _text('creatorIdentifier');
  String get taskCreated => _text('taskCreated');
  String get taskUpdated => _text('taskUpdated');
  String get taskNotFound => _text('taskNotFound');
  String get taskLoadFailed => _text('taskLoadFailed');
  String get taskAccessDenied => _text('taskAccessDenied');
  String get taskDepartmentMissingDescription =>
      _text('taskDepartmentMissingDescription');
  String get adminReadOnlyTask => _text('adminReadOnlyTask');
  String get allDepartmentTasks => _text('allDepartmentTasks');
  String departmentTasks(Object? department) => _format('departmentTasks', {
        'department': department,
      });
  String get loadingTasks => _text('loadingTasks');
  String get noTasks => _text('noTasks');
  String get noTasksDescription => _text('noTasksDescription');
  String get allTypes => _text('allTypes');
  String get createActivity => _text('createActivity');
  String get activityObject => _text('activityObject');
  String get activityObjectHint => _text('activityObjectHint');
  String get remarks => _text('remarks');
  String get remarksHint => _text('remarksHint');
  String get taskStatusNew => _text('taskStatusNew');
  String get taskStatusDoing => _text('taskStatusDoing');
  String get taskStatusDone => _text('taskStatusDone');
  String get taskStatusArchived => _text('taskStatusArchived');
  String get taskTypeTask => _text('taskTypeTask');
  String get taskTypeMail => _text('taskTypeMail');
  String get uploadMailScan => _text('uploadMailScan');
  String get uploadReport => _text('uploadReport');
  String get uploadFile => _text('uploadFile');
  String get upload => _text('upload');
  String get uploading => _text('uploading');
  String get uploadSuccessful => _text('uploadSuccessful');
  String uploadFailed(Object? error) => _format('uploadFailed', {
        'error': error,
      });
  String get uploadedSuccessfully => _text('uploadedSuccessfully');
  String get document => _text('document');
  String get documents => _text('documents');
  String get mailScan => _text('mailScan');
  String get reportFile => _text('reportFile');
  String get storagePath => _text('storagePath');
  String get metadata => _text('metadata');
  String get noDocuments => _text('noDocuments');
  String get preview => _text('preview');
  String get documentPreviewFailed => _text('documentPreviewFailed');
  String get noFileSelected => _text('noFileSelected');
  String get selectFile => _text('selectFile');
  String get replaceFile => _text('replaceFile');
  String get remove => _text('remove');
  String get fileCouldNotBeRead => _text('fileCouldNotBeRead');
  String get fileTooLarge => _text('fileTooLarge');
  String get deleteTask => _text('deleteTask');
  String deleteTaskConfirmation(Object? taskLabel) =>
      _format('deleteTaskConfirmation', {
        'taskLabel': taskLabel,
      });
  String get taskDeleted => _text('taskDeleted');
  String taskDeleteFailed(Object? error) => _format('taskDeleteFailed', {
        'error': error,
      });
  String get departmentRequired => _text('departmentRequired');
  String get mail => _text('mail');
  String get mails => _text('mails');
  String get courrier => _text('courrier');
  String get courriers => _text('courriers');
  String get noCourrierSelected => _text('noCourrierSelected');
  String get noCourrier => _text('noCourrier');
  String get addCourrier => _text('addCourrier');
  String get courrierDetails => _text('courrierDetails');
  String get addAnnotation => _text('addAnnotation');
  String get annotations => _text('annotations');
  String get sender => _text('sender');
  String get receiver => _text('receiver');
  String get subject => _text('subject');
  String get receptionDate => _text('receptionDate');
  String get emissionDate => _text('emissionDate');
  String get weeklyReport => _text('weeklyReport');
  String get weeklyReportFileName => _text('weeklyReportFileName');
  String get informationSystemsDepartment =>
      _text('informationSystemsDepartment');
  String get projectsOtherProcessing => _text('projectsOtherProcessing');
  String get social => _text('social');
  String get socialDashboard => _text('socialDashboard');
  String get socialOffice => _text('socialOffice');
  String get agentsSocial => _text('agentsSocial');
  String get medicalVoucherRequests => _text('medicalVoucherRequests');
  String get refunds => _text('refunds');
  String get refund => _text('refund');
  String get refundList => _text('refundList');
  String get voucherList => _text('voucherList');
  String get dependants => _text('dependants');
  String get dependant => _text('dependant');
  String get noDependantsYet => _text('noDependantsYet');
  String get addDependant => _text('addDependant');
  String get requestVoucher => _text('requestVoucher');
  String get requestRefund => _text('requestRefund');
  String get medicalVoucher => _text('medicalVoucher');
  String get serviceCertificate => _text('serviceCertificate');
  String get agentHasNoDependants => _text('agentHasNoDependants');
  String get unableToLoadDependants => _text('unableToLoadDependants');
  String get loadingDependants => _text('loadingDependants');
  String get unableToLoadRefunds => _text('unableToLoadRefunds');
  String get loadingRefunds => _text('loadingRefunds');
  String get noRefundsYet => _text('noRefundsYet');
  String get refundRequestsWillAppearHere =>
      _text('refundRequestsWillAppearHere');
  String get addDependantsToRequestVouchers =>
      _text('addDependantsToRequestVouchers');
  String get meetingRooms => _text('meetingRooms');
  String get meetingRoom => _text('meetingRoom');
  String get noMeetingRoomsAvailable => _text('noMeetingRoomsAvailable');
  String get newReservation => _text('newReservation');
  String get startTime => _text('startTime');
  String get endTime => _text('endTime');
  String get submitReservation => _text('submitReservation');
  String get createRoom => _text('createRoom');
  String get available => _text('available');
  String get unavailable => _text('unavailable');
  String get capacity => _text('capacity');
  String capacityPeople(Object? count) => _format('capacityPeople', {
        'count': count,
      });
  String get roomLocation => _text('roomLocation');
  String get closeDialog => _text('closeDialog');
  String unableToLoadSchedule(Object? error) =>
      _format('unableToLoadSchedule', {
        'error': error,
      });
  String get dashboard => _text('dashboard');
  String get dashboardTitle => _text('dashboardTitle');
  String get mainDashboard => _text('mainDashboard');
  String get loadingStatistics => _text('loadingStatistics');
  String get errorLoadingData => _text('errorLoadingData');
  String get failedToLoadDashboardStatistics =>
      _text('failedToLoadDashboardStatistics');
  String get dashboardDataDoesNotExist => _text('dashboardDataDoesNotExist');
  String get chartMedicalVouchers => _text('chartMedicalVouchers');
  String get monthJanuaryShort => _text('monthJanuaryShort');
  String get monthFebruaryShort => _text('monthFebruaryShort');
  String get monthMarchShort => _text('monthMarchShort');
  String get monthAprilShort => _text('monthAprilShort');
  String get monthMayShort => _text('monthMayShort');
  String get monthJuneShort => _text('monthJuneShort');
  String get monthJulyShort => _text('monthJulyShort');
  String get monthAugustShort => _text('monthAugustShort');
  String get monthSeptemberShort => _text('monthSeptemberShort');
  String get monthOctoberShort => _text('monthOctoberShort');
  String get monthNovemberShort => _text('monthNovemberShort');
  String get monthDecemberShort => _text('monthDecemberShort');
  String get admin => _text('admin');
  String get manager => _text('manager');
  String get reviewer => _text('reviewer');
  String get noAccess => _text('noAccess');
  String get moduleRoleUser => _text('moduleRoleUser');
  String get moduleRoleManager => _text('moduleRoleManager');
  String get moduleRoleAdmin => _text('moduleRoleAdmin');
  String get moduleRoleReviewer => _text('moduleRoleReviewer');
  String get moduleRoleNone => _text('moduleRoleNone');
  String get permissionAdminDescription => _text('permissionAdminDescription');
  String get permissionManagerDescription =>
      _text('permissionManagerDescription');
  String get permissionUserDescription => _text('permissionUserDescription');
  String get permissionNoneDescription => _text('permissionNoneDescription');
  String get requiredField => _text('requiredField');
  String get enterTitle => _text('enterTitle');
  String get enterShortDescription => _text('enterShortDescription');
  String get enterName => _text('enterName');
  String get enterEmail => _text('enterEmail');
  String get invalidEmail => _text('invalidEmail');
  String get selectRole => _text('selectRole');
  String get selectModule => _text('selectModule');
  String get searchByName => _text('searchByName');
  String get searchByNameEmailOrMatricule =>
      _text('searchByNameEmailOrMatricule');
  String get noResults => _text('noResults');
  String get noItems => _text('noItems');
  String get emptyList => _text('emptyList');
  String get connectionError => _text('connectionError');
  String get unableToConnect => _text('unableToConnect');
  String get serverError => _text('serverError');
  String get permissionDenied => _text('permissionDenied');
  String get file => _text('file');
  String get files => _text('files');
  String get download => _text('download');
  String get print => _text('print');
  String get export => _text('export');
  String get pdf => _text('pdf');
  String get excel => _text('excel');
  String get report => _text('report');
  String get reports => _text('reports');
  String get amount => _text('amount');
  String get hospital => _text('hospital');
  String get relation => _text('relation');
  String get beneficiary => _text('beneficiary');
  String get serviceCatalogueTitle => _text('serviceCatalogueTitle');
  String get serviceCatalogueDescription =>
      _text('serviceCatalogueDescription');
  String get serviceCatalogueSearchHint => _text('serviceCatalogueSearchHint');
  String get serviceCatalogueEmpty => _text('serviceCatalogueEmpty');
  String get serviceCatalogueEmptyDescription =>
      _text('serviceCatalogueEmptyDescription');
  String get browseCatalogue => _text('browseCatalogue');
  String get allCatalogueCategories => _text('allCatalogueCategories');
  String get requestThisService => _text('requestThisService');
  String get createServiceRequest => _text('createServiceRequest');
  String get serviceRequestDetails => _text('serviceRequestDetails');
  String get serviceRequestQueue => _text('serviceRequestQueue');
  String get serviceRequestQueueDescription =>
      _text('serviceRequestQueueDescription');
  String get requestOnBehalfOf => _text('requestOnBehalfOf');
  String get requestedFor => _text('requestedFor');
  String get requestSubmitted => _text('requestSubmitted');
  String get submitRequest => _text('submitRequest');
  String get submittingRequest => _text('submittingRequest');
  String serviceRequestValidationIssues(Object? issues) =>
      _format('serviceRequestValidationIssues', {
        'issues': issues,
      });
  String get requiredDocuments => _text('requiredDocuments');
  String get requiredInformation => _text('requiredInformation');
  String get eligibility => _text('eligibility');
  String get estimatedDelivery => _text('estimatedDelivery');
  String get myRequestsTitle => _text('myRequestsTitle');
  String get myRequestsDescription => _text('myRequestsDescription');
  String get myRequestsSearchHint => _text('myRequestsSearchHint');
  String get myRequestsEmpty => _text('myRequestsEmpty');
  String get myRequestsEmptyDescription => _text('myRequestsEmptyDescription');
  String get allRequestTypes => _text('allRequestTypes');
  String get loadMore => _text('loadMore');
  String get loadingMore => _text('loadingMore');
  String get requestStatusDraft => _text('requestStatusDraft');
  String get requestStatusSubmitted => _text('requestStatusSubmitted');
  String get requestStatusAwaitingApproval =>
      _text('requestStatusAwaitingApproval');
  String get requestStatusApproved => _text('requestStatusApproved');
  String get requestStatusAssigned => _text('requestStatusAssigned');
  String get requestStatusInFulfilment => _text('requestStatusInFulfilment');
  String get requestStatusAwaitingUser => _text('requestStatusAwaitingUser');
  String get requestStatusFulfilled => _text('requestStatusFulfilled');
  String get requestStatusClosed => _text('requestStatusClosed');
  String get requestStatusRejected => _text('requestStatusRejected');
  String get requestStatusCancelled => _text('requestStatusCancelled');
  String get cancelRequest => _text('cancelRequest');
  String get confirmCancelRequest => _text('confirmCancelRequest');
  String get requestCancelled => _text('requestCancelled');
  String get approveRequest => _text('approveRequest');
  String get rejectRequest => _text('rejectRequest');
  String get rejectionReason => _text('rejectionReason');
  String get rejectionReasonRequired => _text('rejectionReasonRequired');
  String get assignRequest => _text('assignRequest');
  String get assignmentGroup => _text('assignmentGroup');
  String get fulfilmentTasks => _text('fulfilmentTasks');
  String get addFulfilmentTask => _text('addFulfilmentTask');
  String get markFulfilled => _text('markFulfilled');
  String get confirmCompletion => _text('confirmCompletion');
  String get approvalHistory => _text('approvalHistory');
  String get statusTimeline => _text('statusTimeline');
  String get linkedRecords => _text('linkedRecords');
  String get relatedAsset => _text('relatedAsset');
  String get relatedIncident => _text('relatedIncident');
  String get relatedServiceRequest => _text('relatedServiceRequest');
  String get relatedChange => _text('relatedChange');
  String get configurationItem => _text('configurationItem');
  String get slaStatus => _text('slaStatus');
  String get slaOnTrack => _text('slaOnTrack');
  String get slaWarning => _text('slaWarning');
  String get slaBreached => _text('slaBreached');
  String get slaPaused => _text('slaPaused');
  String get dueDate => _text('dueDate');
  String get knowledgeBaseTitle => _text('knowledgeBaseTitle');
  String get knowledgeBaseDescription => _text('knowledgeBaseDescription');
  String get knowledgeSearchHint => _text('knowledgeSearchHint');
  String get featuredArticles => _text('featuredArticles');
  String get recentArticles => _text('recentArticles');
  String get knowledgeArticleDetails => _text('knowledgeArticleDetails');
  String get noKnowledgeArticles => _text('noKnowledgeArticles');
  String get noKnowledgeArticlesDescription =>
      _text('noKnowledgeArticlesDescription');
  String get loadingKnowledge => _text('loadingKnowledge');
  String get unableToLoadKnowledge => _text('unableToLoadKnowledge');
  String get wasThisHelpful => _text('wasThisHelpful');
  String get helpful => _text('helpful');
  String get notHelpful => _text('notHelpful');
  String get thankYouForFeedback => _text('thankYouForFeedback');
  String get employeeVisible => _text('employeeVisible');
  String get dsiOnly => _text('dsiOnly');
  String get articleAuthor => _text('articleAuthor');
  String get articleReviewer => _text('articleReviewer');
  String get reviewDate => _text('reviewDate');
  String get expiryDate => _text('expiryDate');
  String get newKnowledgeArticle => _text('newKnowledgeArticle');
  String get editKnowledgeArticle => _text('editKnowledgeArticle');
  String get knowledgeReviewQueue => _text('knowledgeReviewQueue');
  String get manageKnowledge => _text('manageKnowledge');
  String get knowledgeStateDraft => _text('knowledgeStateDraft');
  String get knowledgeStateReview => _text('knowledgeStateReview');
  String get knowledgeStatePublished => _text('knowledgeStatePublished');
  String get knowledgeStateRetired => _text('knowledgeStateRetired');
  String get knowledgeStateArchived => _text('knowledgeStateArchived');
  String get publishArticle => _text('publishArticle');
  String get retireArticle => _text('retireArticle');
  String get archiveArticle => _text('archiveArticle');
  String get articleVersion => _text('articleVersion');
  String get articleContent => _text('articleContent');
  String get articleVisibility => _text('articleVisibility');
  String get articlePublished => _text('articlePublished');
  String get articleRetired => _text('articleRetired');
  String get relatedServices => _text('relatedServices');
  String get relatedCatalogueItems => _text('relatedCatalogueItems');
  String get relatedIncidentCategories => _text('relatedIncidentCategories');
  String get suggestedKnowledge => _text('suggestedKnowledge');
  String get suggestedKnowledgeDescription =>
      _text('suggestedKnowledgeDescription');
  String get viewArticle => _text('viewArticle');
  String get knowledgeAttachments => _text('knowledgeAttachments');
  String get knowledgeAttachmentsHint => _text('knowledgeAttachmentsHint');
  String get internalAttachment => _text('internalAttachment');
  String get operationalActions => _text('operationalActions');
  String get readOnlyAccess => _text('readOnlyAccess');
  String get readOnlyAccessDescription => _text('readOnlyAccessDescription');
  String get assetConfigurationOverview => _text('assetConfigurationOverview');
  String get assetConfigurationOverviewDescription =>
      _text('assetConfigurationOverviewDescription');
  String get myAssets => _text('myAssets');
  String get myAssetsDescription => _text('myAssetsDescription');
  String get assetRegister => _text('assetRegister');
  String get assetRegisterDescription => _text('assetRegisterDescription');
  String get noAssetsAssigned => _text('noAssetsAssigned');
  String get noAssetsFound => _text('noAssetsFound');
  String get unableToLoadAssets => _text('unableToLoadAssets');
  String get searchAssets => _text('searchAssets');
  String get assetTag => _text('assetTag');
  String get serialNumber => _text('serialNumber');
  String get brand => _text('brand');
  String get model => _text('model');
  String get condition => _text('condition');
  String get custodian => _text('custodian');
  String get acquisitionDate => _text('acquisitionDate');
  String get acquisitionCost => _text('acquisitionCost');
  String get supplier => _text('supplier');
  String get warranty => _text('warranty');
  String get securityBaseline => _text('securityBaseline');
  String get lifecycleHistory => _text('lifecycleHistory');
  String get assetPhotographs => _text('assetPhotographs');
  String get reportAssetFault => _text('reportAssetFault');
  String get requestAssetRepair => _text('requestAssetRepair');
  String get requestAssetReplacement => _text('requestAssetReplacement');
  String get requestAssetConfiguration => _text('requestAssetConfiguration');
  String get requestAssetReturn => _text('requestAssetReturn');
  String get assetActionCreatesRequest => _text('assetActionCreatesRequest');
  String get stockManagement => _text('stockManagement');
  String get stockManagementDescription => _text('stockManagementDescription');
  String get stockLocations => _text('stockLocations');
  String get stockItems => _text('stockItems');
  String get stockMovements => _text('stockMovements');
  String get quantityOnHand => _text('quantityOnHand');
  String get quantityReserved => _text('quantityReserved');
  String get quantityAvailable => _text('quantityAvailable');
  String get minimumStockThreshold => _text('minimumStockThreshold');
  String get lowStock => _text('lowStock');
  String get movementType => _text('movementType');
  String get movementReceipt => _text('movementReceipt');
  String get movementReservation => _text('movementReservation');
  String get movementIssue => _text('movementIssue');
  String get movementReturn => _text('movementReturn');
  String get movementTransfer => _text('movementTransfer');
  String get movementAdjustment => _text('movementAdjustment');
  String get movementReconciliation => _text('movementReconciliation');
  String get sourceLocation => _text('sourceLocation');
  String get destinationLocation => _text('destinationLocation');
  String get recipient => _text('recipient');
  String get relatedRequest => _text('relatedRequest');
  String get supportingDocument => _text('supportingDocument');
  String get softwareLicences => _text('softwareLicences');
  String get softwareLicencesDescription =>
      _text('softwareLicencesDescription');
  String get softwareProduct => _text('softwareProduct');
  String get vendor => _text('vendor');
  String get licenceType => _text('licenceType');
  String get purchasedQuantity => _text('purchasedQuantity');
  String get allocatedQuantity => _text('allocatedQuantity');
  String get availableQuantity => _text('availableQuantity');
  String get effectiveDate => _text('effectiveDate');
  String get renewalDate => _text('renewalDate');
  String get complianceStatus => _text('complianceStatus');
  String get licenceAssignments => _text('licenceAssignments');
  String get suppliersWarrantiesDescription =>
      _text('suppliersWarrantiesDescription');
  String get supplierRegister => _text('supplierRegister');
  String get contracts => _text('contracts');
  String get supportTerms => _text('supportTerms');
  String get contractStart => _text('contractStart');
  String get contractEnd => _text('contractEnd');
  String get warrantyCoverage => _text('warrantyCoverage');
  String get warrantyExpiration => _text('warrantyExpiration');
  String get warrantyClaims => _text('warrantyClaims');
  String get configurationManagementDatabase =>
      _text('configurationManagementDatabase');
  String get cmdbDescription => _text('cmdbDescription');
  String get configurationItems => _text('configurationItems');
  String get ciType => _text('ciType');
  String get ciOwner => _text('ciOwner');
  String get supportGroup => _text('supportGroup');
  String get criticality => _text('criticality');
  String get operationalStatus => _text('operationalStatus');
  String get configurationBaseline => _text('configurationBaseline');
  String get dataQualityStatus => _text('dataQualityStatus');
  String get relationships => _text('relationships');
  String get impactView => _text('impactView');
  String get dependencyView => _text('dependencyView');
  String get dependsOn => _text('dependsOn');
  String get runsOn => _text('runsOn');
  String get connectedTo => _text('connectedTo');
  String get uses => _text('uses');
  String get representedBy => _text('representedBy');
  String get managerOperationalAccessRequired =>
      _text('managerOperationalAccessRequired');
  String get assetCommandCompleted => _text('assetCommandCompleted');
  String get stockMovementCompleted => _text('stockMovementCompleted');
  String get licenceOperationCompleted => _text('licenceOperationCompleted');
  String get registerNewAsset => _text('registerNewAsset');
  String get registerNewLicence => _text('registerNewLicence');
  String get allocateLicence => _text('allocateLicence');
  String get releaseLicence => _text('releaseLicence');
  String get saveSupplier => _text('saveSupplier');
  String get saveContract => _text('saveContract');
  String get saveWarranty => _text('saveWarranty');
  String get recordWarrantyClaim => _text('recordWarrantyClaim');
  String get saveConfigurationItem => _text('saveConfigurationItem');
  String get createRelationship => _text('createRelationship');
  String get retireRelationship => _text('retireRelationship');
  String get configurationOperationCompleted =>
      _text('configurationOperationCompleted');
  String get recordIdentifier => _text('recordIdentifier');
  String get categoryId => _text('categoryId');
  String get supplierId => _text('supplierId');
  String get contractId => _text('contractId');
  String get warrantyId => _text('warrantyId');
  String get claimId => _text('claimId');
  String get allocationId => _text('allocationId');
  String get assigneeId => _text('assigneeId');
  String get assigneeName => _text('assigneeName');
  String get assignmentType => _text('assignmentType');
  String get contactName => _text('contactName');
  String get legalName => _text('legalName');
  String get contractNumber => _text('contractNumber');
  String get warrantyNumber => _text('warrantyNumber');
  String get relationshipType => _text('relationshipType');
  String get sourceType => _text('sourceType');
  String get sourceId => _text('sourceId');
  String get targetType => _text('targetType');
  String get targetId => _text('targetId');
  String get linkedAssetId => _text('linkedAssetId');
  String get ownerUserId => _text('ownerUserId');
  String get ownerName => _text('ownerName');
  String get address => _text('address');
  String get currency => _text('currency');
  String get invalidIdentifier => _text('invalidIdentifier');
  String get invalidDate => _text('invalidDate');
  String get positiveWholeNumberRequired =>
      _text('positiveWholeNumberRequired');
  String get isoDateHint => _text('isoDateHint');
  String get assignmentUser => _text('assignmentUser');
  String get assignmentDevice => _text('assignmentDevice');
  String get ciService => _text('ciService');
  String get ciApplication => _text('ciApplication');
  String get ciServer => _text('ciServer');
  String get ciDatabase => _text('ciDatabase');
  String get ciNetwork => _text('ciNetwork');
  String get ciDevice => _text('ciDevice');
  String get statusPlanned => _text('statusPlanned');
  String get statusDegraded => _text('statusDegraded');
  String get statusMaintenance => _text('statusMaintenance');
  String get statusRetired => _text('statusRetired');
  String get dataQualityVerified => _text('dataQualityVerified');
  String get dataQualityNeedsReview => _text('dataQualityNeedsReview');
  String get dataQualityIncomplete => _text('dataQualityIncomplete');
  String get editAsset => _text('editAsset');
  String get assignAsset => _text('assignAsset');
  String get returnAsset => _text('returnAsset');
  String get transitionAsset => _text('transitionAsset');
  String get assignedUserId => _text('assignedUserId');
  String get assignedAssetReturnHint => _text('assignedAssetReturnHint');
  String get transitionReason => _text('transitionReason');
  String get lifecycleOperationCompleted =>
      _text('lifecycleOperationCompleted');
  String get addStockLocation => _text('addStockLocation');
  String get editStockLocation => _text('editStockLocation');
  String get addStockItem => _text('addStockItem');
  String get editStockItem => _text('editStockItem');
  String get stockLocationId => _text('stockLocationId');
  String get stockItemId => _text('stockItemId');
  String get sku => _text('sku');
  String get unitOfMeasure => _text('unitOfMeasure');
  String get isConsumable => _text('isConsumable');
  String get adjustmentDirection => _text('adjustmentDirection');
  String get increaseStock => _text('increaseStock');
  String get decreaseStock => _text('decreaseStock');
  String get reservedQuantityFulfilled => _text('reservedQuantityFulfilled');
  String get targetOnHand => _text('targetOnHand');
  String get targetReserved => _text('targetReserved');
  String get movementReason => _text('movementReason');
  String get movementRequirementsHint => _text('movementRequirementsHint');
  String get sourceLocationRequired => _text('sourceLocationRequired');
  String get destinationLocationRequired =>
      _text('destinationLocationRequired');
  String get recipientRequired => _text('recipientRequired');
  String get evidenceRequired => _text('evidenceRequired');
  String get nonNegativeNumberRequired => _text('nonNegativeNumberRequired');
  String get reservedQuantityTooHigh => _text('reservedQuantityTooHigh');
  String get editSupplier => _text('editSupplier');
  String get editContract => _text('editContract');
  String get editWarranty => _text('editWarranty');
  String get manageWarranty => _text('manageWarranty');
  String get transitionWarrantyClaim => _text('transitionWarrantyClaim');
  String get claimStatus => _text('claimStatus');
  String get claimResolution => _text('claimResolution');
  String get supplierContact => _text('supplierContact');
  String get editConfigurationItem => _text('editConfigurationItem');
  String get relatedIncidentIds => _text('relatedIncidentIds');
  String get relatedRequestIds => _text('relatedRequestIds');
  String get relatedChangeIds => _text('relatedChangeIds');
  String get relatedFindingIds => _text('relatedFindingIds');
  String get commaSeparatedIdsHint => _text('commaSeparatedIdsHint');
  String get allRelationships => _text('allRelationships');
  String get showDependencies => _text('showDependencies');
  String get showImpact => _text('showImpact');
  String get recipientUserId => _text('recipientUserId');
  String get claimSubmitted => _text('claimSubmitted');
  String get claimAcknowledged => _text('claimAcknowledged');
  String get claimApproved => _text('claimApproved');
  String get claimRejected => _text('claimRejected');
  String get claimResolved => _text('claimResolved');
  String get claimClosed => _text('claimClosed');
  String get assetStatusOrdered => _text('assetStatusOrdered');
  String get assetStatusReceived => _text('assetStatusReceived');
  String get assetStatusInStock => _text('assetStatusInStock');
  String get assetStatusConfigured => _text('assetStatusConfigured');
  String get assetStatusAssigned => _text('assetStatusAssigned');
  String get assetStatusReturned => _text('assetStatusReturned');
  String get assetStatusDisposed => _text('assetStatusDisposed');
  String get assetStatusLost => _text('assetStatusLost');
  String get assetStatusStolen => _text('assetStatusStolen');
  String get uploadAssetAttachment => _text('uploadAssetAttachment');
  String get uploadAssetPhotograph => _text('uploadAssetPhotograph');
  String get scanStockBarcode => _text('scanStockBarcode');
  String get scanStockBarcodeHint => _text('scanStockBarcodeHint');
  String get barcodeNotFound => _text('barcodeNotFound');
  String get attachmentRegistrationSuccessful =>
      _text('attachmentRegistrationSuccessful');
  String get chooseSupportingDocument => _text('chooseSupportingDocument');
  String get changeManagementTitle => _text('changeManagementTitle');
  String get changeManagementSubtitle => _text('changeManagementSubtitle');
  String get newChange => _text('newChange');
  String get myChanges => _text('myChanges');
  String get operationalChanges => _text('operationalChanges');
  String get changeEmptyTitle => _text('changeEmptyTitle');
  String get changeEmptyDescription => _text('changeEmptyDescription');
  String get changeRequestDetails => _text('changeRequestDetails');
  String get changeType => _text('changeType');
  String get changeStandard => _text('changeStandard');
  String get changeNormal => _text('changeNormal');
  String get changeEmergency => _text('changeEmergency');
  String get changeJustification => _text('changeJustification');
  String get saveChangeDraft => _text('saveChangeDraft');
  String get submitChange => _text('submitChange');
  String get assessChange => _text('assessChange');
  String get requestChangeApproval => _text('requestChangeApproval');
  String get scheduleChange => _text('scheduleChange');
  String get startImplementation => _text('startImplementation');
  String get recordImplementation => _text('recordImplementation');
  String get recordPostImplementationReview =>
      _text('recordPostImplementationReview');
  String get closeChange => _text('closeChange');
  String get cancelChange => _text('cancelChange');
  String get changeOwner => _text('changeOwner');
  String get changeRequester => _text('changeRequester');
  String get affectedServices => _text('affectedServices');
  String get affectedConfigurationItems => _text('affectedConfigurationItems');
  String get affectedAssets => _text('affectedAssets');
  String get plannedStart => _text('plannedStart');
  String get plannedEnd => _text('plannedEnd');
  String get expectedDowntime => _text('expectedDowntime');
  String get implementationPlan => _text('implementationPlan');
  String get testPlan => _text('testPlan');
  String get communicationPlan => _text('communicationPlan');
  String get rollbackPlan => _text('rollbackPlan');
  String get cabApprovalsTitle => _text('cabApprovalsTitle');
  String get cabApprovalsSubtitle => _text('cabApprovalsSubtitle');
  String get approveChange => _text('approveChange');
  String get approveWithConditions => _text('approveWithConditions');
  String get rejectChange => _text('rejectChange');
  String get requestClarification => _text('requestClarification');
  String get decisionComment => _text('decisionComment');
  String get approvalConditions => _text('approvalConditions');
  String get changeCalendarTitle => _text('changeCalendarTitle');
  String get changeCalendarSubtitle => _text('changeCalendarSubtitle');
  String get calendarMonth => _text('calendarMonth');
  String get calendarWeek => _text('calendarWeek');
  String get calendarAgenda => _text('calendarAgenda');
  String get calendarPrevious => _text('calendarPrevious');
  String get calendarNext => _text('calendarNext');
  String get changeConflict => _text('changeConflict');
  String get maintenancePublished => _text('maintenancePublished');
  String get changeReadOnly => _text('changeReadOnly');
  String get changeCommandSuccessful => _text('changeCommandSuccessful');
  String get changeReasonRequired => _text('changeReasonRequired');
  String get changeSelectStatus => _text('changeSelectStatus');
  String get changeActiveView => _text('changeActiveView');
  String get changeHistoryView => _text('changeHistoryView');
  String get changeStatusDraft => _text('changeStatusDraft');
  String get changeStatusSubmitted => _text('changeStatusSubmitted');
  String get changeStatusAssessment => _text('changeStatusAssessment');
  String get changeStatusAwaitingApproval =>
      _text('changeStatusAwaitingApproval');
  String get changeStatusApproved => _text('changeStatusApproved');
  String get changeStatusScheduled => _text('changeStatusScheduled');
  String get changeStatusImplementation => _text('changeStatusImplementation');
  String get changeStatusReview => _text('changeStatusReview');
  String get changeStatusClosed => _text('changeStatusClosed');
  String get changeStatusRejected => _text('changeStatusRejected');
  String get changeStatusCancelled => _text('changeStatusCancelled');
  String get changeStatusFailed => _text('changeStatusFailed');
  String get changeStatusRolledBack => _text('changeStatusRolledBack');
  String get changeComplexity => _text('changeComplexity');
  String get maintenanceWindow => _text('maintenanceWindow');
  String get changeRisk => _text('changeRisk');
  String get changeRevision => _text('changeRevision');
  String get changeRiskLow => _text('changeRiskLow');
  String get changeRiskMedium => _text('changeRiskMedium');
  String get changeRiskHigh => _text('changeRiskHigh');
  String get changeRiskCritical => _text('changeRiskCritical');
  String get changeServiceFilter => _text('changeServiceFilter');
  String get changeCiFilter => _text('changeCiFilter');
  String get changeRelatedRecords => _text('changeRelatedRecords');
  String get changeImplementationResult => _text('changeImplementationResult');
  String get changePostImplementationReview =>
      _text('changePostImplementationReview');
  String get changeOutcomeSuccessful => _text('changeOutcomeSuccessful');
  String get changeOutcomePartial => _text('changeOutcomePartial');
  String get changeOutcomeFailed => _text('changeOutcomeFailed');
  String get changeOutcomeRolledBack => _text('changeOutcomeRolledBack');
  String get cabMeeting => _text('cabMeeting');
  String get cabMeetings => _text('cabMeetings');
  String get scheduleCabMeeting => _text('scheduleCabMeeting');
  String get cabApprovalGroup => _text('cabApprovalGroup');
  String get cabParticipantIds => _text('cabParticipantIds');
  String get cabMeetingNotes => _text('cabMeetingNotes');
  String get noCabMeetings => _text('noCabMeetings');
  String get changeConflictsOnly => _text('changeConflictsOnly');
  String get changeComments => _text('changeComments');
  String get changeAttachments => _text('changeAttachments');
  String get changeActivityTimeline => _text('changeActivityTimeline');
  String get noChangeComments => _text('noChangeComments');
  String get noChangeAttachments => _text('noChangeAttachments');
  String get noChangeActivity => _text('noChangeActivity');
  String get unableToLoadChangeCollaboration =>
      _text('unableToLoadChangeCollaboration');
  String get requesterVisible => _text('requesterVisible');
  String get internalVisibility => _text('internalVisibility');
  String get changeCollaborationReadOnlyDescription =>
      _text('changeCollaborationReadOnlyDescription');
  String get itsmScSecurityComplianceTitle =>
      _text('itsmScSecurityComplianceTitle');
  String get itsmScSecurityComplianceSubtitle =>
      _text('itsmScSecurityComplianceSubtitle');
  String get itsmScSecurityFindingsTitle =>
      _text('itsmScSecurityFindingsTitle');
  String get itsmScSecurityFindingsSubtitle =>
      _text('itsmScSecurityFindingsSubtitle');
  String get itsmScSecurityExceptionsTitle =>
      _text('itsmScSecurityExceptionsTitle');
  String get itsmScSecurityExceptionsSubtitle =>
      _text('itsmScSecurityExceptionsSubtitle');
  String get itsmScAssetComplianceTitle => _text('itsmScAssetComplianceTitle');
  String get itsmScAssetComplianceSubtitle =>
      _text('itsmScAssetComplianceSubtitle');
  String get itsmScAccessReviewsTitle => _text('itsmScAccessReviewsTitle');
  String get itsmScAccessReviewsSubtitle =>
      _text('itsmScAccessReviewsSubtitle');
  String get itsmScLoading => _text('itsmScLoading');
  String get itsmScRetry => _text('itsmScRetry');
  String get itsmScLoadMore => _text('itsmScLoadMore');
  String get itsmScLoadingMore => _text('itsmScLoadingMore');
  String get itsmScNoData => _text('itsmScNoData');
  String get itsmScNoDataDescription => _text('itsmScNoDataDescription');
  String get itsmScUnableToLoad => _text('itsmScUnableToLoad');
  String get itsmScAccessDenied => _text('itsmScAccessDenied');
  String get itsmScManagerAccessRequired =>
      _text('itsmScManagerAccessRequired');
  String get itsmScSelfServiceAccessRequired =>
      _text('itsmScSelfServiceAccessRequired');
  String get itsmScAdminReadOnlyNotice => _text('itsmScAdminReadOnlyNotice');
  String get itsmScSelfServiceOnlyNotice =>
      _text('itsmScSelfServiceOnlyNotice');
  String get itsmScOperationalView => _text('itsmScOperationalView');
  String get itsmScMyRecords => _text('itsmScMyRecords');
  String get itsmScCampaigns => _text('itsmScCampaigns');
  String get itsmScReviewItems => _text('itsmScReviewItems');
  String get itsmScCorrectionRequests => _text('itsmScCorrectionRequests');
  String get itsmScAllStatuses => _text('itsmScAllStatuses');
  String get itsmScStatus => _text('itsmScStatus');
  String get itsmScSeverity => _text('itsmScSeverity');
  String get itsmScRisk => _text('itsmScRisk');
  String get itsmScOwner => _text('itsmScOwner');
  String get itsmScDueDate => _text('itsmScDueDate');
  String get itsmScUpdated => _text('itsmScUpdated');
  String get itsmScReference => _text('itsmScReference');
  String get itsmScSystem => _text('itsmScSystem');
  String get itsmScDepartment => _text('itsmScDepartment');
  String get itsmScCurrentAccess => _text('itsmScCurrentAccess');
  String get itsmScCurrentRole => _text('itsmScCurrentRole');
  String get itsmScDevice => _text('itsmScDevice');
  String get itsmScAssessedAt => _text('itsmScAssessedAt');
  String get itsmScReviewDate => _text('itsmScReviewDate');
  String get itsmScPeriod => _text('itsmScPeriod');
  String get itsmScEvidence => _text('itsmScEvidence');
  String get itsmScRestrictedEvidenceHidden =>
      _text('itsmScRestrictedEvidenceHidden');
  String get itsmScNewFinding => _text('itsmScNewFinding');
  String get itsmScSubmitException => _text('itsmScSubmitException');
  String get itsmScRecordAssessment => _text('itsmScRecordAssessment');
  String get itsmScNewCampaign => _text('itsmScNewCampaign');
  String get itsmScRequestCorrection => _text('itsmScRequestCorrection');
  String get itsmScRequestRevocation => _text('itsmScRequestRevocation');
  String get itsmScDecide => _text('itsmScDecide');
  String get itsmScApprove => _text('itsmScApprove');
  String get itsmScReject => _text('itsmScReject');
  String get itsmScRetain => _text('itsmScRetain');
  String get itsmScRevoke => _text('itsmScRevoke');
  String get itsmScModify => _text('itsmScModify');
  String get itsmScTransition => _text('itsmScTransition');
  String get itsmScCancel => _text('itsmScCancel');
  String get itsmScSubmit => _text('itsmScSubmit');
  String get itsmScSave => _text('itsmScSave');
  String get itsmScTitle => _text('itsmScTitle');
  String get itsmScDescription => _text('itsmScDescription');
  String get itsmScSource => _text('itsmScSource');
  String get itsmScRequirementOrControl => _text('itsmScRequirementOrControl');
  String get itsmScBusinessJustification =>
      _text('itsmScBusinessJustification');
  String get itsmScScope => _text('itsmScScope');
  String get itsmScRiskDescription => _text('itsmScRiskDescription');
  String get itsmScCompensatingControl => _text('itsmScCompensatingControl');
  String get itsmScReason => _text('itsmScReason');
  String get itsmScComment => _text('itsmScComment');
  String get itsmScAssetId => _text('itsmScAssetId');
  String get itsmScAssetTag => _text('itsmScAssetTag');
  String get itsmScAssetName => _text('itsmScAssetName');
  String get itsmScSummary => _text('itsmScSummary');
  String get itsmScCampaignTitle => _text('itsmScCampaignTitle');
  String get itsmScSystemId => _text('itsmScSystemId');
  String get itsmScSystemName => _text('itsmScSystemName');
  String get itsmScCommandCompleted => _text('itsmScCommandCompleted');
  String get itsmScCommandFailed => _text('itsmScCommandFailed');
  String get itsmScRequiredField => _text('itsmScRequiredField');
  String get itsmScCorrectionSubmitted => _text('itsmScCorrectionSubmitted');
  String get itsmScOwnComplianceUnavailable =>
      _text('itsmScOwnComplianceUnavailable');
  String get itsmScFindingsCount => _text('itsmScFindingsCount');
  String get itsmScExceptionsCount => _text('itsmScExceptionsCount');
  String get itsmScAssessmentsCount => _text('itsmScAssessmentsCount');
  String get itsmScReviewsCount => _text('itsmScReviewsCount');
  String get itsmScComplianceCompliant => _text('itsmScComplianceCompliant');
  String get itsmScComplianceActionRequired =>
      _text('itsmScComplianceActionRequired');
  String get itsmScComplianceAssessmentPending =>
      _text('itsmScComplianceAssessmentPending');
  String get itsmScSeverityLow => _text('itsmScSeverityLow');
  String get itsmScSeverityMedium => _text('itsmScSeverityMedium');
  String get itsmScSeverityHigh => _text('itsmScSeverityHigh');
  String get itsmScSeverityCritical => _text('itsmScSeverityCritical');
  String get itsmScNotAssigned => _text('itsmScNotAssigned');
  String get itsmScOwnerUserId => _text('itsmScOwnerUserId');
  String get itsmScRemediationPlan => _text('itsmScRemediationPlan');
  String get itsmScValidationResult => _text('itsmScValidationResult');
  String get itsmScActionTriageFinding => _text('itsmScActionTriageFinding');
  String get itsmScActionAssignFinding => _text('itsmScActionAssignFinding');
  String get itsmScActionPlanRemediation =>
      _text('itsmScActionPlanRemediation');
  String get itsmScActionSubmitValidation =>
      _text('itsmScActionSubmitValidation');
  String get itsmScActionValidateFinding =>
      _text('itsmScActionValidateFinding');
  String get itsmScActionAcceptRisk => _text('itsmScActionAcceptRisk');
  String get itsmScActionCloseFinding => _text('itsmScActionCloseFinding');
  String get itsmScActionCancelFinding => _text('itsmScActionCancelFinding');
  String get itsmScActionSubmitException =>
      _text('itsmScActionSubmitException');
  String get itsmScActionRequestExceptionApproval =>
      _text('itsmScActionRequestExceptionApproval');
  String get itsmScActionDecideExceptionApproval =>
      _text('itsmScActionDecideExceptionApproval');
  String get itsmScActionActivateException =>
      _text('itsmScActionActivateException');
  String get itsmScActionRenewException => _text('itsmScActionRenewException');
  String get itsmScActionCloseException => _text('itsmScActionCloseException');
  String get itsmScApproverUserId => _text('itsmScApproverUserId');
  String get itsmScApprovalId => _text('itsmScApprovalId');
  String get itsmScDecision => _text('itsmScDecision');
  String get itsmScFindingStatusDetected =>
      _text('itsmScFindingStatusDetected');
  String get itsmScFindingStatusTriaged => _text('itsmScFindingStatusTriaged');
  String get itsmScFindingStatusAssigned =>
      _text('itsmScFindingStatusAssigned');
  String get itsmScFindingStatusRemediation =>
      _text('itsmScFindingStatusRemediation');
  String get itsmScFindingStatusValidation =>
      _text('itsmScFindingStatusValidation');
  String get itsmScFindingStatusClosed => _text('itsmScFindingStatusClosed');
  String get itsmScFindingStatusRiskAccepted =>
      _text('itsmScFindingStatusRiskAccepted');
  String get itsmScFindingStatusCancelled =>
      _text('itsmScFindingStatusCancelled');
  String get itsmScExceptionStatusDraft => _text('itsmScExceptionStatusDraft');
  String get itsmScExceptionStatusSubmitted =>
      _text('itsmScExceptionStatusSubmitted');
  String get itsmScExceptionStatusUnderReview =>
      _text('itsmScExceptionStatusUnderReview');
  String get itsmScExceptionStatusAwaitingApproval =>
      _text('itsmScExceptionStatusAwaitingApproval');
  String get itsmScExceptionStatusApproved =>
      _text('itsmScExceptionStatusApproved');
  String get itsmScExceptionStatusRejected =>
      _text('itsmScExceptionStatusRejected');
  String get itsmScExceptionStatusActive =>
      _text('itsmScExceptionStatusActive');
  String get itsmScExceptionStatusExpired =>
      _text('itsmScExceptionStatusExpired');
  String get itsmScExceptionStatusClosed =>
      _text('itsmScExceptionStatusClosed');
  String get itsmScExceptionStatusCancelled =>
      _text('itsmScExceptionStatusCancelled');
  String get itsmScCampaignStatusDraft => _text('itsmScCampaignStatusDraft');
  String get itsmScCampaignStatusActive => _text('itsmScCampaignStatusActive');
  String get itsmScCampaignStatusCompleted =>
      _text('itsmScCampaignStatusCompleted');
  String get itsmScCampaignStatusCancelled =>
      _text('itsmScCampaignStatusCancelled');
  String get itsmScReviewStatusPending => _text('itsmScReviewStatusPending');
  String get itsmScReviewStatusDecided => _text('itsmScReviewStatusDecided');
  String get itsmScReviewStatusRevocationPending =>
      _text('itsmScReviewStatusRevocationPending');
  String get itsmScReviewStatusCompleted =>
      _text('itsmScReviewStatusCompleted');
  String get itsmScCorrectionStatusSubmitted =>
      _text('itsmScCorrectionStatusSubmitted');
  String get itsmScCorrectionStatusInReview =>
      _text('itsmScCorrectionStatusInReview');
  String get itsmScCorrectionStatusCompleted =>
      _text('itsmScCorrectionStatusCompleted');
  String get itsmScCorrectionStatusRejected =>
      _text('itsmScCorrectionStatusRejected');
  String get itsmScCorrectionStatusCancelled =>
      _text('itsmScCorrectionStatusCancelled');
  String get itsmScValidationPassed => _text('itsmScValidationPassed');
  String get itsmScValidationFailed => _text('itsmScValidationFailed');
  String get itsmScValidationPartial => _text('itsmScValidationPartial');
  String get itsmScRemediationSummary => _text('itsmScRemediationSummary');
  String get itsmScControlOperatingSystem =>
      _text('itsmScControlOperatingSystem');
  String get itsmScControlPatchStatus => _text('itsmScControlPatchStatus');
  String get itsmScControlAntivirus => _text('itsmScControlAntivirus');
  String get itsmScControlEncryption => _text('itsmScControlEncryption');
  String get itsmScControlBackup => _text('itsmScControlBackup');
  String get itsmScControlApprovedSoftware =>
      _text('itsmScControlApprovedSoftware');
  String get itsmScControlSecurityBaseline =>
      _text('itsmScControlSecurityBaseline');
  String get itsmScNotApplicable => _text('itsmScNotApplicable');
  String get itsmScUnknown => _text('itsmScUnknown');
  String get itsmScCompleteRevocationTask =>
      _text('itsmScCompleteRevocationTask');
  String get itsmScActivateCampaign => _text('itsmScActivateCampaign');
  String get itsmScCreateReviewItem => _text('itsmScCreateReviewItem');
  String get itsmScCompleteCampaign => _text('itsmScCompleteCampaign');
  String get itsmScSubjectUserId => _text('itsmScSubjectUserId');
  String get itsmScDepartmentId => _text('itsmScDepartmentId');
  String get itsmScReviewerUserId => _text('itsmScReviewerUserId');
  String get itsmScAssignedToUserId => _text('itsmScAssignedToUserId');
  String get itsmScTargetAccess => _text('itsmScTargetAccess');
  String get itsmScTaskId => _text('itsmScTaskId');
  String get itsmScCompletionEvidenceId => _text('itsmScCompletionEvidenceId');
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales => const <Locale>[
        Locale.fromSubtags(languageCode: 'en'),
        Locale.fromSubtags(languageCode: 'fr'),
      ];

  @override
  bool isSupported(Locale locale) =>
      _supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

const _supportedLanguageCodes = <String>{'en', 'fr'};

const _localizedValues = <String, Map<String, String>>{
  'en': <String, String>{
    'appName': "ARPTC Connect",
    'appTitle': "ARPTC",
    'appShortName': "ARPTC",
    'notAvailable': "N/A",
    'dash': "-",
    'yes': "Yes",
    'no': "No",
    'ok': "OK",
    'cancel': "Cancel",
    'confirm': "Confirm",
    'confirmation': "Confirmation",
    'save': "Save",
    'saving': "Saving...",
    'delete': "Delete",
    'edit': "Edit",
    'add': "Add",
    'create': "Create",
    'update': "Update",
    'submit': "Submit",
    'close': "Close",
    'archive': "Archive",
    'refresh': "Refresh",
    'retry': "Retry",
    'search': "Search",
    'filter': "Filter",
    'clear': "Clear",
    'select': "Select",
    'viewAll': "View All",
    'back': "Back",
    'next': "Next",
    'previous': "Previous",
    'loading': "Loading...",
    'error': "Error",
    'somethingWentWrong': "Something went wrong",
    'unableToLoad': "Unable to load",
    'noDataAvailable': "No data available",
    'noDataDescription': "No data exists yet.",
    'active': "Active",
    'inactive': "Inactive",
    'enabled': "Enabled",
    'disabled': "Disabled",
    'approved': "Approved",
    'pending': "Pending",
    'rejected': "Rejected",
    'archived': "Archived",
    'all': "All",
    'allStatuses': "All statuses",
    'status': "Status",
    'type': "Type",
    'date': "Date",
    'createdAt': "Created at",
    'updatedAt': "Updated at",
    'createdBy': "Created by",
    'assignedTo': "Assigned to",
    'unassigned': "Unassigned",
    'description': "Description",
    'title': "Title",
    'name': "Name",
    'firstName': "First name",
    'lastName': "Last name",
    'postName': "Post-name",
    'fullName': "Full name",
    'email': "Email",
    'noEmail': "No email",
    'phone': "Phone",
    'matricule': "Employee number",
    'position': "Position",
    'category': "Category",
    'subcategory': "Subcategory",
    'department': "Department",
    'departments': "Departments",
    'service': "Service",
    'services': "Services",
    'bureau': "Office",
    'bureaux': "Offices",
    'agent': "Agent",
    'agents': "Agents",
    'user': "User",
    'users': "Users",
    'module': "Module",
    'modules': "Modules",
    'role': "Role",
    'roles': "Roles",
    'permissions': "Permissions",
    'modulePermissions': "Module permissions",
    'profilePicture': "Profile picture",
    'language': "Language",
    'english': "English",
    'french': "French",
    'system': "System",
    'light': "Light",
    'dark': "Dark",
    'navigationHome': "Home",
    'navigationServices': "Services",
    'navigationCourrier': "Mail",
    'navigationCourriers': "Mail",
    'navigationDashboard': "Dashboard",
    'navigationProfile': "Profile",
    'navigationAccount': "Account",
    'navigationAdministration': "Administration",
    'signIn': "Sign in",
    'signOut': "Sign out",
    'signingIn': "Signing in...",
    'emailOrPasswordIncorrect': "Email or password is incorrect",
    'errorOccurred': "An error occurred",
    'emailAlreadyInUse': "Email already in use.",
    'resetPassword': "Reset password",
    'password': "Password",
    'homeNewsTitle': "News",
    'homeNewsDescription':
        "Published posts from authorized company communicators.",
    'companyNews': "Company news",
    'noCompanyNewsYet': "No company news yet",
    'publishedInformationWillAppearHere':
        "Published information will appear here.",
    'loadingCompanyNews': "Loading company news...",
    'unableToLoadCompanyNews': "Unable to load company news",
    'news': "News",
    'newPost': "New Post",
    'postDetails': "Post details",
    'newsEditor': "News editor",
    'newsReview': "News review",
    'reviewPost': "Review post",
    'publishPost': "Publish post",
    'archivePost': "Archive post",
    'submitForReview': "Submit for review",
    'acceptPost': "Accept post",
    'rejectPost': "Reject post",
    'rejectionComment': "Rejection comment",
    'draft': "Draft",
    'accepted': "Accepted",
    'published': "Published",
    'serviceWelcome': "Welcome",
    'loadingModules': "Loading modules...",
    'noAuthorizedModule': "No authorized module",
    'noAuthorizedModuleDescription':
        "No module is authorized for this user. Please contact the administrator.",
    'moduleTasksName': "Tasks",
    'moduleTasksDescription': "Task and activity reporting",
    'moduleInventoryName': "Inventory",
    'moduleInventoryDescription': "Manage organizational stock and items",
    'moduleIncidentName': "Support",
    'moduleIncidentDescription': "IT incident and support management",
    'moduleItsmName': "IT Service Management",
    'moduleItsmDescription':
        "Integrated IT services, support, assets, and governance",
    'itsmLandingTitle': "IT Service Management",
    'itsmLandingDescription':
        "Access support, assets, changes, security, and IT service governance from one place.",
    'itsmSupport': "Support",
    'itsmSupportDescription':
        "Report incidents, request IT services, follow your requests, and find guidance.",
    'itsmAssetsConfiguration': "Assets & Configuration",
    'itsmAssetsConfigurationDescription':
        "Manage IT assets, stock, licences, suppliers, warranties, and configuration items.",
    'itsmChanges': "Changes",
    'itsmChangesDescription':
        "Plan, approve, schedule, and review controlled changes to IT services.",
    'itsmSecurityCompliance': "Security & Compliance",
    'itsmSecurityComplianceDescription':
        "Track security findings, exceptions, asset compliance, and access reviews.",
    'itsmReportingAdministration': "Reporting & Administration",
    'itsmReportingAdministrationDescription':
        "Monitor service performance and manage ITSM policies, workflows, and audit records.",
    'itsmIncidents': "Incidents",
    'itsmServiceRequests': "Service Requests",
    'itsmMyRequests': "My Requests",
    'itsmSearchWorkItems': "Search by reference, title, or description",
    'itsmWorkItemType': "Request type",
    'itsmFilterByDate': "Filter by creation date",
    'itsmLoadMore': "Load more",
    'itsmAddComment': "Add comment",
    'itsmLinkedRecords': "Linked records",
    'itsmLinkRecord': "Link record",
    'itsmUpdateTask': "Update task",
    'itsmStartFulfilment': "Start fulfilment",
    'itsmMarkFulfilled': "Mark fulfilled",
    'itsmConfirmCompletion': "Confirm completion",
    'itsmCancelRequest': "Cancel request",
    'itsmRejectRequest': "Reject request",
    'itsmConfirmStatusChange': "Do you want to apply this status change?",
    'itsmActionCompleted': "Action completed.",
    'itsmAssignRequest': "Assign request",
    'actions': "Actions",
    'assign': "Assign",
    'reason': "Reason",
    'visibility': "Visibility",
    'id': "ID",
    'reference': "Reference",
    'itsmKnowledgeBase': "Knowledge Base",
    'itsmAssets': "Assets",
    'itsmStock': "Stock",
    'itsmLicences': "Licences",
    'itsmSuppliersWarranties': "Suppliers & Warranties",
    'itsmCmdb': "CMDB",
    'itsmChangeRequests': "Change Requests",
    'itsmApprovalsCab': "Approvals / CAB",
    'itsmChangeCalendar': "Change Calendar",
    'itsmSecurityFindings': "Security Findings",
    'itsmSecurityExceptions': "Security Exceptions",
    'itsmAssetCompliance': "Asset Compliance",
    'itsmAccessReviews': "Access Reviews",
    'itsmDashboards': "Dashboards",
    'itsmSla': "SLA",
    'itsmServiceCatalogue': "Service Catalogue",
    'itsmWorkflowConfiguration': "Workflow Configuration",
    'itsmAuditLogs': "Audit Logs",
    'itsmFeatureCardDescription': "Open this ITSM capability.",
    'itsmFeatureUnavailableDescription':
        "This capability is part of the staged ITSM rollout and is not available in this phase. No protected data has been loaded.",
    'itsmAccessDeniedTitle': "ITSM access restricted",
    'itsmAccessDeniedDescription':
        "Your current ITSM role does not allow access to this area.",
    'itsmLoadingAccess': "Loading ITSM access...",
    'itsmUnableToLoadAccess': "Unable to load ITSM access",
    'moduleUserManagementName': "User Management",
    'moduleUserManagementDescription':
        "Manage departments, services, offices, agents, and modules",
    'moduleNewsName': "News",
    'moduleNewsDescription': "Company communication and publishing",
    'moduleCourrierName': "Mail",
    'moduleCourrierDescription': "Official mail and routing",
    'profile': "Profile",
    'profileUnavailable': "Profile unavailable",
    'profileUnavailableDescription':
        "No agent data is cached on this device for the current session.",
    'connectedAgentInformation': "Connected agent information",
    'agentInformation': "Agent Information",
    'noFields': "No fields",
    'noProfileFieldsAvailable': "No profile fields available.",
    'refreshProfile': "Refresh Profile",
    'loadingProfile': "Loading profile...",
    'unableToLoadProfile': "Unable to load profile",
    'enableNotifications': "Enable notifications",
    'notificationsEnabled': "Notifications are enabled.",
    'notificationPermissionNotGranted':
        "Notification permission was not granted yet.",
    'unableToEnableNotifications': "Unable to enable notifications",
    'webPushNotConfigured': "Web push is not configured",
    'webPushNotConfiguredDescription':
        "Web push is not configured for this build. Rebuild with the Firebase Web Push VAPID key.",
    'webPushNotConfiguredAction':
        "Run or build the web app with --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_KEY, then try again.",
    'disableNotifications': "Disable notifications",
    'notificationsBlocked': "Notifications are blocked",
    'notificationsEnabledForPlatform':
        "Notifications are enabled for this {platform}.",
    'notificationsProvisionallyEnabled':
        "Notifications are provisionally enabled.",
    'notificationsBlockedForPlatform':
        "Notifications are blocked for this {platform}.",
    'allowNotificationsPrompt':
        "Check this box to allow ARPTC Connect to send notifications.",
    'disableNotificationsWindows':
        "Notification permissions are controlled by Windows and your browser.\n\nTo disable them, open the browser site settings for this app and block notifications. You can also open Windows Settings > System > Notifications, then disable notifications for the installed ARPTC Connect app, Chrome, or Edge.",
    'disableNotificationsMac':
        "Notification permissions are controlled by macOS and your browser.\n\nTo disable them, open System Settings > Notifications, then disable notifications for ARPTC Connect or Safari. You can also use Safari > Settings > Websites > Notifications to block this app domain.",
    'disableNotificationsWeb':
        "Notification permissions are controlled by your browser. Use the site settings in your browser to block notifications for this app.",
    'disableNotificationsDevice':
        "Notification permissions are controlled by this device. Use your system notification settings to disable notifications for ARPTC Connect.",
    'blockedNotificationsWindows':
        "Windows or your browser has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOn Windows, open Settings > System > Notifications and make sure notifications are enabled for the installed ARPTC Connect app, Google Chrome, or Microsoft Edge.\n\nThen open your browser site settings for this app domain and set Notifications to Allow. In Chrome or Edge, this is usually Settings > Privacy and security > Site settings > Notifications. After that, reopen the installed app and enable notifications again from this profile page.",
    'blockedNotificationsMac':
        "Safari or macOS has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOn macOS, open System Settings > Notifications, then select ARPTC Connect or Safari and allow notifications.\n\nIf it is still blocked, open Safari > Settings > Websites > Notifications, find this app domain, then change it to Allow or remove the saved decision. After that, reopen the installed app and enable notifications again from this profile page.",
    'blockedNotificationsWeb':
        "Your browser has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOpen the browser site settings for this app domain, set Notifications to Allow, then reopen the app and enable notifications again from this profile page.",
    'blockedNotificationsDevice':
        "This device has blocked notifications for ARPTC Connect.\n\nOpen your system notification settings, allow notifications for ARPTC Connect, then return to this profile page and enable notifications again.",
    'notifications': "Notifications",
    'noNotificationsYet': "No notifications yet",
    'noNotificationsDescription':
        "Notifications about incidents, news, and workflows will appear here.",
    'loadingNotifications': "Loading notifications...",
    'unableToLoadNotifications': "Unable to load notifications",
    'clearAllNotifications': "Clear all notifications",
    'notificationsCleared': "Notifications cleared.",
    'unableToClearNotifications': "Unable to clear notifications",
    'everyone': "Everyone",
    'forYou': "For you",
    'erp': "ERP",
    'incidentManagement': "Incident Management",
    'incidentSupport': "Support",
    'incidentOperations': "Incident Operations",
    'incidentOperationsDescription':
        "Live operational view for IT triage and resolution.",
    'incidentSupervision': "Incident Supervision",
    'incidentSupervisionDescription':
        "Read-only global visibility across active, closed, and archived incidents.",
    'newIncident': "New Incident",
    'newSupportIncident': "New Support Incident",
    'submitSupportTicket': "Submit a Support Ticket",
    'submitTicket': "Submit ticket",
    'submitting': "Submitting...",
    'createIncidentManagerDescription':
        "Create and categorize an incident in one pass.",
    'createIncidentUserDescription':
        "Tell IT what is blocked. The support team will categorize the rest.",
    'readOnlyIncidentAccess': "Read-only incident access",
    'onlyUsersAndManagersCreateIncidents':
        "Only users and managers can create incident tickets.",
    'titleExampleEmailAccess': "Example: Unable to access email",
    'shortDescription': "Short description",
    'describeIssue': "Describe the issue",
    'describeIssueAndWork':
        "Describe what happened and what you were trying to do",
    'affectedItService': "Affected IT service",
    'selectAffectedService': "Select the service you cannot reach",
    'thisIssueBlocksMyWork': "This issue blocks my work",
    'blockingWorkDescription':
        "Turn this on if you cannot continue your normal work.",
    'managerCategorization': "Manager categorization",
    'managerCategorizationDescription':
        "Managers create the first two workflow steps together: submission and categorization.",
    'affectedAgent': "Affected agent",
    'searchAffectedAgentHint': "Leave empty to create the ticket for yourself",
    'searchByNameEmailMatricule': "Search by name, email, or employee number",
    'location': "Location",
    'locationHint': "Office, floor, room",
    'deviceType': "Device type",
    'deviceTypeHint': "Laptop, printer, phone",
    'assetId': "Asset ID",
    'assetIdHint': "Optional asset identifier",
    'impact': "Impact",
    'urgency': "Urgency",
    'impactDescription': "Impact description",
    'impactDescriptionHint': "Optional note about how work is affected",
    'selectCategory': "Select a category",
    'selectImpact': "Select Impact",
    'selectUrgency': "Select Urgency",
    'completeCategoryImpactUrgency':
        "Complete category, impact, and urgency before submitting.",
    'openTickets': "Open Tickets",
    'openTicketsSubtitle': "Submitted, not categorized",
    'unassignedTickets': "Unassigned Tickets",
    'unassignedTicketsSubtitle': "Categorized, not assigned",
    'assignedToMe': "Assigned To Me",
    'solvedTickets': "Solved Tickets",
    'solvedTicketsSubtitle': "Solved, not closed",
    'criticalTickets': "Critical Tickets",
    'criticalTicketsSubtitle': "P1 and P2 active tickets",
    'closedThisWeek': "Closed This Week",
    'parameters': "Parameters",
    'operationalQueue': "Operational Queue",
    'operationalQueueDescription':
        "Active incidents sorted by priority first, then oldest first.",
    'noActiveIncident': "No active incident",
    'newOperationalTicketsWillAppearHere':
        "New operational tickets will appear here.",
    'myAssignedTickets': "My Assigned Tickets",
    'myAssignedTicketsDescription':
        "Active incidents currently assigned to you.",
    'ticketsByPriority': "Tickets by Priority",
    'ticketsByStatus': "Tickets by Status",
    'ticketsByAffectedService': "Tickets by Affected Service",
    'agingTickets': "Aging Tickets",
    'ticket': "Ticket",
    'priority': "Priority",
    'age': "Age",
    'createdAtColumn': "Created at",
    'openTicketsQueueDescription':
        "Tickets submitted by users that have not been categorized yet.",
    'unassignedTicketsQueueDescription':
        "Categorized tickets waiting for an IT staff assignment.",
    'assignedToMeQueueDescription':
        "Active tickets assigned to the current manager.",
    'solvedTicketsQueueDescription':
        "Solved tickets waiting to be marked closed.",
    'closedTicketHistory': "Closed ticket history",
    'closedTicketHistoryDescription':
        "Review incidents completed and closed by IT support.",
    'noClosedTicketsHistory': "No closed tickets",
    'noClosedTicketsHistoryDescription': "Closed incidents will appear here.",
    'noTicketsFound': "No tickets found",
    'queueEmpty': "This queue is empty.",
    'tryAnotherSearchOrStatus': "Try another search or status filter.",
    'thereIsNoQueueItem': "There is no {queueLabel}.",
    'searchIncidents': "Search incidents",
    'ticketDetails': "Incident Details",
    'incidentNotFound': "Incident not found",
    'loadingIncident': "Loading incident...",
    'unableToLoadIncident': "Unable to load incident",
    'timeline': "Timeline",
    'requester': "Requester",
    'affectedService': "Affected service",
    'blocking': "Blocking",
    'resolutionSummary': "Resolution summary",
    'resolutionSummaryHint': "Explain what solved the incident",
    'resolutionCode': "Resolution code",
    'resolutionCodeHint': "Select how the incident was resolved",
    'resolutionCodes': "Resolution codes",
    'selectResolutionCode': "Select a resolution code",
    'selectResolutionCodeBeforeSolved':
        "Select a resolution code before marking the ticket solved.",
    'selectResolutionCodeBeforeClosing':
        "Select a resolution code before closing the ticket.",
    'closedAt': "Closed at",
    'archiveEligible': "Archive eligible",
    'internalNotes': "Internal notes",
    'addNote': "Add note",
    'addInternalNoteHint': "Only IT staff can see internal notes",
    'adding': "Adding...",
    'internalNoteAdded': "Internal note added.",
    'workflowStepSubmitTicket': "Step 1: Submit ticket",
    'workflowStepSubmitTicketDescription':
        "The requester provides basic details.",
    'workflowStepCategorizeTicket': "Step 2: Categorize ticket",
    'workflowStepCategorizeOpenDescription':
        "Complete triage and move this ticket to in progress.",
    'workflowStepCategorizeActiveDescription':
        "Operational categorization can still be updated while active.",
    'workflowStepAssignTicket': "Step 3: Assign ticket",
    'workflowStepAssignTicketDescription':
        "Assign the incident to IT staff. The ticket status does not change here.",
    'workflowStepSolveTicket': "Step 4: Solve ticket",
    'workflowStepSolveTicketDescription':
        "Record the resolution summary before closing.",
    'workflowStepCloseTicket': "Step 5: Close ticket",
    'workflowStepCloseTicketDescription':
        "Close the ticket once the solution is validated.",
    'categorizeTicket': "Categorize ticket",
    'categorizing': "Categorizing...",
    'ticketCategorized': "Ticket categorized.",
    'assignTicket': "Assign ticket",
    'assigning': "Assigning...",
    'ticketAssigned': "Ticket assigned.",
    'markTicketSolved': "Mark the ticket solved",
    'markingSolved': "Marking solved...",
    'ticketMarkedSolved': "Ticket marked solved.",
    'markTicketClosed': "Mark the ticket closed",
    'closing': "Closing...",
    'ticketClosed': "Ticket closed.",
    'cancelTicket': "Cancel ticket",
    'cancelThisTicket': "Cancel this ticket?",
    'cancelTicketWarning':
        "This should only be used when the incident is a false alarm. The ticket will leave the operational queue.",
    'keepTicket': "Keep ticket",
    'cancelling': "Cancelling...",
    'ticketCancelled': "Ticket cancelled.",
    'selectServiceCategoryImpactUrgency':
        "Select affected service, category, impact, and urgency first.",
    'selectItStaffAssignee':
        "Select the IT staff member who will solve the incident.",
    'enterResolutionSummaryBeforeSolved':
        "Enter a resolution summary before marking solved.",
    'enterResolutionSummaryBeforeClosing':
        "Enter a resolution summary before closing.",
    'myIncidents': "My incidents",
    'createAndFollowIncidents': "Create and follow your IT incidents",
    'activeIncidents': "Active",
    'closedAndArchived': "Closed & archived",
    'noActiveIncidentUserDescription': "Your open incidents will appear here.",
    'noClosedIncident': "No closed incident",
    'closedAndArchivedDescription':
        "Closed and archived incidents will appear here.",
    'loadingIncidents': "Loading incidents...",
    'unableToLoadIncidents': "Unable to load incidents",
    'incidentAccessUnavailable': "Incident access unavailable",
    'incidentAccessUnavailableDescription':
        "No Incident Management permission is assigned to this agent.",
    'noIncidentDashboardAccess':
        "You do not have access to the Incident Management dashboard.",
    'loadingIncidentAccess': "Loading incident access...",
    'loadingIncidentDashboardAccess': "Loading incident dashboard access...",
    'unableToLoadIncidentAccess': "Unable to load incident access",
    'unableToLoadIncidentDashboardAccess':
        "Unable to load incident dashboard access",
    'incidentParameters': "Incident Parameters",
    'incidentParametersDescription':
        "Configure IT services, categories, and resolution codes used by support tickets.",
    'addItService': "Add IT service",
    'addCategory': "Add category",
    'addResolutionCode': "Add resolution code",
    'editResolutionCode': "Edit resolution code",
    'noResolutionCodes': "No resolution codes available",
    'resolutionCodeIdentifier': "Code identifier",
    'resolutionCodeIdentifierHint': "Example: FIXED or WORKAROUND_PROVIDED",
    'resolutionCodeLabelEnglish': "English label",
    'resolutionCodeLabelFrench': "French label",
    'totalIncidentsThisMonth': "Total Incidents This Month",
    'averageResolutionTime': "Average Resolution Time",
    'monthlyIncidentTrend': "Monthly Incident Trend",
    'ticketsByService': "Tickets by Service",
    'ticketsByCategory': "Tickets by Category",
    'ticketsByDepartment': "Tickets by Department",
    'recentCriticalTickets': "Recent Critical Tickets",
    'recentCriticalTicketsDescription':
        "Latest P1 and P2 incidents. This list is read-only for admins.",
    'criticalTicketsWillAppearHere': "P1 and P2 incidents will appear here.",
    'adminReadOnly': "Read-only",
    'incidentStatusOpen': "Open",
    'incidentStatusCategorized': "Categorized",
    'incidentStatusAssigned': "Assigned",
    'incidentStatusInProgress': "In progress",
    'incidentStatusResolved': "Resolved",
    'incidentStatusClosed': "Closed",
    'incidentStatusArchived': "Archived",
    'incidentStatusCancelled': "Cancelled",
    'incidentLifecycleActive': "Active",
    'incidentLifecycleClosed': "Closed",
    'incidentLifecycleArchived': "Archived",
    'incidentImpactLow': "Low",
    'incidentImpactMedium': "Medium",
    'incidentImpactHigh': "High",
    'incidentUrgencyLow': "Low",
    'incidentUrgencyMedium': "Medium",
    'incidentUrgencyHigh': "High",
    'incidentPriorityUnprioritized': "Unprioritized",
    'incidentRoleNoAccess': "No access",
    'incidentRoleUser': "User",
    'incidentRoleManager': "Manager",
    'incidentRoleAdmin': "Admin",
    'userManagement': "User Management",
    'manageDepartmentsServicesBureauxAgents':
        "Manage departments, services, offices, modules, and agents.",
    'addDepartment': "Add Department",
    'addService': "Add Service",
    'addBureau': "Add Office",
    'addAgent': "Add Agent",
    'addModule': "Add Module",
    'editDepartment': "Edit Department",
    'editService': "Edit Service",
    'editBureau': "Edit Office",
    'editAgent': "Edit Agent",
    'editModule': "Edit Module",
    'departmentDetails': "Department details",
    'serviceDetails': "Service details",
    'bureauDetails': "Office details",
    'agentDetails': "Agent details",
    'moduleDetails': "Module details",
    'deleteDepartment': "Delete department",
    'deleteService': "Delete service",
    'deleteBureau': "Delete office",
    'deleteAgent': "Delete agent",
    'deleteModule': "Delete module",
    'selectDepartment': "Select department",
    'selectService': "Select service",
    'selectBureau': "Select office",
    'searchAgents': "Search agents",
    'searchDepartments': "Search departments",
    'searchServices': "Search services",
    'searchBureaux': "Search offices",
    'headOfDepartment': "Head of department",
    'headOfService': "Head of service",
    'headOfBureau': "Head of office",
    'bureauAttache': "Office attaché",
    'inventory': "Inventory",
    'cart': "Cart",
    'cartDescription': "List of items in the cart",
    'deliver': "Deliver",
    'restock': "Restock",
    'totalArticles': "Total: {count} items",
    'selectDirection': "Select the direction",
    'selectBeneficiaryDirection': "Select the beneficiary direction",
    'createNewItem': "Create a new item",
    'itemToAddToCart': "Item to add to cart",
    'article': "Item",
    'articles': "Items",
    'quantity': "Quantity",
    'stock': "Stock",
    'tasks': "Tasks",
    'tasksDescription': "Record and manage departmental activities",
    'newTask': "New Task",
    'editTask': "Edit task",
    'taskDetails': "Task Details",
    'taskInformation': "Task information",
    'taskIdentifier': "Task ID",
    'departmentIdentifier': "Department ID",
    'creatorIdentifier': "Creator user ID",
    'taskCreated': "Task created",
    'taskUpdated': "Task updated",
    'taskNotFound': "Task not found",
    'taskLoadFailed': "Unable to load tasks",
    'taskAccessDenied': "You do not have access to task management.",
    'taskDepartmentMissingDescription':
        "Your profile must be linked to a department before you can access departmental tasks.",
    'adminReadOnlyTask':
        "Administrator access is read-only. You can review tasks from every department.",
    'allDepartmentTasks': "Tasks from all departments",
    'departmentTasks': "Tasks for {department}",
    'loadingTasks': "Loading tasks...",
    'noTasks': "No tasks found",
    'noTasksDescription': "No task matches the selected filters.",
    'allTypes': "All types",
    'createActivity': "Create an activity",
    'activityObject': "Activity object",
    'activityObjectHint': "Enter the activity object",
    'remarks': "Remarks",
    'remarksHint': "Enter the project or mail remark",
    'taskStatusNew': "New",
    'taskStatusDoing': "In progress",
    'taskStatusDone': "Processed",
    'taskStatusArchived': "Archived",
    'taskTypeTask': "Projects / Other processing",
    'taskTypeMail': "Mail / NSI",
    'uploadMailScan': "Upload Mail Scan",
    'uploadReport': "Upload Report",
    'uploadFile': "Upload File",
    'upload': "Upload",
    'uploading': "Uploading...",
    'uploadSuccessful': "Upload successful!",
    'uploadFailed': "Upload failed: {error}",
    'uploadedSuccessfully': "Uploaded Successfully!",
    'document': "Document",
    'documents': "Documents",
    'mailScan': "Mail scan",
    'reportFile': "Activity report",
    'storagePath': "Storage path",
    'metadata': "Metadata",
    'noDocuments': "No documents have been attached.",
    'preview': "Preview",
    'documentPreviewFailed': "This document could not be opened.",
    'noFileSelected': "No file selected",
    'selectFile': "Select file",
    'replaceFile': "Replace file",
    'remove': "Remove",
    'fileCouldNotBeRead': "The selected file could not be read.",
    'fileTooLarge': "The selected file exceeds the 20 MB limit.",
    'deleteTask': "Delete task",
    'deleteTaskConfirmation': "Do you really want to delete \"{taskLabel}\"?",
    'taskDeleted': "Task deleted",
    'taskDeleteFailed': "Unable to delete the task: {error}",
    'departmentRequired': "Department required",
    'mail': "Mail",
    'mails': "Mails",
    'courrier': "Mail",
    'courriers': "Mail",
    'noCourrierSelected': "No mail selected",
    'noCourrier': "No mail",
    'addCourrier': "Add mail",
    'courrierDetails': "Mail details",
    'addAnnotation': "Add annotation",
    'annotations': "Annotations",
    'sender': "Sender",
    'receiver': "Receiver",
    'subject': "Subject",
    'receptionDate': "Reception date",
    'emissionDate': "Emission date",
    'weeklyReport': "Weekly Report",
    'weeklyReportFileName': "weekly report",
    'informationSystemsDepartment': "Information Systems Department",
    'projectsOtherProcessing': "Projects / Other processing",
    'social': "Social",
    'socialDashboard': "Social Dashboard",
    'socialOffice': "Social Office",
    'agentsSocial': "Agents",
    'medicalVoucherRequests': "Voucher Requests",
    'refunds': "Refunds",
    'refund': "Refund",
    'refundList': "Refund list",
    'voucherList': "Voucher list",
    'dependants': "Dependants",
    'dependant': "Dependant",
    'noDependantsYet': "No dependants yet",
    'addDependant': "Add Dependant",
    'requestVoucher': "Request Voucher",
    'requestRefund': "Request Refund",
    'medicalVoucher': "Medical Voucher",
    'serviceCertificate': "Service Certificate",
    'agentHasNoDependants': "This agent has no dependants",
    'unableToLoadDependants': "Unable to load dependants",
    'loadingDependants': "Loading dependants...",
    'unableToLoadRefunds': "Unable to load refunds",
    'loadingRefunds': "Loading refunds...",
    'noRefundsYet': "No refunds yet",
    'refundRequestsWillAppearHere': "Your refund requests will appear here",
    'addDependantsToRequestVouchers': "Add your dependants to request vouchers",
    'meetingRooms': "Meeting rooms",
    'meetingRoom': "Meeting room",
    'noMeetingRoomsAvailable': "No meeting room available.",
    'newReservation': "New reservation",
    'startTime': "Start time",
    'endTime': "End time",
    'submitReservation': "Submit",
    'createRoom': "Create room",
    'available': "Available",
    'unavailable': "Unavailable",
    'capacity': "Capacity",
    'capacityPeople': "Capacity: {count} people",
    'roomLocation': "Location",
    'closeDialog': "Close",
    'unableToLoadSchedule': "Unable to load schedule: {error}",
    'dashboard': "Dashboard",
    'dashboardTitle': "Dashboard",
    'mainDashboard': "Main Dashboard",
    'loadingStatistics': "Loading statistics...",
    'errorLoadingData': "Error loading data",
    'failedToLoadDashboardStatistics': "Failed to load dashboard statistics",
    'dashboardDataDoesNotExist': "Dashboard data does not exist",
    'chartMedicalVouchers': "Number of vouchers",
    'monthJanuaryShort': "Jan",
    'monthFebruaryShort': "Feb",
    'monthMarchShort': "Mar",
    'monthAprilShort': "Apr",
    'monthMayShort': "May",
    'monthJuneShort': "Jun",
    'monthJulyShort': "Jul",
    'monthAugustShort': "Aug",
    'monthSeptemberShort': "Sep",
    'monthOctoberShort': "Oct",
    'monthNovemberShort': "Nov",
    'monthDecemberShort': "Dec",
    'admin': "Admin",
    'manager': "Manager",
    'reviewer': "Reviewer",
    'noAccess': "No access",
    'moduleRoleUser': "User",
    'moduleRoleManager': "Manager",
    'moduleRoleAdmin': "Admin",
    'moduleRoleReviewer': "Reviewer",
    'moduleRoleNone': "None",
    'permissionAdminDescription':
        "Can supervise the module according to the configured access model.",
    'permissionManagerDescription':
        "Can manage operational work in the module.",
    'permissionUserDescription': "Can use the module for their own work.",
    'permissionNoneDescription': "No access to this module.",
    'requiredField': "This field is required",
    'enterTitle': "Enter a title",
    'enterShortDescription': "Enter a short description",
    'enterName': "Enter a name",
    'enterEmail': "Enter an email",
    'invalidEmail': "Enter a valid email address.",
    'selectRole': "Select a role",
    'selectModule': "Select a module",
    'searchByName': "Search by name",
    'searchByNameEmailOrMatricule': "Search by name, email, or employee number",
    'noResults': "No results",
    'noItems': "No items",
    'emptyList': "The list is empty.",
    'connectionError': "Connection error",
    'unableToConnect': "Unable to connect",
    'serverError': "Server error",
    'permissionDenied': "Missing or insufficient permissions.",
    'file': "File",
    'files': "Files",
    'download': "Download",
    'print': "Print",
    'export': "Export",
    'pdf': "PDF",
    'excel': "Excel",
    'report': "Report",
    'reports': "Reports",
    'amount': "Amount",
    'hospital': "Hospital",
    'relation': "Relation",
    'beneficiary': "Beneficiary",
    'serviceCatalogueTitle': "Service Catalogue",
    'serviceCatalogueDescription':
        "Browse published IT services and submit a guided request.",
    'serviceCatalogueSearchHint': "Search services",
    'serviceCatalogueEmpty': "No catalogue services are available",
    'serviceCatalogueEmptyDescription':
        "Published services will appear here when they become available.",
    'browseCatalogue': "Browse catalogue",
    'allCatalogueCategories': "All categories",
    'requestThisService': "Request this service",
    'createServiceRequest': "Create service request",
    'serviceRequestDetails': "Service request details",
    'serviceRequestQueue': "Service request queue",
    'serviceRequestQueueDescription':
        "Review, assign, approve, and fulfil service requests.",
    'requestOnBehalfOf': "Request on behalf of an agent",
    'requestedFor': "Requested for",
    'requestSubmitted': "Your service request has been submitted.",
    'submitRequest': "Submit request",
    'submittingRequest': "Submitting request...",
    'serviceRequestValidationIssues':
        "Please correct the following request fields: {issues}",
    'requiredDocuments': "Required documents",
    'requiredInformation': "Required information",
    'eligibility': "Eligibility",
    'estimatedDelivery': "Estimated delivery",
    'myRequestsTitle': "My Requests",
    'myRequestsDescription':
        "Track your incidents, service requests, and other ITSM work in one place.",
    'myRequestsSearchHint': "Search by reference or title",
    'myRequestsEmpty': "You have no requests yet",
    'myRequestsEmptyDescription':
        "Incidents and service requests that you submit will appear here.",
    'allRequestTypes': "All request types",
    'loadMore': "Load more",
    'loadingMore': "Loading more...",
    'requestStatusDraft': "Draft",
    'requestStatusSubmitted': "Submitted",
    'requestStatusAwaitingApproval': "Awaiting approval",
    'requestStatusApproved': "Approved",
    'requestStatusAssigned': "Assigned",
    'requestStatusInFulfilment': "In fulfilment",
    'requestStatusAwaitingUser': "Awaiting user",
    'requestStatusFulfilled': "Fulfilled",
    'requestStatusClosed': "Closed",
    'requestStatusRejected': "Rejected",
    'requestStatusCancelled': "Cancelled",
    'cancelRequest': "Cancel request",
    'confirmCancelRequest':
        "Cancel this request? This action cannot be undone.",
    'requestCancelled': "The request has been cancelled.",
    'approveRequest': "Approve request",
    'rejectRequest': "Reject request",
    'rejectionReason': "Rejection reason",
    'rejectionReasonRequired': "A rejection reason is required.",
    'assignRequest': "Assign request",
    'assignmentGroup': "Assignment group",
    'fulfilmentTasks': "Fulfilment tasks",
    'addFulfilmentTask': "Add fulfilment task",
    'markFulfilled': "Mark fulfilled",
    'confirmCompletion': "Confirm completion",
    'approvalHistory': "Approval history",
    'statusTimeline': "Status timeline",
    'linkedRecords': "Linked records",
    'relatedAsset': "Related asset",
    'relatedIncident': "Related incident",
    'relatedServiceRequest': "Related service request",
    'relatedChange': "Related change",
    'configurationItem': "Configuration item",
    'slaStatus': "SLA status",
    'slaOnTrack': "On track",
    'slaWarning': "At risk",
    'slaBreached': "Breached",
    'slaPaused': "Paused",
    'dueDate': "Due date",
    'knowledgeBaseTitle': "Knowledge Base",
    'knowledgeBaseDescription':
        "Find trusted guidance, solutions, and service information.",
    'knowledgeSearchHint': "Search the knowledge base",
    'featuredArticles': "Featured articles",
    'recentArticles': "Recent articles",
    'knowledgeArticleDetails': "Knowledge article",
    'noKnowledgeArticles': "No knowledge articles are available",
    'noKnowledgeArticlesDescription':
        "Published guidance will appear here when it becomes available.",
    'loadingKnowledge': "Loading knowledge...",
    'unableToLoadKnowledge': "Unable to load the knowledge base",
    'wasThisHelpful': "Was this article helpful?",
    'helpful': "Helpful",
    'notHelpful': "Not helpful",
    'thankYouForFeedback': "Thank you for your feedback.",
    'employeeVisible': "Visible to all employees",
    'dsiOnly': "DSI only",
    'articleAuthor': "Author",
    'articleReviewer': "Reviewer",
    'reviewDate': "Review date",
    'expiryDate': "Expiry date",
    'newKnowledgeArticle': "New article",
    'editKnowledgeArticle': "Edit article",
    'knowledgeReviewQueue': "Knowledge review queue",
    'manageKnowledge': "Manage knowledge",
    'knowledgeStateDraft': "Draft",
    'knowledgeStateReview': "In review",
    'knowledgeStatePublished': "Published",
    'knowledgeStateRetired': "Retired",
    'knowledgeStateArchived': "Archived",
    'publishArticle': "Publish article",
    'retireArticle': "Retire article",
    'archiveArticle': "Archive article",
    'articleVersion': "Article version",
    'articleContent': "Article content",
    'articleVisibility': "Article visibility",
    'articlePublished': "The article has been published.",
    'articleRetired': "The article has been retired.",
    'relatedServices': "Related services",
    'relatedCatalogueItems': "Related catalogue items",
    'relatedIncidentCategories': "Related incident categories",
    'suggestedKnowledge': "Suggested knowledge",
    'suggestedKnowledgeDescription':
        "These published articles may help resolve this request.",
    'viewArticle': "View article",
    'knowledgeAttachments': "Article attachments",
    'knowledgeAttachmentsHint':
        "Select files before saving. Uploaded files are registered against the immutable article version.",
    'internalAttachment': "Visible only to IT staff",
    'operationalActions': "Operational actions",
    'readOnlyAccess': "Read-only access",
    'readOnlyAccessDescription':
        "You can view this information but cannot change it.",
    'assetConfigurationOverview': "Assets & Configuration",
    'assetConfigurationOverviewDescription':
        "Track equipment, stock, licences, suppliers, warranties, and service dependencies.",
    'myAssets': "My Assets",
    'myAssetsDescription':
        "View equipment currently assigned to you and request help through the service catalogue.",
    'assetRegister': "Asset register",
    'assetRegisterDescription':
        "Manage the complete lifecycle and custody of organizational IT assets.",
    'noAssetsAssigned': "No assets are currently assigned to you.",
    'noAssetsFound': "No assets match the selected filters.",
    'unableToLoadAssets': "Unable to load assets",
    'searchAssets': "Search by asset tag, serial number, brand, or model",
    'assetTag': "Asset tag",
    'serialNumber': "Serial number",
    'brand': "Brand",
    'model': "Model",
    'condition': "Condition",
    'custodian': "Custodian",
    'acquisitionDate': "Acquisition date",
    'acquisitionCost': "Acquisition cost",
    'supplier': "Supplier",
    'warranty': "Warranty",
    'securityBaseline': "Security baseline",
    'lifecycleHistory': "Lifecycle history",
    'assetPhotographs': "Asset photographs",
    'reportAssetFault': "Report a fault",
    'requestAssetRepair': "Request repair",
    'requestAssetReplacement': "Request replacement",
    'requestAssetConfiguration': "Request configuration",
    'requestAssetReturn': "Request return",
    'assetActionCreatesRequest':
        "This action creates a governed service request and does not modify the asset directly.",
    'stockManagement': "Stock management",
    'stockManagementDescription':
        "Control quantities through traceable and atomic stock movements.",
    'stockLocations': "Stock locations",
    'stockItems': "Stock items",
    'stockMovements': "Stock movements",
    'quantityOnHand': "Quantity on hand",
    'quantityReserved': "Quantity reserved",
    'quantityAvailable': "Quantity available",
    'minimumStockThreshold': "Minimum stock threshold",
    'lowStock': "Low stock",
    'movementType': "Movement type",
    'movementReceipt': "Receipt",
    'movementReservation': "Reservation",
    'movementIssue': "Issue",
    'movementReturn': "Return",
    'movementTransfer': "Transfer",
    'movementAdjustment': "Adjustment",
    'movementReconciliation': "Reconciliation",
    'sourceLocation': "Source location",
    'destinationLocation': "Destination location",
    'recipient': "Recipient",
    'relatedRequest': "Related request",
    'supportingDocument': "Supporting document",
    'softwareLicences': "Software licences",
    'softwareLicencesDescription':
        "Manage allocations, compliance, contracts, and renewals without exposing licence secrets.",
    'softwareProduct': "Software product",
    'vendor': "Vendor",
    'licenceType': "Licence type",
    'purchasedQuantity': "Purchased quantity",
    'allocatedQuantity': "Allocated quantity",
    'availableQuantity': "Available quantity",
    'effectiveDate': "Effective date",
    'renewalDate': "Renewal date",
    'complianceStatus': "Compliance status",
    'licenceAssignments': "Licence assignments",
    'suppliersWarrantiesDescription':
        "Manage suppliers, contracts, warranty coverage, claims, and expiry dates.",
    'supplierRegister': "Supplier register",
    'contracts': "Contracts",
    'supportTerms': "Support terms",
    'contractStart': "Contract start",
    'contractEnd': "Contract end",
    'warrantyCoverage': "Warranty coverage",
    'warrantyExpiration': "Warranty expiration",
    'warrantyClaims': "Warranty claims",
    'configurationManagementDatabase': "Configuration management database",
    'cmdbDescription':
        "Map critical services, applications, infrastructure, devices, and their directional dependencies.",
    'configurationItems': "Configuration items",
    'ciType': "CI type",
    'ciOwner': "CI owner",
    'supportGroup': "Support group",
    'criticality': "Criticality",
    'operationalStatus': "Operational status",
    'configurationBaseline': "Configuration baseline",
    'dataQualityStatus': "Data quality status",
    'relationships': "Relationships",
    'impactView': "Impact view",
    'dependencyView': "Dependency view",
    'dependsOn': "Depends on",
    'runsOn': "Runs on",
    'connectedTo': "Connected to",
    'uses': "Uses",
    'representedBy': "Represented by",
    'managerOperationalAccessRequired':
        "A MANAGER role is required to access this operational capability.",
    'assetCommandCompleted': "The asset operation was completed.",
    'stockMovementCompleted': "The stock movement was recorded.",
    'licenceOperationCompleted': "The licence operation was completed.",
    'registerNewAsset': "Register a new asset",
    'registerNewLicence': "Register a new licence",
    'allocateLicence': "Allocate licence",
    'releaseLicence': "Release allocation",
    'saveSupplier': "Save supplier",
    'saveContract': "Save contract",
    'saveWarranty': "Save warranty",
    'recordWarrantyClaim': "Record warranty claim",
    'saveConfigurationItem': "Save configuration item",
    'createRelationship': "Create relationship",
    'retireRelationship': "Retire relationship",
    'configurationOperationCompleted':
        "The configuration operation was completed.",
    'recordIdentifier': "Record ID",
    'categoryId': "Category ID",
    'supplierId': "Supplier ID",
    'contractId': "Contract ID",
    'warrantyId': "Warranty ID",
    'claimId': "Claim ID",
    'allocationId': "Allocation ID",
    'assigneeId': "Assignee ID",
    'assigneeName': "Assignee name",
    'assignmentType': "Assignment type",
    'contactName': "Contact name",
    'legalName': "Legal name",
    'contractNumber': "Contract number",
    'warrantyNumber': "Warranty number",
    'relationshipType': "Relationship type",
    'sourceType': "Source type",
    'sourceId': "Source ID",
    'targetType': "Target type",
    'targetId': "Target ID",
    'linkedAssetId': "Linked asset ID",
    'ownerUserId': "Owner user ID",
    'ownerName': "Owner name",
    'address': "Address",
    'currency': "Currency",
    'invalidIdentifier':
        "Use letters, numbers, dots, dashes, underscores, or colons only.",
    'invalidDate': "Enter a valid date in YYYY-MM-DD format.",
    'positiveWholeNumberRequired': "Enter a positive whole number.",
    'isoDateHint': "YYYY-MM-DD",
    'assignmentUser': "User",
    'assignmentDevice': "Device",
    'ciService': "Service",
    'ciApplication': "Application",
    'ciServer': "Server",
    'ciDatabase': "Database",
    'ciNetwork': "Network",
    'ciDevice': "Device",
    'statusPlanned': "Planned",
    'statusDegraded': "Degraded",
    'statusMaintenance': "Maintenance",
    'statusRetired': "Retired",
    'dataQualityVerified': "Verified",
    'dataQualityNeedsReview': "Needs review",
    'dataQualityIncomplete': "Incomplete",
    'editAsset': "Edit asset",
    'assignAsset': "Assign asset",
    'returnAsset': "Return asset",
    'transitionAsset': "Change lifecycle state",
    'assignedUserId': "Assigned agent UID",
    'assignedAssetReturnHint':
        "Return is available only while the asset has a current assignment.",
    'transitionReason': "Transition reason",
    'lifecycleOperationCompleted': "The asset operation was completed.",
    'addStockLocation': "Add stock location",
    'editStockLocation': "Edit stock location",
    'addStockItem': "Add stock item",
    'editStockItem': "Edit stock item",
    'stockLocationId': "Stock location ID",
    'stockItemId': "Stock item ID",
    'sku': "SKU",
    'unitOfMeasure': "Unit of measure",
    'isConsumable': "Consumable item",
    'adjustmentDirection': "Adjustment direction",
    'increaseStock': "Increase stock",
    'decreaseStock': "Decrease stock",
    'reservedQuantityFulfilled': "Reserved quantity fulfilled",
    'targetOnHand': "Target quantity on hand",
    'targetReserved': "Target reserved quantity",
    'movementReason': "Movement reason",
    'movementRequirementsHint':
        "Required fields change with the selected movement type.",
    'sourceLocationRequired':
        "A source location is required for this movement.",
    'destinationLocationRequired':
        "A destination location is required for this movement.",
    'recipientRequired': "A recipient agent UID is required for this movement.",
    'evidenceRequired':
        "A supporting document ID is required for this movement.",
    'nonNegativeNumberRequired': "Enter zero or a positive number.",
    'reservedQuantityTooHigh':
        "Reserved fulfilment cannot exceed the issued quantity.",
    'editSupplier': "Edit supplier",
    'editContract': "Edit contract",
    'editWarranty': "Edit warranty",
    'manageWarranty': "Manage warranty",
    'transitionWarrantyClaim': "Update claim status",
    'claimStatus': "Claim status",
    'claimResolution': "Claim reason or resolution",
    'supplierContact': "Primary supplier contact",
    'editConfigurationItem': "Edit configuration item",
    'relatedIncidentIds': "Related incident IDs",
    'relatedRequestIds': "Related request IDs",
    'relatedChangeIds': "Related change IDs",
    'relatedFindingIds': "Related security finding IDs",
    'commaSeparatedIdsHint': "Comma-separated IDs",
    'allRelationships': "All relationships",
    'showDependencies': "Dependencies",
    'showImpact': "Impact",
    'recipientUserId': "Recipient agent UID",
    'claimSubmitted': "Submitted",
    'claimAcknowledged': "Acknowledged",
    'claimApproved': "Approved",
    'claimRejected': "Rejected",
    'claimResolved': "Resolved",
    'claimClosed': "Closed",
    'assetStatusOrdered': "Ordered",
    'assetStatusReceived': "Received",
    'assetStatusInStock': "In stock",
    'assetStatusConfigured': "Configured",
    'assetStatusAssigned': "Assigned",
    'assetStatusReturned': "Returned",
    'assetStatusDisposed': "Disposed",
    'assetStatusLost': "Lost",
    'assetStatusStolen': "Stolen",
    'uploadAssetAttachment': "Upload attachment",
    'uploadAssetPhotograph': "Upload photograph",
    'scanStockBarcode': "Scan barcode",
    'scanStockBarcodeHint': "Scan or enter the stock item barcode",
    'barcodeNotFound': "No stock item matches this barcode.",
    'attachmentRegistrationSuccessful':
        "The file was uploaded and securely registered.",
    'chooseSupportingDocument': "Choose supporting document",
    'changeManagementTitle': "Change Management",
    'changeManagementSubtitle':
        "Plan, assess, approve, schedule, and review controlled service changes.",
    'newChange': "New change",
    'myChanges': "My changes",
    'operationalChanges': "Operational changes",
    'changeEmptyTitle': "No change requests",
    'changeEmptyDescription':
        "Change requests matching this view will appear here.",
    'changeRequestDetails': "Change request details",
    'changeType': "Change type",
    'changeStandard': "Standard",
    'changeNormal': "Normal",
    'changeEmergency': "Emergency",
    'changeJustification': "Business justification",
    'saveChangeDraft': "Save draft",
    'submitChange': "Submit change",
    'assessChange': "Assess change",
    'requestChangeApproval': "Request approval",
    'scheduleChange': "Schedule change",
    'startImplementation': "Start implementation",
    'recordImplementation': "Record result",
    'recordPostImplementationReview': "Record review",
    'closeChange': "Close change",
    'cancelChange': "Cancel change",
    'changeOwner': "Change owner",
    'changeRequester': "Requester",
    'affectedServices': "Affected services",
    'affectedConfigurationItems': "Affected configuration items",
    'affectedAssets': "Affected assets",
    'plannedStart': "Planned start",
    'plannedEnd': "Planned end",
    'expectedDowntime': "Expected downtime (minutes)",
    'implementationPlan': "Implementation plan",
    'testPlan': "Test plan",
    'communicationPlan': "Communication plan",
    'rollbackPlan': "Rollback plan",
    'cabApprovalsTitle': "Approvals and CAB",
    'cabApprovalsSubtitle':
        "Review pending changes and keep immutable decision history.",
    'approveChange': "Approve",
    'approveWithConditions': "Approve with conditions",
    'rejectChange': "Reject",
    'requestClarification': "Request clarification",
    'decisionComment': "Decision comment",
    'approvalConditions': "Approval conditions",
    'changeCalendarTitle': "Change calendar",
    'changeCalendarSubtitle':
        "Review implementation windows, maintenance notices, and conflicts.",
    'calendarMonth': "Month",
    'calendarWeek': "Week",
    'calendarAgenda': "Agenda",
    'calendarPrevious': "Previous period",
    'calendarNext': "Next period",
    'changeConflict': "Conflict",
    'maintenancePublished': "Published maintenance",
    'changeReadOnly': "Read-only view",
    'changeCommandSuccessful': "The change was updated successfully.",
    'changeReasonRequired': "A reason is required.",
    'changeSelectStatus': "Filter by status",
    'changeActiveView': "Active",
    'changeHistoryView': "History",
    'changeStatusDraft': "Draft",
    'changeStatusSubmitted': "Submitted",
    'changeStatusAssessment': "Assessment",
    'changeStatusAwaitingApproval': "Awaiting approval",
    'changeStatusApproved': "Approved",
    'changeStatusScheduled': "Scheduled",
    'changeStatusImplementation': "Implementation",
    'changeStatusReview': "Review",
    'changeStatusClosed': "Closed",
    'changeStatusRejected': "Rejected",
    'changeStatusCancelled': "Cancelled",
    'changeStatusFailed': "Failed",
    'changeStatusRolledBack': "Rolled back",
    'changeComplexity': "Complexity",
    'maintenanceWindow': "Maintenance window",
    'changeRisk': "Risk",
    'changeRevision': "Revision",
    'changeRiskLow': "Low",
    'changeRiskMedium': "Medium",
    'changeRiskHigh': "High",
    'changeRiskCritical': "Critical",
    'changeServiceFilter': "Affected service ID",
    'changeCiFilter': "Configuration item ID",
    'changeRelatedRecords': "Related records",
    'changeImplementationResult': "Implementation result",
    'changePostImplementationReview': "Post-implementation review",
    'changeOutcomeSuccessful': "Successful",
    'changeOutcomePartial': "Partially successful",
    'changeOutcomeFailed': "Failed",
    'changeOutcomeRolledBack': "Rolled back",
    'cabMeeting': "CAB meeting",
    'cabMeetings': "CAB meetings",
    'scheduleCabMeeting': "Schedule CAB meeting",
    'cabApprovalGroup': "CAB approval group ID",
    'cabParticipantIds': "Participant manager UIDs",
    'cabMeetingNotes': "Meeting notes",
    'noCabMeetings': "No CAB meeting has been scheduled for this change.",
    'changeConflictsOnly': "Conflicts only",
    'changeComments': "Comments",
    'changeAttachments': "Attachments",
    'changeActivityTimeline': "Activity timeline",
    'noChangeComments': "No visible comments yet.",
    'noChangeAttachments': "No visible attachments yet.",
    'noChangeActivity': "No visible activity yet.",
    'unableToLoadChangeCollaboration': "Unable to load this information.",
    'requesterVisible': "Requester visible",
    'internalVisibility': "Internal",
    'changeCollaborationReadOnlyDescription':
        "Comments, attachments, and activity are shown according to your access. Workflow updates remain available only through the authorized actions above.",
    'itsmScSecurityComplianceTitle': "Security & Compliance",
    'itsmScSecurityComplianceSubtitle':
        "Manage security risk, exceptions, device posture and access reviews.",
    'itsmScSecurityFindingsTitle': "Security findings",
    'itsmScSecurityFindingsSubtitle':
        "Restricted operational findings and remediation progress.",
    'itsmScSecurityExceptionsTitle': "Security exceptions",
    'itsmScSecurityExceptionsSubtitle':
        "Request, review and monitor time-bound risk exceptions.",
    'itsmScAssetComplianceTitle': "Asset compliance",
    'itsmScAssetComplianceSubtitle':
        "Assess device controls or view your safe compliance status.",
    'itsmScAccessReviewsTitle': "Access reviews",
    'itsmScAccessReviewsSubtitle':
        "Review access or request a correction to your own access.",
    'itsmScLoading': "Loading security data…",
    'itsmScRetry': "Retry",
    'itsmScLoadMore': "Load more",
    'itsmScLoadingMore': "Loading more…",
    'itsmScNoData': "No records found",
    'itsmScNoDataDescription': "There is no data for the selected view.",
    'itsmScUnableToLoad': "Security data could not be loaded.",
    'itsmScAccessDenied': "Access denied",
    'itsmScManagerAccessRequired':
        "This operational view is available to ITSM MANAGER users only.",
    'itsmScSelfServiceAccessRequired':
        "This self-service view is not available for your role.",
    'itsmScAdminReadOnlyNotice':
        "ADMIN has no raw operational access. Only owned self-service records are shown.",
    'itsmScSelfServiceOnlyNotice':
        "Only your own self-service records are shown in this view.",
    'itsmScOperationalView': "Operational view",
    'itsmScMyRecords': "My records",
    'itsmScCampaigns': "Campaigns",
    'itsmScReviewItems': "Review items",
    'itsmScCorrectionRequests': "Correction requests",
    'itsmScAllStatuses': "All statuses",
    'itsmScStatus': "Status",
    'itsmScSeverity': "Severity",
    'itsmScRisk': "Risk",
    'itsmScOwner': "Owner",
    'itsmScDueDate': "Due date",
    'itsmScUpdated': "Updated",
    'itsmScReference': "Reference",
    'itsmScSystem': "System",
    'itsmScDepartment': "Department",
    'itsmScCurrentAccess': "Current access",
    'itsmScCurrentRole': "Current role",
    'itsmScDevice': "Device",
    'itsmScAssessedAt': "Assessed",
    'itsmScReviewDate': "Review date",
    'itsmScPeriod': "Period",
    'itsmScEvidence': "Accessible evidence",
    'itsmScRestrictedEvidenceHidden':
        "Restricted evidence is hidden unless you are explicitly authorized.",
    'itsmScNewFinding': "New finding",
    'itsmScSubmitException': "Submit exception",
    'itsmScRecordAssessment': "Record assessment",
    'itsmScNewCampaign': "New campaign",
    'itsmScRequestCorrection': "Request correction",
    'itsmScRequestRevocation': "Request revocation",
    'itsmScDecide': "Record decision",
    'itsmScApprove': "Approve",
    'itsmScReject': "Reject",
    'itsmScRetain': "Retain",
    'itsmScRevoke': "Revoke",
    'itsmScModify': "Modify",
    'itsmScTransition': "Change status",
    'itsmScCancel': "Cancel",
    'itsmScSubmit': "Submit",
    'itsmScSave': "Save",
    'itsmScTitle': "Title",
    'itsmScDescription': "Description",
    'itsmScSource': "Source",
    'itsmScRequirementOrControl': "Requirement or control",
    'itsmScBusinessJustification': "Business justification",
    'itsmScScope': "Scope",
    'itsmScRiskDescription': "Risk description",
    'itsmScCompensatingControl': "Compensating control",
    'itsmScReason': "Reason",
    'itsmScComment': "Comment",
    'itsmScAssetId': "Asset ID",
    'itsmScAssetTag': "Asset tag",
    'itsmScAssetName': "Asset name",
    'itsmScSummary': "Summary",
    'itsmScCampaignTitle': "Campaign title",
    'itsmScSystemId': "System ID",
    'itsmScSystemName': "System name",
    'itsmScCommandCompleted': "The security operation was accepted.",
    'itsmScCommandFailed': "The security operation could not be completed.",
    'itsmScRequiredField': "This field is required.",
    'itsmScCorrectionSubmitted':
        "Your access correction request was submitted.",
    'itsmScOwnComplianceUnavailable':
        "Own-device compliance is available to USER self-service only.",
    'itsmScFindingsCount': "Findings",
    'itsmScExceptionsCount': "Exceptions",
    'itsmScAssessmentsCount': "Assessments",
    'itsmScReviewsCount': "Reviews",
    'itsmScComplianceCompliant': "Compliant",
    'itsmScComplianceActionRequired': "Action required",
    'itsmScComplianceAssessmentPending': "Assessment pending",
    'itsmScSeverityLow': "Low",
    'itsmScSeverityMedium': "Medium",
    'itsmScSeverityHigh': "High",
    'itsmScSeverityCritical': "Critical",
    'itsmScNotAssigned': "Not assigned",
    'itsmScOwnerUserId': "Owner user ID",
    'itsmScRemediationPlan': "Remediation plan",
    'itsmScValidationResult': "Validation result",
    'itsmScActionTriageFinding': "Triage finding",
    'itsmScActionAssignFinding': "Assign finding",
    'itsmScActionPlanRemediation': "Plan remediation",
    'itsmScActionSubmitValidation': "Submit for validation",
    'itsmScActionValidateFinding': "Record validation",
    'itsmScActionAcceptRisk': "Accept risk",
    'itsmScActionCloseFinding': "Close finding",
    'itsmScActionCancelFinding': "Cancel finding",
    'itsmScActionSubmitException': "Submit exception",
    'itsmScActionRequestExceptionApproval': "Request approval",
    'itsmScActionDecideExceptionApproval': "Decide approval",
    'itsmScActionActivateException': "Activate exception",
    'itsmScActionRenewException': "Renew exception",
    'itsmScActionCloseException': "Close exception",
    'itsmScApproverUserId': "Approver user ID",
    'itsmScApprovalId': "Approval ID",
    'itsmScDecision': "Decision",
    'itsmScFindingStatusDetected': "Detected",
    'itsmScFindingStatusTriaged': "Triaged",
    'itsmScFindingStatusAssigned': "Assigned",
    'itsmScFindingStatusRemediation': "Remediation",
    'itsmScFindingStatusValidation': "Validation",
    'itsmScFindingStatusClosed': "Closed",
    'itsmScFindingStatusRiskAccepted': "Risk accepted",
    'itsmScFindingStatusCancelled': "Cancelled",
    'itsmScExceptionStatusDraft': "Draft",
    'itsmScExceptionStatusSubmitted': "Submitted",
    'itsmScExceptionStatusUnderReview': "Under review",
    'itsmScExceptionStatusAwaitingApproval': "Awaiting approval",
    'itsmScExceptionStatusApproved': "Approved",
    'itsmScExceptionStatusRejected': "Rejected",
    'itsmScExceptionStatusActive': "Active",
    'itsmScExceptionStatusExpired': "Expired",
    'itsmScExceptionStatusClosed': "Closed",
    'itsmScExceptionStatusCancelled': "Cancelled",
    'itsmScCampaignStatusDraft': "Draft",
    'itsmScCampaignStatusActive': "Active",
    'itsmScCampaignStatusCompleted': "Completed",
    'itsmScCampaignStatusCancelled': "Cancelled",
    'itsmScReviewStatusPending': "Pending",
    'itsmScReviewStatusDecided': "Decided",
    'itsmScReviewStatusRevocationPending': "Revocation pending",
    'itsmScReviewStatusCompleted': "Completed",
    'itsmScCorrectionStatusSubmitted': "Submitted",
    'itsmScCorrectionStatusInReview': "In review",
    'itsmScCorrectionStatusCompleted': "Completed",
    'itsmScCorrectionStatusRejected': "Rejected",
    'itsmScCorrectionStatusCancelled': "Cancelled",
    'itsmScValidationPassed': "Passed",
    'itsmScValidationFailed': "Failed",
    'itsmScValidationPartial': "Partially validated",
    'itsmScRemediationSummary': "Assessment and remediation summary",
    'itsmScControlOperatingSystem': "Operating system support",
    'itsmScControlPatchStatus': "Patch status",
    'itsmScControlAntivirus': "Antivirus / EDR",
    'itsmScControlEncryption': "Disk encryption",
    'itsmScControlBackup': "Backup",
    'itsmScControlApprovedSoftware': "Approved software",
    'itsmScControlSecurityBaseline': "Security baseline",
    'itsmScNotApplicable': "Not applicable",
    'itsmScUnknown': "Unknown",
    'itsmScCompleteRevocationTask': "Complete revocation task",
    'itsmScActivateCampaign': "Activate campaign",
    'itsmScCreateReviewItem': "Create review item",
    'itsmScCompleteCampaign': "Complete campaign",
    'itsmScSubjectUserId': "Subject user ID",
    'itsmScDepartmentId': "Department ID",
    'itsmScReviewerUserId': "Reviewer user ID",
    'itsmScAssignedToUserId': "Assigned manager ID",
    'itsmScTargetAccess': "Target access",
    'itsmScTaskId': "Revocation task ID",
    'itsmScCompletionEvidenceId': "Completion evidence ID",
  },
  'fr': <String, String>{
    'appName': "ARPTC Connect",
    'appTitle': "ARPTC",
    'appShortName': "ARPTC",
    'notAvailable': "N/D",
    'dash': "-",
    'yes': "Oui",
    'no': "Non",
    'ok': "OK",
    'cancel': "Annuler",
    'confirm': "Confirmer",
    'confirmation': "Confirmation",
    'save': "Enregistrer",
    'saving': "Enregistrement...",
    'delete': "Supprimer",
    'edit': "Modifier",
    'add': "Ajouter",
    'create': "Créer",
    'update': "Mettre à jour",
    'submit': "Soumettre",
    'close': "Fermer",
    'archive': "Archiver",
    'refresh': "Actualiser",
    'retry': "Réessayer",
    'search': "Rechercher",
    'filter': "Filtrer",
    'clear': "Effacer",
    'select': "Sélectionner",
    'viewAll': "Tout afficher",
    'back': "Retour",
    'next': "Suivant",
    'previous': "Précédent",
    'loading': "Chargement...",
    'error': "Erreur",
    'somethingWentWrong': "Une erreur est survenue",
    'unableToLoad': "Impossible de charger",
    'noDataAvailable': "Aucune donnée disponible",
    'noDataDescription': "Aucune donnée n'existe encore.",
    'active': "Actif",
    'inactive': "Inactif",
    'enabled': "Activé",
    'disabled': "Désactivé",
    'approved': "Approuvé",
    'pending': "En attente",
    'rejected': "Rejeté",
    'archived': "Archivé",
    'all': "Tout",
    'allStatuses': "Tous les statuts",
    'status': "Statut",
    'type': "Type",
    'date': "Date",
    'createdAt': "Créé le",
    'updatedAt': "Mis à jour le",
    'createdBy': "Créé par",
    'assignedTo': "Assigné à",
    'unassigned': "Non assigné",
    'description': "Description",
    'title': "Titre",
    'name': "Nom",
    'firstName': "Prénom",
    'lastName': "Nom de famille",
    'postName': "Post-nom",
    'fullName': "Nom complet",
    'email': "E-mail",
    'noEmail': "Aucun e-mail",
    'phone': "Téléphone",
    'matricule': "Matricule",
    'position': "Fonction",
    'category': "Catégorie",
    'subcategory': "Sous-catégorie",
    'department': "Département",
    'departments': "Départements",
    'service': "Service",
    'services': "Services",
    'bureau': "Bureau",
    'bureaux': "Bureaux",
    'agent': "Agent",
    'agents': "Agents",
    'user': "Utilisateur",
    'users': "Utilisateurs",
    'module': "Module",
    'modules': "Modules",
    'role': "Rôle",
    'roles': "Rôles",
    'permissions': "Permissions",
    'modulePermissions': "Permissions des modules",
    'profilePicture': "Photo de profil",
    'language': "Langue",
    'english': "Anglais",
    'french': "Français",
    'system': "Système",
    'light': "Clair",
    'dark': "Sombre",
    'navigationHome': "Accueil",
    'navigationServices': "Services",
    'navigationCourrier': "Courrier",
    'navigationCourriers': "Courriers",
    'navigationDashboard': "Tableau de bord",
    'navigationProfile': "Profil",
    'navigationAccount': "Compte",
    'navigationAdministration': "Administration",
    'signIn': "Se connecter",
    'signOut': "Se déconnecter",
    'signingIn': "Connexion...",
    'emailOrPasswordIncorrect': "L'e-mail ou le mot de passe est incorrect",
    'errorOccurred': "Une erreur est survenue",
    'emailAlreadyInUse': "Cet e-mail est déjà utilisé.",
    'resetPassword': "Réinitialiser le mot de passe",
    'password': "Mot de passe",
    'homeNewsTitle': "Actualités",
    'homeNewsDescription':
        "Publications des communicateurs autorisés de l'entreprise.",
    'companyNews': "Actualités de l'entreprise",
    'noCompanyNewsYet': "Aucune actualité de l'entreprise pour le moment",
    'publishedInformationWillAppearHere':
        "Les informations publiées apparaîtront ici.",
    'loadingCompanyNews': "Chargement des actualités de l'entreprise...",
    'unableToLoadCompanyNews':
        "Impossible de charger les actualités de l'entreprise",
    'news': "Actualités",
    'newPost': "Nouvelle publication",
    'postDetails': "Détails de la publication",
    'newsEditor': "Éditeur d'actualités",
    'newsReview': "Revue des actualités",
    'reviewPost': "Examiner la publication",
    'publishPost': "Publier la publication",
    'archivePost': "Archiver la publication",
    'submitForReview': "Soumettre pour validation",
    'acceptPost': "Accepter la publication",
    'rejectPost': "Rejeter la publication",
    'rejectionComment': "Commentaire de rejet",
    'draft': "Brouillon",
    'accepted': "Accepté",
    'published': "Publié",
    'serviceWelcome': "Bienvenue",
    'loadingModules': "Chargement des modules...",
    'noAuthorizedModule': "Aucun module autorisé",
    'noAuthorizedModuleDescription':
        "Aucun module n'est autorisé pour cet utilisateur. Veuillez contacter l'administrateur.",
    'moduleTasksName': "Tâches",
    'moduleTasksDescription': "Rapport des tâches et activités",
    'moduleInventoryName': "Inventaire",
    'moduleInventoryDescription':
        "Gérer les stocks et les articles de l'organisation",
    'moduleIncidentName': "Support",
    'moduleIncidentDescription': "Gestion des incidents IT et du support",
    'moduleItsmName': "Gestion des services informatiques",
    'moduleItsmDescription':
        "Services IT, support, actifs et gouvernance intégrés",
    'itsmLandingTitle': "Gestion des services informatiques",
    'itsmLandingDescription':
        "Accédez au support, aux actifs, aux changements, à la sécurité et à la gouvernance des services IT depuis un seul espace.",
    'itsmSupport': "Support",
    'itsmSupportDescription':
        "Signalez des incidents, demandez des services IT, suivez vos demandes et trouvez des conseils.",
    'itsmAssetsConfiguration': "Actifs et configuration",
    'itsmAssetsConfigurationDescription':
        "Gérez les actifs IT, le stock, les licences, les fournisseurs, les garanties et les éléments de configuration.",
    'itsmChanges': "Changements",
    'itsmChangesDescription':
        "Planifiez, approuvez, programmez et évaluez les changements contrôlés des services IT.",
    'itsmSecurityCompliance': "Sécurité et conformité",
    'itsmSecurityComplianceDescription':
        "Suivez les constats de sécurité, les exceptions, la conformité des actifs et les revues d'accès.",
    'itsmReportingAdministration': "Rapports et administration",
    'itsmReportingAdministrationDescription':
        "Surveillez la performance des services et gérez les politiques, les workflows et les audits ITSM.",
    'itsmIncidents': "Incidents",
    'itsmServiceRequests': "Demandes de service",
    'itsmMyRequests': "Mes demandes",
    'itsmSearchWorkItems': "Rechercher par référence, titre ou description",
    'itsmWorkItemType': "Type de demande",
    'itsmFilterByDate': "Filtrer par date de création",
    'itsmLoadMore': "Charger plus",
    'itsmAddComment': "Ajouter un commentaire",
    'itsmLinkedRecords': "Éléments liés",
    'itsmLinkRecord': "Lier un élément",
    'itsmUpdateTask': "Mettre à jour la tâche",
    'itsmStartFulfilment': "Démarrer le traitement",
    'itsmMarkFulfilled': "Marquer comme exécutée",
    'itsmConfirmCompletion': "Confirmer l'exécution",
    'itsmCancelRequest': "Annuler la demande",
    'itsmRejectRequest': "Rejeter la demande",
    'itsmConfirmStatusChange':
        "Voulez-vous appliquer ce changement de statut ?",
    'itsmActionCompleted': "Action terminée.",
    'itsmAssignRequest': "Assigner la demande",
    'actions': "Actions",
    'assign': "Assigner",
    'reason': "Motif",
    'visibility': "Visibilité",
    'id': "ID",
    'reference': "Référence",
    'itsmKnowledgeBase': "Base de connaissances",
    'itsmAssets': "Actifs",
    'itsmStock': "Stock",
    'itsmLicences': "Licences",
    'itsmSuppliersWarranties': "Fournisseurs et garanties",
    'itsmCmdb': "CMDB",
    'itsmChangeRequests': "Demandes de changement",
    'itsmApprovalsCab': "Approbations / CAB",
    'itsmChangeCalendar': "Calendrier des changements",
    'itsmSecurityFindings': "Constats de sécurité",
    'itsmSecurityExceptions': "Exceptions de sécurité",
    'itsmAssetCompliance': "Conformité des actifs",
    'itsmAccessReviews': "Revues des accès",
    'itsmDashboards': "Tableaux de bord",
    'itsmSla': "SLA",
    'itsmServiceCatalogue': "Catalogue de services",
    'itsmWorkflowConfiguration': "Configuration des workflows",
    'itsmAuditLogs': "Journaux d'audit",
    'itsmFeatureCardDescription': "Ouvrir cette fonctionnalité ITSM.",
    'itsmFeatureUnavailableDescription':
        "Cette fonctionnalité fait partie du déploiement progressif de l'ITSM et n'est pas disponible dans cette phase. Aucune donnée protégée n'a été chargée.",
    'itsmAccessDeniedTitle': "Accès ITSM restreint",
    'itsmAccessDeniedDescription':
        "Votre rôle ITSM actuel ne permet pas d'accéder à cet espace.",
    'itsmLoadingAccess': "Chargement des accès ITSM...",
    'itsmUnableToLoadAccess': "Impossible de charger les accès ITSM",
    'moduleUserManagementName': "Gestion des utilisateurs",
    'moduleUserManagementDescription':
        "Gérer les départements, services, bureaux, agents et modules",
    'moduleNewsName': "Actualités",
    'moduleNewsDescription': "Communication et publication internes",
    'moduleCourrierName': "Courrier",
    'moduleCourrierDescription': "Courrier officiel et circuit de transmission",
    'profile': "Profil",
    'profileUnavailable': "Profil indisponible",
    'profileUnavailableDescription':
        "Aucune donnée d'agent n'est mise en cache sur cet appareil pour la session actuelle.",
    'connectedAgentInformation': "Informations de l'agent connecté",
    'agentInformation': "Informations de l'agent",
    'noFields': "Aucun champ",
    'noProfileFieldsAvailable': "Aucun champ de profil disponible.",
    'refreshProfile': "Actualiser le profil",
    'loadingProfile': "Chargement du profil...",
    'unableToLoadProfile': "Impossible de charger le profil",
    'enableNotifications': "Activer les notifications",
    'notificationsEnabled': "Les notifications sont activées.",
    'notificationPermissionNotGranted':
        "L'autorisation de notification n'a pas encore été accordée.",
    'unableToEnableNotifications': "Impossible d'activer les notifications",
    'webPushNotConfigured': "Web push n'est pas configuré",
    'webPushNotConfiguredDescription':
        "Web push n'est pas configuré pour cette version. Reconstruisez l'application avec la clé VAPID Firebase Web Push.",
    'webPushNotConfiguredAction':
        "Lancez ou construisez l'application web avec --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=VOTRE_CLE_PUBLIQUE, puis réessayez.",
    'disableNotifications': "Désactiver les notifications",
    'notificationsBlocked': "Les notifications sont bloquées",
    'notificationsEnabledForPlatform':
        "Les notifications sont activées pour ce {platform}.",
    'notificationsProvisionallyEnabled':
        "Les notifications sont activées provisoirement.",
    'notificationsBlockedForPlatform':
        "Les notifications sont bloquées pour ce {platform}.",
    'allowNotificationsPrompt':
        "Cochez cette case pour autoriser ARPTC Connect à envoyer des notifications.",
    'disableNotificationsWindows':
        "Les autorisations de notification sont contrôlées par Windows et votre navigateur.\n\nPour les désactiver, ouvrez les paramètres du site dans le navigateur pour cette application et bloquez les notifications. Vous pouvez aussi ouvrir Paramètres Windows > Système > Notifications, puis désactiver les notifications pour l'application ARPTC Connect installée, Chrome ou Edge.",
    'disableNotificationsMac':
        "Les autorisations de notification sont contrôlées par macOS et votre navigateur.\n\nPour les désactiver, ouvrez Réglages Système > Notifications, puis désactivez les notifications pour ARPTC Connect ou Safari. Vous pouvez aussi utiliser Safari > Réglages > Sites web > Notifications pour bloquer le domaine de cette application.",
    'disableNotificationsWeb':
        "Les autorisations de notification sont contrôlées par votre navigateur. Utilisez les paramètres du site dans votre navigateur pour bloquer les notifications de cette application.",
    'disableNotificationsDevice':
        "Les autorisations de notification sont contrôlées par cet appareil. Utilisez les paramètres système de notification pour désactiver les notifications d'ARPTC Connect.",
    'blockedNotificationsWindows':
        "Windows ou votre navigateur a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nSous Windows, ouvrez Paramètres > Système > Notifications et assurez-vous que les notifications sont activées pour l'application ARPTC Connect installée, Google Chrome ou Microsoft Edge.\n\nOuvrez ensuite les paramètres du site de ce domaine dans votre navigateur et définissez Notifications sur Autoriser. Dans Chrome ou Edge, cela se trouve généralement dans Paramètres > Confidentialité et sécurité > Paramètres des sites > Notifications. Ensuite, rouvrez l'application installée et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsMac':
        "Safari ou macOS a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nSous macOS, ouvrez Réglages Système > Notifications, puis sélectionnez ARPTC Connect ou Safari et autorisez les notifications.\n\nSi elles restent bloquées, ouvrez Safari > Réglages > Sites web > Notifications, trouvez le domaine de cette application, puis passez-le sur Autoriser ou supprimez la décision enregistrée. Ensuite, rouvrez l'application installée et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsWeb':
        "Votre navigateur a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nOuvrez les paramètres du site pour ce domaine, définissez Notifications sur Autoriser, puis rouvrez l'application et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsDevice':
        "Cet appareil a bloqué les notifications pour ARPTC Connect.\n\nOuvrez les paramètres système de notification, autorisez les notifications pour ARPTC Connect, puis revenez sur cette page de profil et activez-les de nouveau.",
    'notifications': "Notifications",
    'noNotificationsYet': "Aucune notification pour le moment",
    'noNotificationsDescription':
        "Les notifications concernant les incidents, les actualités et les workflows apparaîtront ici.",
    'loadingNotifications': "Chargement des notifications...",
    'unableToLoadNotifications': "Impossible de charger les notifications",
    'clearAllNotifications': "Effacer toutes les notifications",
    'notificationsCleared': "Notifications effacées.",
    'unableToClearNotifications': "Impossible d'effacer les notifications",
    'everyone': "Tout le monde",
    'forYou': "Pour vous",
    'erp': "ERP",
    'incidentManagement': "Gestion des incidents",
    'incidentSupport': "Support",
    'incidentOperations': "Opérations incidents",
    'incidentOperationsDescription':
        "Vue opérationnelle en temps réel pour le triage et la résolution IT.",
    'incidentSupervision': "Supervision des incidents",
    'incidentSupervisionDescription':
        "Visibilité globale en lecture seule sur les incidents actifs, fermés et archivés.",
    'newIncident': "Nouvel incident",
    'newSupportIncident': "Nouvel incident support",
    'submitSupportTicket': "Soumettre un ticket support",
    'submitTicket': "Soumettre le ticket",
    'submitting': "Soumission...",
    'createIncidentManagerDescription':
        "Créer et catégoriser un incident en une seule étape.",
    'createIncidentUserDescription':
        "Indiquez à l'IT ce qui est bloqué. L'équipe support catégorisera le reste.",
    'readOnlyIncidentAccess': "Accès incident en lecture seule",
    'onlyUsersAndManagersCreateIncidents':
        "Seuls les utilisateurs et les managers peuvent créer des tickets d'incident.",
    'titleExampleEmailAccess': "Exemple : Impossible d'accéder à l'e-mail",
    'shortDescription': "Brève description",
    'describeIssue': "Décrivez le problème",
    'describeIssueAndWork':
        "Décrivez ce qui s'est passé et ce que vous essayiez de faire",
    'affectedItService': "Service IT affecté",
    'selectAffectedService':
        "Sélectionnez le service que vous ne parvenez pas à joindre",
    'thisIssueBlocksMyWork': "Ce problème bloque mon travail",
    'blockingWorkDescription':
        "Activez cette option si vous ne pouvez pas poursuivre votre travail normal.",
    'managerCategorization': "Catégorisation manager",
    'managerCategorizationDescription':
        "Les managers effectuent ensemble les deux premières étapes du workflow : soumission et catégorisation.",
    'affectedAgent': "Agent concerné",
    'searchAffectedAgentHint':
        "Laissez vide pour créer le ticket pour vous-même",
    'searchByNameEmailMatricule': "Rechercher par nom, e-mail ou matricule",
    'location': "Emplacement",
    'locationHint': "Bureau, étage, salle",
    'deviceType': "Type d'appareil",
    'deviceTypeHint': "Ordinateur portable, imprimante, téléphone",
    'assetId': "ID de l'actif",
    'assetIdHint': "Identifiant d'actif facultatif",
    'impact': "Impact",
    'urgency': "Urgence",
    'impactDescription': "Description de l'impact",
    'impactDescriptionHint': "Note facultative sur l'impact sur le travail",
    'selectCategory': "Sélectionnez une catégorie",
    'selectImpact': "Sélectionnez l'impact",
    'selectUrgency': "Sélectionnez l'urgence",
    'completeCategoryImpactUrgency':
        "Complétez la catégorie, l'impact et l'urgence avant de soumettre.",
    'openTickets': "Tickets ouverts",
    'openTicketsSubtitle': "Soumis, non catégorisés",
    'unassignedTickets': "Tickets non assignés",
    'unassignedTicketsSubtitle': "Catégorisés, non assignés",
    'assignedToMe': "Assignés à moi",
    'solvedTickets': "Tickets résolus",
    'solvedTicketsSubtitle': "Résolus, non fermés",
    'criticalTickets': "Tickets critiques",
    'criticalTicketsSubtitle': "Tickets actifs P1 et P2",
    'closedThisWeek': "Fermés cette semaine",
    'parameters': "Paramètres",
    'operationalQueue': "File opérationnelle",
    'operationalQueueDescription':
        "Incidents actifs triés d'abord par priorité, puis du plus ancien au plus récent.",
    'noActiveIncident': "Aucun incident actif",
    'newOperationalTicketsWillAppearHere':
        "Les nouveaux tickets opérationnels apparaîtront ici.",
    'myAssignedTickets': "Mes tickets assignés",
    'myAssignedTicketsDescription':
        "Incidents actifs actuellement assignés à vous.",
    'ticketsByPriority': "Tickets par priorité",
    'ticketsByStatus': "Tickets par statut",
    'ticketsByAffectedService': "Tickets par service affecté",
    'agingTickets': "Vieillissement des tickets",
    'ticket': "Ticket",
    'priority': "Priorité",
    'age': "Âge",
    'createdAtColumn': "Créé le",
    'openTicketsQueueDescription':
        "Tickets soumis par les utilisateurs et non encore catégorisés.",
    'unassignedTicketsQueueDescription':
        "Tickets catégorisés en attente d'assignation à un membre IT.",
    'assignedToMeQueueDescription':
        "Tickets actifs assignés au manager actuel.",
    'solvedTicketsQueueDescription': "Tickets résolus en attente de clôture.",
    'closedTicketHistory': "Historique des tickets fermés",
    'closedTicketHistoryDescription':
        "Consultez les incidents traités et fermés par le support IT.",
    'noClosedTicketsHistory': "Aucun ticket fermé",
    'noClosedTicketsHistoryDescription':
        "Les incidents fermés apparaîtront ici.",
    'noTicketsFound': "Aucun ticket trouvé",
    'queueEmpty': "Cette file est vide.",
    'tryAnotherSearchOrStatus':
        "Essayez une autre recherche ou un autre filtre de statut.",
    'thereIsNoQueueItem': "Il n'y a aucun {queueLabel}.",
    'searchIncidents': "Rechercher des incidents",
    'ticketDetails': "Détails de l'incident",
    'incidentNotFound': "Incident introuvable",
    'loadingIncident': "Chargement de l'incident...",
    'unableToLoadIncident': "Impossible de charger l'incident",
    'timeline': "Chronologie",
    'requester': "Demandeur",
    'affectedService': "Service affecté",
    'blocking': "Bloquant",
    'resolutionSummary': "Résumé de résolution",
    'resolutionSummaryHint': "Expliquez ce qui a résolu l'incident",
    'resolutionCode': "Code de résolution",
    'resolutionCodeHint': "Sélectionnez comment l'incident a été résolu",
    'resolutionCodes': "Codes de résolution",
    'selectResolutionCode': "Sélectionnez un code de résolution",
    'selectResolutionCodeBeforeSolved':
        "Sélectionnez un code de résolution avant de marquer le ticket comme résolu.",
    'selectResolutionCodeBeforeClosing':
        "Sélectionnez un code de résolution avant de fermer le ticket.",
    'closedAt': "Fermé le",
    'archiveEligible': "Archivable le",
    'internalNotes': "Notes internes",
    'addNote': "Ajouter une note",
    'addInternalNoteHint': "Seul le personnel IT peut voir les notes internes",
    'adding': "Ajout...",
    'internalNoteAdded': "Note interne ajoutée.",
    'workflowStepSubmitTicket': "Étape 1 : Soumettre le ticket",
    'workflowStepSubmitTicketDescription':
        "Le demandeur fournit les informations de base.",
    'workflowStepCategorizeTicket': "Étape 2 : Catégoriser le ticket",
    'workflowStepCategorizeOpenDescription':
        "Complétez le triage et passez ce ticket en cours de traitement.",
    'workflowStepCategorizeActiveDescription':
        "La catégorisation opérationnelle peut encore être mise à jour tant que le ticket est actif.",
    'workflowStepAssignTicket': "Étape 3 : Assigner le ticket",
    'workflowStepAssignTicketDescription':
        "Assignez l'incident au personnel IT. Le statut du ticket ne change pas ici.",
    'workflowStepSolveTicket': "Étape 4 : Résoudre le ticket",
    'workflowStepSolveTicketDescription':
        "Enregistrez le résumé de résolution avant la clôture.",
    'workflowStepCloseTicket': "Étape 5 : Fermer le ticket",
    'workflowStepCloseTicketDescription':
        "Fermez le ticket une fois la solution validée.",
    'categorizeTicket': "Catégoriser le ticket",
    'categorizing': "Catégorisation...",
    'ticketCategorized': "Ticket catégorisé.",
    'assignTicket': "Assigner le ticket",
    'assigning': "Assignation...",
    'ticketAssigned': "Ticket assigné.",
    'markTicketSolved': "Marquer le ticket comme résolu",
    'markingSolved': "Marquage comme résolu...",
    'ticketMarkedSolved': "Ticket marqué comme résolu.",
    'markTicketClosed': "Marquer le ticket comme fermé",
    'closing': "Clôture...",
    'ticketClosed': "Ticket fermé.",
    'cancelTicket': "Annuler le ticket",
    'cancelThisTicket': "Annuler ce ticket ?",
    'cancelTicketWarning':
        "Cette action ne doit être utilisée que si l'incident est une fausse alerte. Le ticket quittera la file opérationnelle.",
    'keepTicket': "Conserver le ticket",
    'cancelling': "Annulation...",
    'ticketCancelled': "Ticket annulé.",
    'selectServiceCategoryImpactUrgency':
        "Sélectionnez d'abord le service affecté, la catégorie, l'impact et l'urgence.",
    'selectItStaffAssignee':
        "Sélectionnez le membre IT qui résoudra l'incident.",
    'enterResolutionSummaryBeforeSolved':
        "Saisissez un résumé de résolution avant de marquer comme résolu.",
    'enterResolutionSummaryBeforeClosing':
        "Saisissez un résumé de résolution avant de fermer.",
    'myIncidents': "Mes incidents",
    'createAndFollowIncidents': "Créez et suivez vos incidents IT",
    'activeIncidents': "Actifs",
    'closedAndArchived': "Fermés et archivés",
    'noActiveIncidentUserDescription':
        "Vos incidents ouverts apparaîtront ici.",
    'noClosedIncident': "Aucun incident fermé",
    'closedAndArchivedDescription':
        "Les incidents fermés et archivés apparaîtront ici.",
    'loadingIncidents': "Chargement des incidents...",
    'unableToLoadIncidents': "Impossible de charger les incidents",
    'incidentAccessUnavailable': "Accès aux incidents indisponible",
    'incidentAccessUnavailableDescription':
        "Aucune permission de Gestion des incidents n'est attribuée à cet agent.",
    'noIncidentDashboardAccess':
        "Vous n'avez pas accès au tableau de bord de Gestion des incidents.",
    'loadingIncidentAccess': "Chargement des accès aux incidents...",
    'loadingIncidentDashboardAccess':
        "Chargement des accès au tableau de bord des incidents...",
    'unableToLoadIncidentAccess':
        "Impossible de charger les accès aux incidents",
    'unableToLoadIncidentDashboardAccess':
        "Impossible de charger les accès au tableau de bord des incidents",
    'incidentParameters': "Paramètres des incidents",
    'incidentParametersDescription':
        "Configurez les services IT, les catégories et les codes de résolution utilisés par les tickets support.",
    'addItService': "Ajouter un service IT",
    'addCategory': "Ajouter une catégorie",
    'addResolutionCode': "Ajouter un code de résolution",
    'editResolutionCode': "Modifier le code de résolution",
    'noResolutionCodes': "Aucun code de résolution disponible",
    'resolutionCodeIdentifier': "Identifiant du code",
    'resolutionCodeIdentifierHint': "Exemple : FIXED ou WORKAROUND_PROVIDED",
    'resolutionCodeLabelEnglish': "Libellé anglais",
    'resolutionCodeLabelFrench': "Libellé français",
    'totalIncidentsThisMonth': "Total des incidents ce mois-ci",
    'averageResolutionTime': "Temps moyen de résolution",
    'monthlyIncidentTrend': "Tendance mensuelle des incidents",
    'ticketsByService': "Tickets par service",
    'ticketsByCategory': "Tickets par catégorie",
    'ticketsByDepartment': "Tickets par département",
    'recentCriticalTickets': "Tickets critiques récents",
    'recentCriticalTicketsDescription':
        "Derniers incidents P1 et P2. Cette liste est en lecture seule pour les admins.",
    'criticalTicketsWillAppearHere': "Les incidents P1 et P2 apparaîtront ici.",
    'adminReadOnly': "Lecture seule",
    'incidentStatusOpen': "Ouvert",
    'incidentStatusCategorized': "Catégorisé",
    'incidentStatusAssigned': "Assigné",
    'incidentStatusInProgress': "En cours",
    'incidentStatusResolved': "Résolu",
    'incidentStatusClosed': "Fermé",
    'incidentStatusArchived': "Archivé",
    'incidentStatusCancelled': "Annulé",
    'incidentLifecycleActive': "Actif",
    'incidentLifecycleClosed': "Fermé",
    'incidentLifecycleArchived': "Archivé",
    'incidentImpactLow': "Faible",
    'incidentImpactMedium': "Moyen",
    'incidentImpactHigh': "Élevé",
    'incidentUrgencyLow': "Faible",
    'incidentUrgencyMedium': "Moyenne",
    'incidentUrgencyHigh': "Élevée",
    'incidentPriorityUnprioritized': "Non priorisé",
    'incidentRoleNoAccess': "Aucun accès",
    'incidentRoleUser': "Utilisateur",
    'incidentRoleManager': "Manager",
    'incidentRoleAdmin': "Admin",
    'userManagement': "Gestion des utilisateurs",
    'manageDepartmentsServicesBureauxAgents':
        "Gérer les départements, services, bureaux, modules et agents.",
    'addDepartment': "Ajouter un département",
    'addService': "Ajouter un service",
    'addBureau': "Ajouter un bureau",
    'addAgent': "Ajouter un agent",
    'addModule': "Ajouter un module",
    'editDepartment': "Modifier le département",
    'editService': "Modifier le service",
    'editBureau': "Modifier le bureau",
    'editAgent': "Modifier l'agent",
    'editModule': "Modifier le module",
    'departmentDetails': "Détails du département",
    'serviceDetails': "Détails du service",
    'bureauDetails': "Détails du bureau",
    'agentDetails': "Détails de l'agent",
    'moduleDetails': "Détails du module",
    'deleteDepartment': "Supprimer le département",
    'deleteService': "Supprimer le service",
    'deleteBureau': "Supprimer le bureau",
    'deleteAgent': "Supprimer l'agent",
    'deleteModule': "Supprimer le module",
    'selectDepartment': "Sélectionner un département",
    'selectService': "Sélectionner un service",
    'selectBureau': "Sélectionner un bureau",
    'searchAgents': "Rechercher des agents",
    'searchDepartments': "Rechercher des départements",
    'searchServices': "Rechercher des services",
    'searchBureaux': "Rechercher des bureaux",
    'headOfDepartment': "Chef de département",
    'headOfService': "Chef de service",
    'headOfBureau': "Chef de bureau",
    'bureauAttache': "Attaché au bureau",
    'inventory': "Inventaire",
    'cart': "Panier",
    'cartDescription': "Liste des articles dans le panier",
    'deliver': "Livrer",
    'restock': "Approvisionner",
    'totalArticles': "Total : {count} articles",
    'selectDirection': "Sélectionner la direction",
    'selectBeneficiaryDirection': "Sélectionner la direction bénéficiaire",
    'createNewItem': "Créer un nouvel article",
    'itemToAddToCart': "Article à ajouter au panier",
    'article': "Article",
    'articles': "Articles",
    'quantity': "Quantité",
    'stock': "Stock",
    'tasks': "Tâches",
    'tasksDescription': "Enregistrer et gérer les activités départementales",
    'newTask': "Nouvelle tâche",
    'editTask': "Modifier la tâche",
    'taskDetails': "Détails de la tâche",
    'taskInformation': "Informations sur la tâche",
    'taskIdentifier': "ID de la tâche",
    'departmentIdentifier': "ID du département",
    'creatorIdentifier': "ID utilisateur du créateur",
    'taskCreated': "Tâche créée",
    'taskUpdated': "Tâche mise à jour",
    'taskNotFound': "Tâche introuvable",
    'taskLoadFailed': "Impossible de charger les tâches",
    'taskAccessDenied': "Vous n'avez pas accès à la gestion des tâches.",
    'taskDepartmentMissingDescription':
        "Votre profil doit être rattaché à un département avant de pouvoir accéder aux tâches départementales.",
    'adminReadOnlyTask':
        "L'accès administrateur est en lecture seule. Vous pouvez consulter les tâches de tous les départements.",
    'allDepartmentTasks': "Tâches de tous les départements",
    'departmentTasks': "Tâches de {department}",
    'loadingTasks': "Chargement des tâches...",
    'noTasks': "Aucune tâche trouvée",
    'noTasksDescription':
        "Aucune tâche ne correspond aux filtres sélectionnés.",
    'allTypes': "Tous les types",
    'createActivity': "Créer une activité",
    'activityObject': "Objet de l'activité",
    'activityObjectHint': "Entrez l'objet de l'activité",
    'remarks': "Remarques",
    'remarksHint': "Entrer la remarque du projet ou du courrier",
    'taskStatusNew': "Nouvelle",
    'taskStatusDoing': "En traitement",
    'taskStatusDone': "Traitée",
    'taskStatusArchived': "Archivée",
    'taskTypeTask': "Projets / Autres traitements",
    'taskTypeMail': "Courrier / NSI",
    'uploadMailScan': "Téléverser le scan du courrier",
    'uploadReport': "Téléverser le rapport",
    'uploadFile': "Téléverser un fichier",
    'upload': "Téléverser",
    'uploading': "Téléversement...",
    'uploadSuccessful': "Téléversement réussi !",
    'uploadFailed': "Échec du téléversement : {error}",
    'uploadedSuccessfully': "Téléversé avec succès !",
    'document': "Document",
    'documents': "Documents",
    'mailScan': "Scan du courrier",
    'reportFile': "Rapport d'activité",
    'storagePath': "Chemin de stockage",
    'metadata': "Métadonnées",
    'noDocuments': "Aucun document n'est joint.",
    'preview': "Aperçu",
    'documentPreviewFailed': "Ce document n'a pas pu être ouvert.",
    'noFileSelected': "Aucun fichier sélectionné",
    'selectFile': "Sélectionner un fichier",
    'replaceFile': "Remplacer le fichier",
    'remove': "Retirer",
    'fileCouldNotBeRead': "Le fichier sélectionné n'a pas pu être lu.",
    'fileTooLarge': "Le fichier sélectionné dépasse la limite de 20 Mo.",
    'deleteTask': "Supprimer la tâche",
    'deleteTaskConfirmation':
        "Voulez-vous vraiment supprimer \"{taskLabel}\" ?",
    'taskDeleted': "Tâche supprimée",
    'taskDeleteFailed': "Impossible de supprimer la tâche : {error}",
    'departmentRequired': "Département requis",
    'mail': "Courrier",
    'mails': "Courriers",
    'courrier': "Courrier",
    'courriers': "Courriers",
    'noCourrierSelected': "Aucun courrier sélectionné",
    'noCourrier': "Aucun courrier",
    'addCourrier': "Ajouter un courrier",
    'courrierDetails': "Détails du courrier",
    'addAnnotation': "Ajouter une annotation",
    'annotations': "Annotations",
    'sender': "Expéditeur",
    'receiver': "Destinataire",
    'subject': "Objet",
    'receptionDate': "Date de réception",
    'emissionDate': "Date d'émission",
    'weeklyReport': "Rapport hebdomadaire",
    'weeklyReportFileName': "rapport hebdomadaire",
    'informationSystemsDepartment': "Direction des Systèmes d'Information",
    'projectsOtherProcessing': "Projets / Autres traitements",
    'social': "Social",
    'socialDashboard': "Tableau de bord social",
    'socialOffice': "Bureau social",
    'agentsSocial': "Agents",
    'medicalVoucherRequests': "Demandes de bon",
    'refunds': "Remboursements",
    'refund': "Remboursement",
    'refundList': "Liste des remboursements",
    'voucherList': "Liste des bons",
    'dependants': "Dépendants",
    'dependant': "Dépendant",
    'noDependantsYet': "Aucun dépendant pour le moment",
    'addDependant': "Ajouter un dépendant",
    'requestVoucher': "Demander un bon",
    'requestRefund': "Demander un remboursement",
    'medicalVoucher': "Bon médical",
    'serviceCertificate': "Attestation de service",
    'agentHasNoDependants': "Cet agent n'a aucun dépendant",
    'unableToLoadDependants': "Impossible de charger les dépendants",
    'loadingDependants': "Chargement des dépendants...",
    'unableToLoadRefunds': "Impossible de charger les remboursements",
    'loadingRefunds': "Chargement des remboursements...",
    'noRefundsYet': "Aucun remboursement pour le moment",
    'refundRequestsWillAppearHere':
        "Vos demandes de remboursement apparaîtront ici",
    'addDependantsToRequestVouchers':
        "Ajoutez vos dépendants pour demander des bons",
    'meetingRooms': "Salles de réunion",
    'meetingRoom': "Salle de réunion",
    'noMeetingRoomsAvailable': "Aucune salle de réunion disponible.",
    'newReservation': "Nouvelle réservation",
    'startTime': "Heure de début",
    'endTime': "Heure de fin",
    'submitReservation': "Soumettre",
    'createRoom': "Créer la salle",
    'available': "Disponible",
    'unavailable': "Indisponible",
    'capacity': "Capacité",
    'capacityPeople': "Capacité : {count} personnes",
    'roomLocation': "Emplacement",
    'closeDialog': "Fermer",
    'unableToLoadSchedule': "Impossible de charger le planning : {error}",
    'dashboard': "Tableau de bord",
    'dashboardTitle': "Tableau de bord",
    'mainDashboard': "Tableau de bord principal",
    'loadingStatistics': "Chargement des statistiques...",
    'errorLoadingData': "Erreur lors du chargement des données",
    'failedToLoadDashboardStatistics':
        "Échec du chargement des statistiques du tableau de bord",
    'dashboardDataDoesNotExist':
        "Les données du tableau de bord n'existent pas",
    'chartMedicalVouchers': "Nombre de bons",
    'monthJanuaryShort': "Jan",
    'monthFebruaryShort': "Fév",
    'monthMarchShort': "Mar",
    'monthAprilShort': "Avr",
    'monthMayShort': "Mai",
    'monthJuneShort': "Juin",
    'monthJulyShort': "Juil",
    'monthAugustShort': "Août",
    'monthSeptemberShort': "Sept",
    'monthOctoberShort': "Oct",
    'monthNovemberShort': "Nov",
    'monthDecemberShort': "Déc",
    'admin': "Admin",
    'manager': "Manager",
    'reviewer': "Réviseur",
    'noAccess': "Aucun accès",
    'moduleRoleUser': "Utilisateur",
    'moduleRoleManager': "Manager",
    'moduleRoleAdmin': "Admin",
    'moduleRoleReviewer': "Réviseur",
    'moduleRoleNone': "Aucun",
    'permissionAdminDescription':
        "Peut superviser le module selon le modèle d'accès configuré.",
    'permissionManagerDescription':
        "Peut gérer le travail opérationnel dans le module.",
    'permissionUserDescription':
        "Peut utiliser le module pour son propre travail.",
    'permissionNoneDescription': "Aucun accès à ce module.",
    'requiredField': "Ce champ est obligatoire",
    'enterTitle': "Saisissez un titre",
    'enterShortDescription': "Saisissez une brève description",
    'enterName': "Saisissez un nom",
    'enterEmail': "Saisissez un e-mail",
    'invalidEmail': "Saisissez une adresse e-mail valide.",
    'selectRole': "Sélectionnez un rôle",
    'selectModule': "Sélectionnez un module",
    'searchByName': "Rechercher par nom",
    'searchByNameEmailOrMatricule': "Rechercher par nom, e-mail ou matricule",
    'noResults': "Aucun résultat",
    'noItems': "Aucun élément",
    'emptyList': "La liste est vide.",
    'connectionError': "Erreur de connexion",
    'unableToConnect': "Impossible de se connecter",
    'serverError': "Erreur serveur",
    'permissionDenied': "Autorisations manquantes ou insuffisantes.",
    'file': "Fichier",
    'files': "Fichiers",
    'download': "Télécharger",
    'print': "Imprimer",
    'export': "Exporter",
    'pdf': "PDF",
    'excel': "Excel",
    'report': "Rapport",
    'reports': "Rapports",
    'amount': "Montant",
    'hospital': "Hôpital",
    'relation': "Relation",
    'beneficiary': "Bénéficiaire",
    'serviceCatalogueTitle': "Catalogue de services",
    'serviceCatalogueDescription':
        "Parcourez les services IT publiés et soumettez une demande guidée.",
    'serviceCatalogueSearchHint': "Rechercher des services",
    'serviceCatalogueEmpty': "Aucun service du catalogue n'est disponible",
    'serviceCatalogueEmptyDescription':
        "Les services publiés apparaîtront ici dès qu'ils seront disponibles.",
    'browseCatalogue': "Parcourir le catalogue",
    'allCatalogueCategories': "Toutes les catégories",
    'requestThisService': "Demander ce service",
    'createServiceRequest': "Créer une demande de service",
    'serviceRequestDetails': "Détails de la demande de service",
    'serviceRequestQueue': "File des demandes de service",
    'serviceRequestQueueDescription':
        "Examinez, affectez, approuvez et exécutez les demandes de service.",
    'requestOnBehalfOf': "Demander au nom d'un agent",
    'requestedFor': "Demandé pour",
    'requestSubmitted': "Votre demande de service a été soumise.",
    'submitRequest': "Soumettre la demande",
    'submittingRequest': "Soumission de la demande...",
    'serviceRequestValidationIssues':
        "Veuillez corriger les champs suivants de la demande : {issues}",
    'requiredDocuments': "Documents requis",
    'requiredInformation': "Informations requises",
    'eligibility': "Éligibilité",
    'estimatedDelivery': "Délai estimé",
    'myRequestsTitle': "Mes demandes",
    'myRequestsDescription':
        "Suivez vos incidents, demandes de service et autres travaux ITSM au même endroit.",
    'myRequestsSearchHint': "Rechercher par référence ou titre",
    'myRequestsEmpty': "Vous n'avez encore aucune demande",
    'myRequestsEmptyDescription':
        "Les incidents et demandes de service que vous soumettez apparaîtront ici.",
    'allRequestTypes': "Tous les types de demande",
    'loadMore': "Charger plus",
    'loadingMore': "Chargement...",
    'requestStatusDraft': "Brouillon",
    'requestStatusSubmitted': "Soumise",
    'requestStatusAwaitingApproval': "En attente d'approbation",
    'requestStatusApproved': "Approuvée",
    'requestStatusAssigned': "Affectée",
    'requestStatusInFulfilment': "En cours d'exécution",
    'requestStatusAwaitingUser': "En attente de l'utilisateur",
    'requestStatusFulfilled': "Exécutée",
    'requestStatusClosed': "Clôturée",
    'requestStatusRejected': "Rejetée",
    'requestStatusCancelled': "Annulée",
    'cancelRequest': "Annuler la demande",
    'confirmCancelRequest':
        "Annuler cette demande ? Cette action est irréversible.",
    'requestCancelled': "La demande a été annulée.",
    'approveRequest': "Approuver la demande",
    'rejectRequest': "Rejeter la demande",
    'rejectionReason': "Motif du rejet",
    'rejectionReasonRequired': "Le motif du rejet est obligatoire.",
    'assignRequest': "Affecter la demande",
    'assignmentGroup': "Groupe d'affectation",
    'fulfilmentTasks': "Tâches d'exécution",
    'addFulfilmentTask': "Ajouter une tâche d'exécution",
    'markFulfilled': "Marquer comme exécutée",
    'confirmCompletion': "Confirmer l'achèvement",
    'approvalHistory': "Historique des approbations",
    'statusTimeline': "Historique des statuts",
    'linkedRecords': "Éléments liés",
    'relatedAsset': "Actif lié",
    'relatedIncident': "Incident lié",
    'relatedServiceRequest': "Demande de service liée",
    'relatedChange': "Changement lié",
    'configurationItem': "Élément de configuration",
    'slaStatus': "État du SLA",
    'slaOnTrack': "Dans les délais",
    'slaWarning': "À risque",
    'slaBreached': "Dépassé",
    'slaPaused': "En pause",
    'dueDate': "Date d'échéance",
    'knowledgeBaseTitle': "Base de connaissances",
    'knowledgeBaseDescription':
        "Trouvez des conseils, des solutions et des informations de service fiables.",
    'knowledgeSearchHint': "Rechercher dans la base de connaissances",
    'featuredArticles': "Articles à la une",
    'recentArticles': "Articles récents",
    'knowledgeArticleDetails': "Article de connaissance",
    'noKnowledgeArticles': "Aucun article de connaissance n'est disponible",
    'noKnowledgeArticlesDescription':
        "Les conseils publiés apparaîtront ici dès qu'ils seront disponibles.",
    'loadingKnowledge': "Chargement de la base de connaissances...",
    'unableToLoadKnowledge': "Impossible de charger la base de connaissances",
    'wasThisHelpful': "Cet article vous a-t-il été utile ?",
    'helpful': "Utile",
    'notHelpful': "Pas utile",
    'thankYouForFeedback': "Merci pour votre avis.",
    'employeeVisible': "Visible par tous les agents",
    'dsiOnly': "DSI uniquement",
    'articleAuthor': "Auteur",
    'articleReviewer': "Réviseur",
    'reviewDate': "Date de révision",
    'expiryDate': "Date d'expiration",
    'newKnowledgeArticle': "Nouvel article",
    'editKnowledgeArticle': "Modifier l'article",
    'knowledgeReviewQueue': "File de révision des connaissances",
    'manageKnowledge': "Gérer les connaissances",
    'knowledgeStateDraft': "Brouillon",
    'knowledgeStateReview': "En révision",
    'knowledgeStatePublished': "Publié",
    'knowledgeStateRetired': "Retiré",
    'knowledgeStateArchived': "Archivé",
    'publishArticle': "Publier l'article",
    'retireArticle': "Retirer l'article",
    'archiveArticle': "Archiver l'article",
    'articleVersion': "Version de l'article",
    'articleContent': "Contenu de l'article",
    'articleVisibility': "Visibilité de l'article",
    'articlePublished': "L'article a été publié.",
    'articleRetired': "L'article a été retiré.",
    'relatedServices': "Services liés",
    'relatedCatalogueItems': "Éléments du catalogue liés",
    'relatedIncidentCategories': "Catégories d'incident liées",
    'suggestedKnowledge': "Connaissances suggérées",
    'suggestedKnowledgeDescription':
        "Ces articles publiés peuvent aider à résoudre cette demande.",
    'viewArticle': "Voir l'article",
    'knowledgeAttachments': "Pièces jointes de l'article",
    'knowledgeAttachmentsHint':
        "Sélectionnez les fichiers avant l'enregistrement. Les fichiers téléversés sont rattachés à la version immuable de l'article.",
    'internalAttachment': "Visible uniquement par le personnel informatique",
    'operationalActions': "Actions opérationnelles",
    'readOnlyAccess': "Accès en lecture seule",
    'readOnlyAccessDescription':
        "Vous pouvez consulter ces informations sans les modifier.",
    'assetConfigurationOverview': "Actifs et configuration",
    'assetConfigurationOverviewDescription':
        "Suivez les équipements, le stock, les licences, les fournisseurs, les garanties et les dépendances de service.",
    'myAssets': "Mes actifs",
    'myAssetsDescription':
        "Consultez les équipements qui vous sont affectés et demandez une assistance via le catalogue de services.",
    'assetRegister': "Registre des actifs",
    'assetRegisterDescription':
        "Gérez le cycle de vie complet et la garde des actifs informatiques de l'organisation.",
    'noAssetsAssigned': "Aucun actif ne vous est actuellement affecté.",
    'noAssetsFound': "Aucun actif ne correspond aux filtres sélectionnés.",
    'unableToLoadAssets': "Impossible de charger les actifs",
    'searchAssets':
        "Rechercher par étiquette, numéro de série, marque ou modèle",
    'assetTag': "Étiquette de l'actif",
    'serialNumber': "Numéro de série",
    'brand': "Marque",
    'model': "Modèle",
    'condition': "État",
    'custodian': "Dépositaire",
    'acquisitionDate': "Date d'acquisition",
    'acquisitionCost': "Coût d'acquisition",
    'supplier': "Fournisseur",
    'warranty': "Garantie",
    'securityBaseline': "Référentiel de sécurité",
    'lifecycleHistory': "Historique du cycle de vie",
    'assetPhotographs': "Photographies de l'actif",
    'reportAssetFault': "Signaler une panne",
    'requestAssetRepair': "Demander une réparation",
    'requestAssetReplacement': "Demander un remplacement",
    'requestAssetConfiguration': "Demander une configuration",
    'requestAssetReturn': "Demander un retour",
    'assetActionCreatesRequest':
        "Cette action crée une demande de service gouvernée et ne modifie pas directement l'actif.",
    'stockManagement': "Gestion du stock",
    'stockManagementDescription':
        "Contrôlez les quantités au moyen de mouvements de stock traçables et atomiques.",
    'stockLocations': "Emplacements de stock",
    'stockItems': "Articles en stock",
    'stockMovements': "Mouvements de stock",
    'quantityOnHand': "Quantité en stock",
    'quantityReserved': "Quantité réservée",
    'quantityAvailable': "Quantité disponible",
    'minimumStockThreshold': "Seuil minimum de stock",
    'lowStock': "Stock faible",
    'movementType': "Type de mouvement",
    'movementReceipt': "Réception",
    'movementReservation': "Réservation",
    'movementIssue': "Sortie",
    'movementReturn': "Retour",
    'movementTransfer': "Transfert",
    'movementAdjustment': "Ajustement",
    'movementReconciliation': "Rapprochement",
    'sourceLocation': "Emplacement source",
    'destinationLocation': "Emplacement de destination",
    'recipient': "Bénéficiaire",
    'relatedRequest': "Demande liée",
    'supportingDocument': "Justificatif",
    'softwareLicences': "Licences logicielles",
    'softwareLicencesDescription':
        "Gérez les affectations, la conformité, les contrats et les renouvellements sans exposer les secrets de licence.",
    'softwareProduct': "Produit logiciel",
    'vendor': "Éditeur",
    'licenceType': "Type de licence",
    'purchasedQuantity': "Quantité achetée",
    'allocatedQuantity': "Quantité affectée",
    'availableQuantity': "Quantité disponible",
    'effectiveDate': "Date d'effet",
    'renewalDate': "Date de renouvellement",
    'complianceStatus': "État de conformité",
    'licenceAssignments': "Affectations de licences",
    'suppliersWarrantiesDescription':
        "Gérez les fournisseurs, les contrats, la couverture de garantie, les réclamations et les dates d'expiration.",
    'supplierRegister': "Registre des fournisseurs",
    'contracts': "Contrats",
    'supportTerms': "Conditions d'assistance",
    'contractStart': "Début du contrat",
    'contractEnd': "Fin du contrat",
    'warrantyCoverage': "Couverture de garantie",
    'warrantyExpiration': "Expiration de la garantie",
    'warrantyClaims': "Réclamations de garantie",
    'configurationManagementDatabase':
        "Base de données de gestion des configurations",
    'cmdbDescription':
        "Cartographiez les services critiques, les applications, l'infrastructure, les appareils et leurs dépendances directionnelles.",
    'configurationItems': "Éléments de configuration",
    'ciType': "Type d'élément de configuration",
    'ciOwner': "Responsable de l'élément",
    'supportGroup': "Groupe de support",
    'criticality': "Criticité",
    'operationalStatus': "État opérationnel",
    'configurationBaseline': "Référentiel de configuration",
    'dataQualityStatus': "État de qualité des données",
    'relationships': "Relations",
    'impactView': "Vue d'impact",
    'dependencyView': "Vue des dépendances",
    'dependsOn': "Dépend de",
    'runsOn': "S'exécute sur",
    'connectedTo': "Connecté à",
    'uses': "Utilise",
    'representedBy': "Représenté par",
    'managerOperationalAccessRequired':
        "Le rôle MANAGER est requis pour accéder à cette fonction opérationnelle.",
    'assetCommandCompleted': "L'opération sur l'actif est terminée.",
    'stockMovementCompleted': "Le mouvement de stock a été enregistré.",
    'licenceOperationCompleted': "L'opération sur la licence est terminée.",
    'registerNewAsset': "Enregistrer un nouvel actif",
    'registerNewLicence': "Enregistrer une nouvelle licence",
    'allocateLicence': "Affecter la licence",
    'releaseLicence': "Libérer l'affectation",
    'saveSupplier': "Enregistrer le fournisseur",
    'saveContract': "Enregistrer le contrat",
    'saveWarranty': "Enregistrer la garantie",
    'recordWarrantyClaim': "Enregistrer une réclamation de garantie",
    'saveConfigurationItem': "Enregistrer l'élément de configuration",
    'createRelationship': "Créer une relation",
    'retireRelationship': "Retirer la relation",
    'configurationOperationCompleted':
        "L'opération de configuration est terminée.",
    'recordIdentifier': "Identifiant de l'enregistrement",
    'categoryId': "Identifiant de catégorie",
    'supplierId': "Identifiant du fournisseur",
    'contractId': "Identifiant du contrat",
    'warrantyId': "Identifiant de la garantie",
    'claimId': "Identifiant de la réclamation",
    'allocationId': "Identifiant de l'affectation",
    'assigneeId': "Identifiant du bénéficiaire",
    'assigneeName': "Nom du bénéficiaire",
    'assignmentType': "Type d'affectation",
    'contactName': "Nom du contact",
    'legalName': "Raison sociale",
    'contractNumber': "Numéro de contrat",
    'warrantyNumber': "Numéro de garantie",
    'relationshipType': "Type de relation",
    'sourceType': "Type de source",
    'sourceId': "Identifiant de la source",
    'targetType': "Type de cible",
    'targetId': "Identifiant de la cible",
    'linkedAssetId': "Identifiant de l'actif lié",
    'ownerUserId': "Identifiant du responsable",
    'ownerName': "Nom du responsable",
    'address': "Adresse",
    'currency': "Devise",
    'invalidIdentifier':
        "Utilisez uniquement des lettres, chiffres, points, tirets, traits de soulignement ou deux-points.",
    'invalidDate': "Saisissez une date valide au format AAAA-MM-JJ.",
    'positiveWholeNumberRequired': "Saisissez un nombre entier positif.",
    'isoDateHint': "AAAA-MM-JJ",
    'assignmentUser': "Utilisateur",
    'assignmentDevice': "Appareil",
    'ciService': "Service",
    'ciApplication': "Application",
    'ciServer': "Serveur",
    'ciDatabase': "Base de données",
    'ciNetwork': "Réseau",
    'ciDevice': "Appareil",
    'statusPlanned': "Planifié",
    'statusDegraded': "Dégradé",
    'statusMaintenance': "Maintenance",
    'statusRetired': "Retiré",
    'dataQualityVerified': "Vérifié",
    'dataQualityNeedsReview': "À réviser",
    'dataQualityIncomplete': "Incomplet",
    'editAsset': "Modifier l'actif",
    'assignAsset': "Affecter l'actif",
    'returnAsset': "Restituer l'actif",
    'transitionAsset': "Changer l'état du cycle de vie",
    'assignedUserId': "UID de l'agent affecté",
    'assignedAssetReturnHint':
        "La restitution est disponible uniquement lorsque l'actif a une affectation en cours.",
    'transitionReason': "Motif de la transition",
    'lifecycleOperationCompleted': "L'opération sur l'actif est terminée.",
    'addStockLocation': "Ajouter un emplacement de stock",
    'editStockLocation': "Modifier un emplacement de stock",
    'addStockItem': "Ajouter un article de stock",
    'editStockItem': "Modifier un article de stock",
    'stockLocationId': "ID de l'emplacement de stock",
    'stockItemId': "ID de l'article de stock",
    'sku': "UGS",
    'unitOfMeasure': "Unité de mesure",
    'isConsumable': "Article consommable",
    'adjustmentDirection': "Sens de l'ajustement",
    'increaseStock': "Augmenter le stock",
    'decreaseStock': "Diminuer le stock",
    'reservedQuantityFulfilled': "Quantité réservée honorée",
    'targetOnHand': "Quantité physique cible",
    'targetReserved': "Quantité réservée cible",
    'movementReason': "Motif du mouvement",
    'movementRequirementsHint':
        "Les champs obligatoires changent selon le type de mouvement sélectionné.",
    'sourceLocationRequired':
        "Un emplacement source est obligatoire pour ce mouvement.",
    'destinationLocationRequired':
        "Un emplacement de destination est obligatoire pour ce mouvement.",
    'recipientRequired':
        "L'UID de l'agent destinataire est obligatoire pour ce mouvement.",
    'evidenceRequired':
        "L'ID d'une pièce justificative est obligatoire pour ce mouvement.",
    'nonNegativeNumberRequired': "Saisissez zéro ou un nombre positif.",
    'reservedQuantityTooHigh':
        "La quantité réservée honorée ne peut pas dépasser la quantité sortie.",
    'editSupplier': "Modifier le fournisseur",
    'editContract': "Modifier le contrat",
    'editWarranty': "Modifier la garantie",
    'manageWarranty': "Gérer la garantie",
    'transitionWarrantyClaim': "Mettre à jour l'état de la réclamation",
    'claimStatus': "État de la réclamation",
    'claimResolution': "Motif ou résolution de la réclamation",
    'supplierContact': "Contact principal du fournisseur",
    'editConfigurationItem': "Modifier l'élément de configuration",
    'relatedIncidentIds': "IDs des incidents liés",
    'relatedRequestIds': "IDs des demandes liées",
    'relatedChangeIds': "IDs des changements liés",
    'relatedFindingIds': "IDs des constats de sécurité liés",
    'commaSeparatedIdsHint': "IDs séparés par des virgules",
    'allRelationships': "Toutes les relations",
    'showDependencies': "Dépendances",
    'showImpact': "Impact",
    'recipientUserId': "UID de l'agent destinataire",
    'claimSubmitted': "Soumise",
    'claimAcknowledged': "Accusée réception",
    'claimApproved': "Approuvée",
    'claimRejected': "Rejetée",
    'claimResolved': "Résolue",
    'claimClosed': "Clôturée",
    'assetStatusOrdered': "Commandé",
    'assetStatusReceived': "Reçu",
    'assetStatusInStock': "En stock",
    'assetStatusConfigured': "Configuré",
    'assetStatusAssigned': "Affecté",
    'assetStatusReturned': "Restitué",
    'assetStatusDisposed': "Mis au rebut",
    'assetStatusLost': "Perdu",
    'assetStatusStolen': "Volé",
    'uploadAssetAttachment': "Téléverser une pièce jointe",
    'uploadAssetPhotograph': "Téléverser une photographie",
    'scanStockBarcode': "Scanner le code-barres",
    'scanStockBarcodeHint': "Scannez ou saisissez le code-barres de l'article",
    'barcodeNotFound': "Aucun article en stock ne correspond à ce code-barres.",
    'attachmentRegistrationSuccessful':
        "Le fichier a été téléversé et enregistré de manière sécurisée.",
    'chooseSupportingDocument': "Choisir une pièce justificative",
    'changeManagementTitle': "Gestion des changements",
    'changeManagementSubtitle':
        "Planifiez, évaluez, approuvez, programmez et révisez les changements de services contrôlés.",
    'newChange': "Nouveau changement",
    'myChanges': "Mes changements",
    'operationalChanges': "Changements opérationnels",
    'changeEmptyTitle': "Aucune demande de changement",
    'changeEmptyDescription':
        "Les demandes correspondant à cette vue apparaîtront ici.",
    'changeRequestDetails': "Détails de la demande de changement",
    'changeType': "Type de changement",
    'changeStandard': "Standard",
    'changeNormal': "Normal",
    'changeEmergency': "Urgent",
    'changeJustification': "Justification métier",
    'saveChangeDraft': "Enregistrer le brouillon",
    'submitChange': "Soumettre le changement",
    'assessChange': "Évaluer le changement",
    'requestChangeApproval': "Demander l'approbation",
    'scheduleChange': "Programmer le changement",
    'startImplementation': "Démarrer la mise en œuvre",
    'recordImplementation': "Enregistrer le résultat",
    'recordPostImplementationReview': "Enregistrer la revue",
    'closeChange': "Clôturer le changement",
    'cancelChange': "Annuler le changement",
    'changeOwner': "Responsable du changement",
    'changeRequester': "Demandeur",
    'affectedServices': "Services affectés",
    'affectedConfigurationItems': "Éléments de configuration affectés",
    'affectedAssets': "Actifs affectés",
    'plannedStart': "Début planifié",
    'plannedEnd': "Fin planifiée",
    'expectedDowntime': "Interruption prévue (minutes)",
    'implementationPlan': "Plan de mise en œuvre",
    'testPlan': "Plan de test",
    'communicationPlan': "Plan de communication",
    'rollbackPlan': "Plan de retour arrière",
    'cabApprovalsTitle': "Approbations et CAB",
    'cabApprovalsSubtitle':
        "Examinez les changements en attente et conservez un historique immuable des décisions.",
    'approveChange': "Approuver",
    'approveWithConditions': "Approuver sous conditions",
    'rejectChange': "Rejeter",
    'requestClarification': "Demander une clarification",
    'decisionComment': "Commentaire de décision",
    'approvalConditions': "Conditions d'approbation",
    'changeCalendarTitle': "Calendrier des changements",
    'changeCalendarSubtitle':
        "Consultez les fenêtres de mise en œuvre, les maintenances et les conflits.",
    'calendarMonth': "Mois",
    'calendarWeek': "Semaine",
    'calendarAgenda': "Agenda",
    'calendarPrevious': "Période précédente",
    'calendarNext': "Période suivante",
    'changeConflict': "Conflit",
    'maintenancePublished': "Maintenance publiée",
    'changeReadOnly': "Vue en lecture seule",
    'changeCommandSuccessful': "Le changement a été mis à jour avec succès.",
    'changeReasonRequired': "Un motif est obligatoire.",
    'changeSelectStatus': "Filtrer par statut",
    'changeActiveView': "Actifs",
    'changeHistoryView': "Historique",
    'changeStatusDraft': "Brouillon",
    'changeStatusSubmitted': "Soumis",
    'changeStatusAssessment': "Évaluation",
    'changeStatusAwaitingApproval': "En attente d'approbation",
    'changeStatusApproved': "Approuvé",
    'changeStatusScheduled': "Programmé",
    'changeStatusImplementation': "Mise en œuvre",
    'changeStatusReview': "Revue",
    'changeStatusClosed': "Clôturé",
    'changeStatusRejected': "Rejeté",
    'changeStatusCancelled': "Annulé",
    'changeStatusFailed': "Échoué",
    'changeStatusRolledBack': "Retour arrière effectué",
    'changeComplexity': "Complexité",
    'maintenanceWindow': "Fenêtre de maintenance",
    'changeRisk': "Risque",
    'changeRevision': "Révision",
    'changeRiskLow': "Faible",
    'changeRiskMedium': "Moyen",
    'changeRiskHigh': "Élevé",
    'changeRiskCritical': "Critique",
    'changeServiceFilter': "ID du service affecté",
    'changeCiFilter': "ID de l'élément de configuration",
    'changeRelatedRecords': "Enregistrements liés",
    'changeImplementationResult': "Résultat de la mise en œuvre",
    'changePostImplementationReview': "Revue post-implémentation",
    'changeOutcomeSuccessful': "Réussi",
    'changeOutcomePartial': "Partiellement réussi",
    'changeOutcomeFailed': "Échoué",
    'changeOutcomeRolledBack': "Retour arrière effectué",
    'cabMeeting': "Réunion CAB",
    'cabMeetings': "Réunions CAB",
    'scheduleCabMeeting': "Programmer une réunion CAB",
    'cabApprovalGroup': "ID du groupe d'approbation CAB",
    'cabParticipantIds': "UID des responsables participants",
    'cabMeetingNotes': "Notes de réunion",
    'noCabMeetings':
        "Aucune réunion CAB n'a été programmée pour ce changement.",
    'changeConflictsOnly': "Conflits uniquement",
    'changeComments': "Commentaires",
    'changeAttachments': "Pièces jointes",
    'changeActivityTimeline': "Chronologie des activités",
    'noChangeComments': "Aucun commentaire visible pour le moment.",
    'noChangeAttachments': "Aucune pièce jointe visible pour le moment.",
    'noChangeActivity': "Aucune activité visible pour le moment.",
    'unableToLoadChangeCollaboration':
        "Impossible de charger ces informations.",
    'requesterVisible': "Visible par le demandeur",
    'internalVisibility': "Interne",
    'changeCollaborationReadOnlyDescription':
        "Les commentaires, pièces jointes et activités sont affichés selon votre accès. Les mises à jour du workflow restent disponibles uniquement via les actions autorisées ci-dessus.",
    'itsmScSecurityComplianceTitle': "Sécurité et conformité",
    'itsmScSecurityComplianceSubtitle':
        "Gérez les risques, dérogations, appareils et revues des accès.",
    'itsmScSecurityFindingsTitle': "Constats de sécurité",
    'itsmScSecurityFindingsSubtitle':
        "Constats opérationnels restreints et suivi des remédiations.",
    'itsmScSecurityExceptionsTitle': "Dérogations de sécurité",
    'itsmScSecurityExceptionsSubtitle':
        "Demandez, examinez et suivez les dérogations limitées dans le temps.",
    'itsmScAssetComplianceTitle': "Conformité des actifs",
    'itsmScAssetComplianceSubtitle':
        "Évaluez les contrôles ou consultez le statut sécurisé de vos appareils.",
    'itsmScAccessReviewsTitle': "Revues des accès",
    'itsmScAccessReviewsSubtitle':
        "Examinez les accès ou demandez une correction de vos propres accès.",
    'itsmScLoading': "Chargement des données de sécurité…",
    'itsmScRetry': "Réessayer",
    'itsmScLoadMore': "Charger plus",
    'itsmScLoadingMore': "Chargement…",
    'itsmScNoData': "Aucun enregistrement",
    'itsmScNoDataDescription':
        "Aucune donnée ne correspond à la vue sélectionnée.",
    'itsmScUnableToLoad': "Impossible de charger les données de sécurité.",
    'itsmScAccessDenied': "Accès refusé",
    'itsmScManagerAccessRequired':
        "Cette vue opérationnelle est réservée aux utilisateurs MANAGER ITSM.",
    'itsmScSelfServiceAccessRequired':
        "Cette vue libre-service n’est pas disponible pour votre rôle.",
    'itsmScAdminReadOnlyNotice':
        "ADMIN n’a pas accès aux opérations brutes. Seuls ses dossiers libre-service sont affichés.",
    'itsmScSelfServiceOnlyNotice':
        "Seuls vos propres dossiers libre-service sont affichés dans cette vue.",
    'itsmScOperationalView': "Vue opérationnelle",
    'itsmScMyRecords': "Mes dossiers",
    'itsmScCampaigns': "Campagnes",
    'itsmScReviewItems': "Éléments à revoir",
    'itsmScCorrectionRequests': "Demandes de correction",
    'itsmScAllStatuses': "Tous les statuts",
    'itsmScStatus': "Statut",
    'itsmScSeverity': "Sévérité",
    'itsmScRisk': "Risque",
    'itsmScOwner': "Responsable",
    'itsmScDueDate': "Échéance",
    'itsmScUpdated': "Mis à jour",
    'itsmScReference': "Référence",
    'itsmScSystem': "Système",
    'itsmScDepartment': "Département",
    'itsmScCurrentAccess': "Accès actuel",
    'itsmScCurrentRole': "Rôle actuel",
    'itsmScDevice': "Appareil",
    'itsmScAssessedAt': "Évalué",
    'itsmScReviewDate': "Date de revue",
    'itsmScPeriod': "Période",
    'itsmScEvidence': "Preuves accessibles",
    'itsmScRestrictedEvidenceHidden':
        "Les preuves restreintes sont masquées sans autorisation explicite.",
    'itsmScNewFinding': "Nouveau constat",
    'itsmScSubmitException': "Soumettre une dérogation",
    'itsmScRecordAssessment': "Enregistrer une évaluation",
    'itsmScNewCampaign': "Nouvelle campagne",
    'itsmScRequestCorrection': "Demander une correction",
    'itsmScRequestRevocation': "Demander une révocation",
    'itsmScDecide': "Enregistrer la décision",
    'itsmScApprove': "Approuver",
    'itsmScReject': "Rejeter",
    'itsmScRetain': "Conserver",
    'itsmScRevoke': "Révoquer",
    'itsmScModify': "Modifier",
    'itsmScTransition': "Changer le statut",
    'itsmScCancel': "Annuler",
    'itsmScSubmit': "Soumettre",
    'itsmScSave': "Enregistrer",
    'itsmScTitle': "Titre",
    'itsmScDescription': "Description",
    'itsmScSource': "Source",
    'itsmScRequirementOrControl': "Exigence ou contrôle",
    'itsmScBusinessJustification': "Justification métier",
    'itsmScScope': "Périmètre",
    'itsmScRiskDescription': "Description du risque",
    'itsmScCompensatingControl': "Mesure compensatoire",
    'itsmScReason': "Motif",
    'itsmScComment': "Commentaire",
    'itsmScAssetId': "ID de l’actif",
    'itsmScAssetTag': "Étiquette de l’actif",
    'itsmScAssetName': "Nom de l’actif",
    'itsmScSummary': "Résumé",
    'itsmScCampaignTitle': "Titre de la campagne",
    'itsmScSystemId': "ID du système",
    'itsmScSystemName': "Nom du système",
    'itsmScCommandCompleted': "L’opération de sécurité a été acceptée.",
    'itsmScCommandFailed': "L’opération de sécurité n’a pas pu être exécutée.",
    'itsmScRequiredField': "Ce champ est obligatoire.",
    'itsmScCorrectionSubmitted': "Votre demande de correction a été soumise.",
    'itsmScOwnComplianceUnavailable':
        "La conformité de ses appareils est réservée au libre-service USER.",
    'itsmScFindingsCount': "Constats",
    'itsmScExceptionsCount': "Dérogations",
    'itsmScAssessmentsCount': "Évaluations",
    'itsmScReviewsCount': "Revues",
    'itsmScComplianceCompliant': "Conforme",
    'itsmScComplianceActionRequired': "Action requise",
    'itsmScComplianceAssessmentPending': "Évaluation en attente",
    'itsmScSeverityLow': "Faible",
    'itsmScSeverityMedium': "Moyenne",
    'itsmScSeverityHigh': "Élevée",
    'itsmScSeverityCritical': "Critique",
    'itsmScNotAssigned': "Non attribué",
    'itsmScOwnerUserId': "ID du responsable",
    'itsmScRemediationPlan': "Plan de remédiation",
    'itsmScValidationResult': "Résultat de validation",
    'itsmScActionTriageFinding': "Qualifier le constat",
    'itsmScActionAssignFinding': "Attribuer le constat",
    'itsmScActionPlanRemediation': "Planifier la remédiation",
    'itsmScActionSubmitValidation': "Soumettre pour validation",
    'itsmScActionValidateFinding': "Enregistrer la validation",
    'itsmScActionAcceptRisk': "Accepter le risque",
    'itsmScActionCloseFinding': "Clôturer le constat",
    'itsmScActionCancelFinding': "Annuler le constat",
    'itsmScActionSubmitException': "Soumettre la dérogation",
    'itsmScActionRequestExceptionApproval': "Demander une approbation",
    'itsmScActionDecideExceptionApproval': "Décider de l’approbation",
    'itsmScActionActivateException': "Activer la dérogation",
    'itsmScActionRenewException': "Renouveler la dérogation",
    'itsmScActionCloseException': "Clôturer la dérogation",
    'itsmScApproverUserId': "ID de l’approbateur",
    'itsmScApprovalId': "ID de l’approbation",
    'itsmScDecision': "Décision",
    'itsmScFindingStatusDetected': "Détecté",
    'itsmScFindingStatusTriaged': "Qualifié",
    'itsmScFindingStatusAssigned': "Attribué",
    'itsmScFindingStatusRemediation': "Remédiation",
    'itsmScFindingStatusValidation': "Validation",
    'itsmScFindingStatusClosed': "Clôturé",
    'itsmScFindingStatusRiskAccepted': "Risque accepté",
    'itsmScFindingStatusCancelled': "Annulé",
    'itsmScExceptionStatusDraft': "Brouillon",
    'itsmScExceptionStatusSubmitted': "Soumise",
    'itsmScExceptionStatusUnderReview': "En cours d’examen",
    'itsmScExceptionStatusAwaitingApproval': "En attente d’approbation",
    'itsmScExceptionStatusApproved': "Approuvée",
    'itsmScExceptionStatusRejected': "Rejetée",
    'itsmScExceptionStatusActive': "Active",
    'itsmScExceptionStatusExpired': "Expirée",
    'itsmScExceptionStatusClosed': "Clôturée",
    'itsmScExceptionStatusCancelled': "Annulée",
    'itsmScCampaignStatusDraft': "Brouillon",
    'itsmScCampaignStatusActive': "Active",
    'itsmScCampaignStatusCompleted': "Terminée",
    'itsmScCampaignStatusCancelled': "Annulée",
    'itsmScReviewStatusPending': "En attente",
    'itsmScReviewStatusDecided': "Décidée",
    'itsmScReviewStatusRevocationPending': "Révocation en attente",
    'itsmScReviewStatusCompleted': "Terminée",
    'itsmScCorrectionStatusSubmitted': "Soumise",
    'itsmScCorrectionStatusInReview': "En cours d’examen",
    'itsmScCorrectionStatusCompleted': "Terminée",
    'itsmScCorrectionStatusRejected': "Rejetée",
    'itsmScCorrectionStatusCancelled': "Annulée",
    'itsmScValidationPassed': "Réussie",
    'itsmScValidationFailed': "Échouée",
    'itsmScValidationPartial': "Partiellement validée",
    'itsmScRemediationSummary': "Résumé de l’évaluation et de la remédiation",
    'itsmScControlOperatingSystem': "Support du système d’exploitation",
    'itsmScControlPatchStatus': "État des correctifs",
    'itsmScControlAntivirus': "Antivirus / EDR",
    'itsmScControlEncryption': "Chiffrement du disque",
    'itsmScControlBackup': "Sauvegarde",
    'itsmScControlApprovedSoftware': "Logiciels approuvés",
    'itsmScControlSecurityBaseline': "Référentiel de sécurité",
    'itsmScNotApplicable': "Non applicable",
    'itsmScUnknown': "Inconnu",
    'itsmScCompleteRevocationTask': "Terminer la tâche de révocation",
    'itsmScActivateCampaign': "Activer la campagne",
    'itsmScCreateReviewItem': "Créer un élément de revue",
    'itsmScCompleteCampaign': "Terminer la campagne",
    'itsmScSubjectUserId': "ID de l’utilisateur concerné",
    'itsmScDepartmentId': "ID du département",
    'itsmScReviewerUserId': "ID du réviseur",
    'itsmScAssignedToUserId': "ID du responsable assigné",
    'itsmScTargetAccess': "Accès cible",
    'itsmScTaskId': "ID de la tâche de révocation",
    'itsmScCompletionEvidenceId': "ID de la preuve d’exécution",
  },
};
