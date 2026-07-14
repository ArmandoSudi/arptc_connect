// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';

class S {
  S._(this.localeName, this._messages);

  final String localeName;
  final Map<String, String> _messages;
  static S? _current;

  static S get current {
    assert(_current != null, 'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) async {
    final localeName = _supportedLanguageCodes.contains(locale.languageCode) ? locale.languageCode : 'en';
    final instance = S._(localeName, _localizedValues[localeName] ?? _localizedValues['en']!);
    _current = instance;
    return instance;
  }

  static S of(BuildContext context) {
    final instance = maybeOf(context);
    assert(instance != null, 'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) => Localizations.of<S>(context, S);

  String _text(String key) => _messages[key] ?? _localizedValues['en']?[key] ?? key;

  String _format(String key, Map<String, Object?> values) {
    var result = _text(key);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value?.toString() ?? '');
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
  String get publishedInformationWillAppearHere => _text('publishedInformationWillAppearHere');
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
  String get noAuthorizedModuleDescription => _text('noAuthorizedModuleDescription');
  String get moduleTasksName => _text('moduleTasksName');
  String get moduleTasksDescription => _text('moduleTasksDescription');
  String get moduleInventoryName => _text('moduleInventoryName');
  String get moduleInventoryDescription => _text('moduleInventoryDescription');
  String get moduleIncidentName => _text('moduleIncidentName');
  String get moduleIncidentDescription => _text('moduleIncidentDescription');
  String get moduleUserManagementName => _text('moduleUserManagementName');
  String get moduleUserManagementDescription => _text('moduleUserManagementDescription');
  String get moduleNewsName => _text('moduleNewsName');
  String get moduleNewsDescription => _text('moduleNewsDescription');
  String get moduleCourrierName => _text('moduleCourrierName');
  String get moduleCourrierDescription => _text('moduleCourrierDescription');
  String get profile => _text('profile');
  String get profileUnavailable => _text('profileUnavailable');
  String get profileUnavailableDescription => _text('profileUnavailableDescription');
  String get connectedAgentInformation => _text('connectedAgentInformation');
  String get agentInformation => _text('agentInformation');
  String get noFields => _text('noFields');
  String get noProfileFieldsAvailable => _text('noProfileFieldsAvailable');
  String get refreshProfile => _text('refreshProfile');
  String get loadingProfile => _text('loadingProfile');
  String get unableToLoadProfile => _text('unableToLoadProfile');
  String get enableNotifications => _text('enableNotifications');
  String get notificationsEnabled => _text('notificationsEnabled');
  String get notificationPermissionNotGranted => _text('notificationPermissionNotGranted');
  String get unableToEnableNotifications => _text('unableToEnableNotifications');
  String get webPushNotConfigured => _text('webPushNotConfigured');
  String get webPushNotConfiguredDescription => _text('webPushNotConfiguredDescription');
  String get webPushNotConfiguredAction => _text('webPushNotConfiguredAction');
  String get disableNotifications => _text('disableNotifications');
  String get notificationsBlocked => _text('notificationsBlocked');
  String notificationsEnabledForPlatform(Object? platform) => _format('notificationsEnabledForPlatform', {'platform': platform});
  String get notificationsProvisionallyEnabled => _text('notificationsProvisionallyEnabled');
  String notificationsBlockedForPlatform(Object? platform) => _format('notificationsBlockedForPlatform', {'platform': platform});
  String get allowNotificationsPrompt => _text('allowNotificationsPrompt');
  String get disableNotificationsWindows => _text('disableNotificationsWindows');
  String get disableNotificationsMac => _text('disableNotificationsMac');
  String get disableNotificationsWeb => _text('disableNotificationsWeb');
  String get disableNotificationsDevice => _text('disableNotificationsDevice');
  String get blockedNotificationsWindows => _text('blockedNotificationsWindows');
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
  String get incidentOperationsDescription => _text('incidentOperationsDescription');
  String get incidentSupervision => _text('incidentSupervision');
  String get incidentSupervisionDescription => _text('incidentSupervisionDescription');
  String get newIncident => _text('newIncident');
  String get newSupportIncident => _text('newSupportIncident');
  String get submitSupportTicket => _text('submitSupportTicket');
  String get submitTicket => _text('submitTicket');
  String get submitting => _text('submitting');
  String get createIncidentManagerDescription => _text('createIncidentManagerDescription');
  String get createIncidentUserDescription => _text('createIncidentUserDescription');
  String get readOnlyIncidentAccess => _text('readOnlyIncidentAccess');
  String get onlyUsersAndManagersCreateIncidents => _text('onlyUsersAndManagersCreateIncidents');
  String get titleExampleEmailAccess => _text('titleExampleEmailAccess');
  String get shortDescription => _text('shortDescription');
  String get describeIssue => _text('describeIssue');
  String get describeIssueAndWork => _text('describeIssueAndWork');
  String get affectedItService => _text('affectedItService');
  String get selectAffectedService => _text('selectAffectedService');
  String get thisIssueBlocksMyWork => _text('thisIssueBlocksMyWork');
  String get blockingWorkDescription => _text('blockingWorkDescription');
  String get managerCategorization => _text('managerCategorization');
  String get managerCategorizationDescription => _text('managerCategorizationDescription');
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
  String get completeCategoryImpactUrgency => _text('completeCategoryImpactUrgency');
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
  String get operationalQueueDescription => _text('operationalQueueDescription');
  String get noActiveIncident => _text('noActiveIncident');
  String get newOperationalTicketsWillAppearHere => _text('newOperationalTicketsWillAppearHere');
  String get myAssignedTickets => _text('myAssignedTickets');
  String get myAssignedTicketsDescription => _text('myAssignedTicketsDescription');
  String get ticketsByPriority => _text('ticketsByPriority');
  String get ticketsByStatus => _text('ticketsByStatus');
  String get ticketsByAffectedService => _text('ticketsByAffectedService');
  String get agingTickets => _text('agingTickets');
  String get ticket => _text('ticket');
  String get priority => _text('priority');
  String get age => _text('age');
  String get createdAtColumn => _text('createdAtColumn');
  String get openTicketsQueueDescription => _text('openTicketsQueueDescription');
  String get unassignedTicketsQueueDescription => _text('unassignedTicketsQueueDescription');
  String get assignedToMeQueueDescription => _text('assignedToMeQueueDescription');
  String get solvedTicketsQueueDescription => _text('solvedTicketsQueueDescription');
  String get noTicketsFound => _text('noTicketsFound');
  String get queueEmpty => _text('queueEmpty');
  String get tryAnotherSearchOrStatus => _text('tryAnotherSearchOrStatus');
  String thereIsNoQueueItem(Object? queueLabel) => _format('thereIsNoQueueItem', {'queueLabel': queueLabel});
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
  String get selectResolutionCodeBeforeSolved => _text('selectResolutionCodeBeforeSolved');
  String get selectResolutionCodeBeforeClosing => _text('selectResolutionCodeBeforeClosing');
  String get closedAt => _text('closedAt');
  String get archiveEligible => _text('archiveEligible');
  String get internalNotes => _text('internalNotes');
  String get addNote => _text('addNote');
  String get addInternalNoteHint => _text('addInternalNoteHint');
  String get adding => _text('adding');
  String get internalNoteAdded => _text('internalNoteAdded');
  String get workflowStepSubmitTicket => _text('workflowStepSubmitTicket');
  String get workflowStepSubmitTicketDescription => _text('workflowStepSubmitTicketDescription');
  String get workflowStepCategorizeTicket => _text('workflowStepCategorizeTicket');
  String get workflowStepCategorizeOpenDescription => _text('workflowStepCategorizeOpenDescription');
  String get workflowStepCategorizeActiveDescription => _text('workflowStepCategorizeActiveDescription');
  String get workflowStepAssignTicket => _text('workflowStepAssignTicket');
  String get workflowStepAssignTicketDescription => _text('workflowStepAssignTicketDescription');
  String get workflowStepSolveTicket => _text('workflowStepSolveTicket');
  String get workflowStepSolveTicketDescription => _text('workflowStepSolveTicketDescription');
  String get workflowStepCloseTicket => _text('workflowStepCloseTicket');
  String get workflowStepCloseTicketDescription => _text('workflowStepCloseTicketDescription');
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
  String get selectServiceCategoryImpactUrgency => _text('selectServiceCategoryImpactUrgency');
  String get selectItStaffAssignee => _text('selectItStaffAssignee');
  String get enterResolutionSummaryBeforeSolved => _text('enterResolutionSummaryBeforeSolved');
  String get enterResolutionSummaryBeforeClosing => _text('enterResolutionSummaryBeforeClosing');
  String get myIncidents => _text('myIncidents');
  String get createAndFollowIncidents => _text('createAndFollowIncidents');
  String get activeIncidents => _text('activeIncidents');
  String get closedAndArchived => _text('closedAndArchived');
  String get noActiveIncidentUserDescription => _text('noActiveIncidentUserDescription');
  String get noClosedIncident => _text('noClosedIncident');
  String get closedAndArchivedDescription => _text('closedAndArchivedDescription');
  String get loadingIncidents => _text('loadingIncidents');
  String get unableToLoadIncidents => _text('unableToLoadIncidents');
  String get incidentAccessUnavailable => _text('incidentAccessUnavailable');
  String get incidentAccessUnavailableDescription => _text('incidentAccessUnavailableDescription');
  String get noIncidentDashboardAccess => _text('noIncidentDashboardAccess');
  String get loadingIncidentAccess => _text('loadingIncidentAccess');
  String get loadingIncidentDashboardAccess => _text('loadingIncidentDashboardAccess');
  String get unableToLoadIncidentAccess => _text('unableToLoadIncidentAccess');
  String get unableToLoadIncidentDashboardAccess => _text('unableToLoadIncidentDashboardAccess');
  String get incidentParameters => _text('incidentParameters');
  String get incidentParametersDescription => _text('incidentParametersDescription');
  String get addItService => _text('addItService');
  String get addCategory => _text('addCategory');
  String get addResolutionCode => _text('addResolutionCode');
  String get editResolutionCode => _text('editResolutionCode');
  String get noResolutionCodes => _text('noResolutionCodes');
  String get resolutionCodeIdentifier => _text('resolutionCodeIdentifier');
  String get resolutionCodeIdentifierHint => _text('resolutionCodeIdentifierHint');
  String get resolutionCodeLabelEnglish => _text('resolutionCodeLabelEnglish');
  String get resolutionCodeLabelFrench => _text('resolutionCodeLabelFrench');
  String get totalIncidentsThisMonth => _text('totalIncidentsThisMonth');
  String get averageResolutionTime => _text('averageResolutionTime');
  String get monthlyIncidentTrend => _text('monthlyIncidentTrend');
  String get ticketsByService => _text('ticketsByService');
  String get ticketsByCategory => _text('ticketsByCategory');
  String get ticketsByDepartment => _text('ticketsByDepartment');
  String get recentCriticalTickets => _text('recentCriticalTickets');
  String get recentCriticalTicketsDescription => _text('recentCriticalTicketsDescription');
  String get criticalTicketsWillAppearHere => _text('criticalTicketsWillAppearHere');
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
  String get incidentPriorityUnprioritized => _text('incidentPriorityUnprioritized');
  String get incidentRoleNoAccess => _text('incidentRoleNoAccess');
  String get incidentRoleUser => _text('incidentRoleUser');
  String get incidentRoleManager => _text('incidentRoleManager');
  String get incidentRoleAdmin => _text('incidentRoleAdmin');
  String get userManagement => _text('userManagement');
  String get manageDepartmentsServicesBureauxAgents => _text('manageDepartmentsServicesBureauxAgents');
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
  String totalArticles(Object? count) => _format('totalArticles', {'count': count});
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
  String get taskDetails => _text('taskDetails');
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
  String uploadFailed(Object? error) => _format('uploadFailed', {'error': error});
  String get uploadedSuccessfully => _text('uploadedSuccessfully');
  String get deleteTask => _text('deleteTask');
  String deleteTaskConfirmation(Object? taskLabel) => _format('deleteTaskConfirmation', {'taskLabel': taskLabel});
  String get taskDeleted => _text('taskDeleted');
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
  String get informationSystemsDepartment => _text('informationSystemsDepartment');
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
  String get refundRequestsWillAppearHere => _text('refundRequestsWillAppearHere');
  String get addDependantsToRequestVouchers => _text('addDependantsToRequestVouchers');
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
  String capacityPeople(Object? count) => _format('capacityPeople', {'count': count});
  String get roomLocation => _text('roomLocation');
  String get closeDialog => _text('closeDialog');
  String unableToLoadSchedule(Object? error) => _format('unableToLoadSchedule', {'error': error});
  String get dashboard => _text('dashboard');
  String get dashboardTitle => _text('dashboardTitle');
  String get mainDashboard => _text('mainDashboard');
  String get loadingStatistics => _text('loadingStatistics');
  String get errorLoadingData => _text('errorLoadingData');
  String get failedToLoadDashboardStatistics => _text('failedToLoadDashboardStatistics');
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
  String get permissionManagerDescription => _text('permissionManagerDescription');
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
  String get searchByNameEmailOrMatricule => _text('searchByNameEmailOrMatricule');
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
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

const _supportedLanguageCodes = <String>{
  'en',
  'fr',
};

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
    'homeNewsDescription': "Published posts from authorized company communicators.",
    'companyNews': "Company news",
    'noCompanyNewsYet': "No company news yet",
    'publishedInformationWillAppearHere': "Published information will appear here.",
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
    'noAuthorizedModuleDescription': "No module is authorized for this user. Please contact the administrator.",
    'moduleTasksName': "Tasks",
    'moduleTasksDescription': "Task and activity reporting",
    'moduleInventoryName': "Inventory",
    'moduleInventoryDescription': "Manage organizational stock and items",
    'moduleIncidentName': "Support",
    'moduleIncidentDescription': "IT incident and support management",
    'moduleUserManagementName': "User Management",
    'moduleUserManagementDescription': "Manage departments, services, offices, agents, and modules",
    'moduleNewsName': "News",
    'moduleNewsDescription': "Company communication and publishing",
    'moduleCourrierName': "Mail",
    'moduleCourrierDescription': "Official mail and routing",
    'profile': "Profile",
    'profileUnavailable': "Profile unavailable",
    'profileUnavailableDescription': "No agent data is cached on this device for the current session.",
    'connectedAgentInformation': "Connected agent information",
    'agentInformation': "Agent Information",
    'noFields': "No fields",
    'noProfileFieldsAvailable': "No profile fields available.",
    'refreshProfile': "Refresh Profile",
    'loadingProfile': "Loading profile...",
    'unableToLoadProfile': "Unable to load profile",
    'enableNotifications': "Enable notifications",
    'notificationsEnabled': "Notifications are enabled.",
    'notificationPermissionNotGranted': "Notification permission was not granted yet.",
    'unableToEnableNotifications': "Unable to enable notifications",
    'webPushNotConfigured': "Web push is not configured",
    'webPushNotConfiguredDescription': "Web push is not configured for this build. Rebuild with the Firebase Web Push VAPID key.",
    'webPushNotConfiguredAction': "Run or build the web app with --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_KEY, then try again.",
    'disableNotifications': "Disable notifications",
    'notificationsBlocked': "Notifications are blocked",
    'notificationsEnabledForPlatform': "Notifications are enabled for this {platform}.",
    'notificationsProvisionallyEnabled': "Notifications are provisionally enabled.",
    'notificationsBlockedForPlatform': "Notifications are blocked for this {platform}.",
    'allowNotificationsPrompt': "Check this box to allow ARPTC Connect to send notifications.",
    'disableNotificationsWindows': "Notification permissions are controlled by Windows and your browser.\n\nTo disable them, open the browser site settings for this app and block notifications. You can also open Windows Settings > System > Notifications, then disable notifications for the installed ARPTC Connect app, Chrome, or Edge.",
    'disableNotificationsMac': "Notification permissions are controlled by macOS and your browser.\n\nTo disable them, open System Settings > Notifications, then disable notifications for ARPTC Connect or Safari. You can also use Safari > Settings > Websites > Notifications to block this app domain.",
    'disableNotificationsWeb': "Notification permissions are controlled by your browser. Use the site settings in your browser to block notifications for this app.",
    'disableNotificationsDevice': "Notification permissions are controlled by this device. Use your system notification settings to disable notifications for ARPTC Connect.",
    'blockedNotificationsWindows': "Windows or your browser has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOn Windows, open Settings > System > Notifications and make sure notifications are enabled for the installed ARPTC Connect app, Google Chrome, or Microsoft Edge.\n\nThen open your browser site settings for this app domain and set Notifications to Allow. In Chrome or Edge, this is usually Settings > Privacy and security > Site settings > Notifications. After that, reopen the installed app and enable notifications again from this profile page.",
    'blockedNotificationsMac': "Safari or macOS has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOn macOS, open System Settings > Notifications, then select ARPTC Connect or Safari and allow notifications.\n\nIf it is still blocked, open Safari > Settings > Websites > Notifications, find this app domain, then change it to Allow or remove the saved decision. After that, reopen the installed app and enable notifications again from this profile page.",
    'blockedNotificationsWeb': "Your browser has blocked notifications for this app, so ARPTC Connect cannot show the permission prompt again.\n\nOpen the browser site settings for this app domain, set Notifications to Allow, then reopen the app and enable notifications again from this profile page.",
    'blockedNotificationsDevice': "This device has blocked notifications for ARPTC Connect.\n\nOpen your system notification settings, allow notifications for ARPTC Connect, then return to this profile page and enable notifications again.",
    'notifications': "Notifications",
    'noNotificationsYet': "No notifications yet",
    'noNotificationsDescription': "Notifications about incidents, news, and workflows will appear here.",
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
    'incidentOperationsDescription': "Live operational view for IT triage and resolution.",
    'incidentSupervision': "Incident Supervision",
    'incidentSupervisionDescription': "Read-only global visibility across active, closed, and archived incidents.",
    'newIncident': "New Incident",
    'newSupportIncident': "New Support Incident",
    'submitSupportTicket': "Submit a Support Ticket",
    'submitTicket': "Submit ticket",
    'submitting': "Submitting...",
    'createIncidentManagerDescription': "Create and categorize an incident in one pass.",
    'createIncidentUserDescription': "Tell IT what is blocked. The support team will categorize the rest.",
    'readOnlyIncidentAccess': "Read-only incident access",
    'onlyUsersAndManagersCreateIncidents': "Only users and managers can create incident tickets.",
    'titleExampleEmailAccess': "Example: Unable to access email",
    'shortDescription': "Short description",
    'describeIssue': "Describe the issue",
    'describeIssueAndWork': "Describe what happened and what you were trying to do",
    'affectedItService': "Affected IT service",
    'selectAffectedService': "Select the service you cannot reach",
    'thisIssueBlocksMyWork': "This issue blocks my work",
    'blockingWorkDescription': "Turn this on if you cannot continue your normal work.",
    'managerCategorization': "Manager categorization",
    'managerCategorizationDescription': "Managers create the first two workflow steps together: submission and categorization.",
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
    'completeCategoryImpactUrgency': "Complete category, impact, and urgency before submitting.",
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
    'operationalQueueDescription': "Active incidents sorted by priority first, then oldest first.",
    'noActiveIncident': "No active incident",
    'newOperationalTicketsWillAppearHere': "New operational tickets will appear here.",
    'myAssignedTickets': "My Assigned Tickets",
    'myAssignedTicketsDescription': "Active incidents currently assigned to you.",
    'ticketsByPriority': "Tickets by Priority",
    'ticketsByStatus': "Tickets by Status",
    'ticketsByAffectedService': "Tickets by Affected Service",
    'agingTickets': "Aging Tickets",
    'ticket': "Ticket",
    'priority': "Priority",
    'age': "Age",
    'createdAtColumn': "Created at",
    'openTicketsQueueDescription': "Tickets submitted by users that have not been categorized yet.",
    'unassignedTicketsQueueDescription': "Categorized tickets waiting for an IT staff assignment.",
    'assignedToMeQueueDescription': "Active tickets assigned to the current manager.",
    'solvedTicketsQueueDescription': "Solved tickets waiting to be marked closed.",
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
    'selectResolutionCodeBeforeSolved': "Select a resolution code before marking the ticket solved.",
    'selectResolutionCodeBeforeClosing': "Select a resolution code before closing the ticket.",
    'closedAt': "Closed at",
    'archiveEligible': "Archive eligible",
    'internalNotes': "Internal notes",
    'addNote': "Add note",
    'addInternalNoteHint': "Only IT staff can see internal notes",
    'adding': "Adding...",
    'internalNoteAdded': "Internal note added.",
    'workflowStepSubmitTicket': "Step 1: Submit ticket",
    'workflowStepSubmitTicketDescription': "The requester provides basic details.",
    'workflowStepCategorizeTicket': "Step 2: Categorize ticket",
    'workflowStepCategorizeOpenDescription': "Complete triage and move this ticket to in progress.",
    'workflowStepCategorizeActiveDescription': "Operational categorization can still be updated while active.",
    'workflowStepAssignTicket': "Step 3: Assign ticket",
    'workflowStepAssignTicketDescription': "Assign the incident to IT staff. The ticket status does not change here.",
    'workflowStepSolveTicket': "Step 4: Solve ticket",
    'workflowStepSolveTicketDescription': "Record the resolution summary before closing.",
    'workflowStepCloseTicket': "Step 5: Close ticket",
    'workflowStepCloseTicketDescription': "Close the ticket once the solution is validated.",
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
    'cancelTicketWarning': "This should only be used when the incident is a false alarm. The ticket will leave the operational queue.",
    'keepTicket': "Keep ticket",
    'cancelling': "Cancelling...",
    'ticketCancelled': "Ticket cancelled.",
    'selectServiceCategoryImpactUrgency': "Select affected service, category, impact, and urgency first.",
    'selectItStaffAssignee': "Select the IT staff member who will solve the incident.",
    'enterResolutionSummaryBeforeSolved': "Enter a resolution summary before marking solved.",
    'enterResolutionSummaryBeforeClosing': "Enter a resolution summary before closing.",
    'myIncidents': "My incidents",
    'createAndFollowIncidents': "Create and follow your IT incidents",
    'activeIncidents': "Active",
    'closedAndArchived': "Closed & archived",
    'noActiveIncidentUserDescription': "Your open incidents will appear here.",
    'noClosedIncident': "No closed incident",
    'closedAndArchivedDescription': "Closed and archived incidents will appear here.",
    'loadingIncidents': "Loading incidents...",
    'unableToLoadIncidents': "Unable to load incidents",
    'incidentAccessUnavailable': "Incident access unavailable",
    'incidentAccessUnavailableDescription': "No Incident Management permission is assigned to this agent.",
    'noIncidentDashboardAccess': "You do not have access to the Incident Management dashboard.",
    'loadingIncidentAccess': "Loading incident access...",
    'loadingIncidentDashboardAccess': "Loading incident dashboard access...",
    'unableToLoadIncidentAccess': "Unable to load incident access",
    'unableToLoadIncidentDashboardAccess': "Unable to load incident dashboard access",
    'incidentParameters': "Incident Parameters",
    'incidentParametersDescription': "Configure IT services, categories, and resolution codes used by support tickets.",
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
    'recentCriticalTicketsDescription': "Latest P1 and P2 incidents. This list is read-only for admins.",
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
    'manageDepartmentsServicesBureauxAgents': "Manage departments, services, offices, modules, and agents.",
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
    'tasksDescription': "Manage intervention tickets",
    'newTask': "New Task",
    'taskDetails': "Task Details",
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
    'deleteTask': "Delete task",
    'deleteTaskConfirmation': "Do you really want to delete \"{taskLabel}\"?",
    'taskDeleted': "Task deleted",
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
    'permissionAdminDescription': "Can supervise the module according to the configured access model.",
    'permissionManagerDescription': "Can manage operational work in the module.",
    'permissionUserDescription': "Can use the module for their own work.",
    'permissionNoneDescription': "No access to this module.",
    'requiredField': "This field is required",
    'enterTitle': "Enter a title",
    'enterShortDescription': "Enter a short description",
    'enterName': "Enter a name",
    'enterEmail': "Enter an email",
    'invalidEmail': "Enter a valid email",
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
    'homeNewsDescription': "Publications des communicateurs autorisés de l'entreprise.",
    'companyNews': "Actualités de l'entreprise",
    'noCompanyNewsYet': "Aucune actualité de l'entreprise pour le moment",
    'publishedInformationWillAppearHere': "Les informations publiées apparaîtront ici.",
    'loadingCompanyNews': "Chargement des actualités de l'entreprise...",
    'unableToLoadCompanyNews': "Impossible de charger les actualités de l'entreprise",
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
    'noAuthorizedModuleDescription': "Aucun module n'est autorisé pour cet utilisateur. Veuillez contacter l'administrateur.",
    'moduleTasksName': "Tâches",
    'moduleTasksDescription': "Rapport des tâches et activités",
    'moduleInventoryName': "Inventaire",
    'moduleInventoryDescription': "Gérer les stocks et les articles de l'organisation",
    'moduleIncidentName': "Support",
    'moduleIncidentDescription': "Gestion des incidents IT et du support",
    'moduleUserManagementName': "Gestion des utilisateurs",
    'moduleUserManagementDescription': "Gérer les départements, services, bureaux, agents et modules",
    'moduleNewsName': "Actualités",
    'moduleNewsDescription': "Communication et publication internes",
    'moduleCourrierName': "Courrier",
    'moduleCourrierDescription': "Courrier officiel et circuit de transmission",
    'profile': "Profil",
    'profileUnavailable': "Profil indisponible",
    'profileUnavailableDescription': "Aucune donnée d'agent n'est mise en cache sur cet appareil pour la session actuelle.",
    'connectedAgentInformation': "Informations de l'agent connecté",
    'agentInformation': "Informations de l'agent",
    'noFields': "Aucun champ",
    'noProfileFieldsAvailable': "Aucun champ de profil disponible.",
    'refreshProfile': "Actualiser le profil",
    'loadingProfile': "Chargement du profil...",
    'unableToLoadProfile': "Impossible de charger le profil",
    'enableNotifications': "Activer les notifications",
    'notificationsEnabled': "Les notifications sont activées.",
    'notificationPermissionNotGranted': "L'autorisation de notification n'a pas encore été accordée.",
    'unableToEnableNotifications': "Impossible d'activer les notifications",
    'webPushNotConfigured': "Web push n'est pas configuré",
    'webPushNotConfiguredDescription': "Web push n'est pas configuré pour cette version. Reconstruisez l'application avec la clé VAPID Firebase Web Push.",
    'webPushNotConfiguredAction': "Lancez ou construisez l'application web avec --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=VOTRE_CLE_PUBLIQUE, puis réessayez.",
    'disableNotifications': "Désactiver les notifications",
    'notificationsBlocked': "Les notifications sont bloquées",
    'notificationsEnabledForPlatform': "Les notifications sont activées pour ce {platform}.",
    'notificationsProvisionallyEnabled': "Les notifications sont activées provisoirement.",
    'notificationsBlockedForPlatform': "Les notifications sont bloquées pour ce {platform}.",
    'allowNotificationsPrompt': "Cochez cette case pour autoriser ARPTC Connect à envoyer des notifications.",
    'disableNotificationsWindows': "Les autorisations de notification sont contrôlées par Windows et votre navigateur.\n\nPour les désactiver, ouvrez les paramètres du site dans le navigateur pour cette application et bloquez les notifications. Vous pouvez aussi ouvrir Paramètres Windows > Système > Notifications, puis désactiver les notifications pour l'application ARPTC Connect installée, Chrome ou Edge.",
    'disableNotificationsMac': "Les autorisations de notification sont contrôlées par macOS et votre navigateur.\n\nPour les désactiver, ouvrez Réglages Système > Notifications, puis désactivez les notifications pour ARPTC Connect ou Safari. Vous pouvez aussi utiliser Safari > Réglages > Sites web > Notifications pour bloquer le domaine de cette application.",
    'disableNotificationsWeb': "Les autorisations de notification sont contrôlées par votre navigateur. Utilisez les paramètres du site dans votre navigateur pour bloquer les notifications de cette application.",
    'disableNotificationsDevice': "Les autorisations de notification sont contrôlées par cet appareil. Utilisez les paramètres système de notification pour désactiver les notifications d'ARPTC Connect.",
    'blockedNotificationsWindows': "Windows ou votre navigateur a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nSous Windows, ouvrez Paramètres > Système > Notifications et assurez-vous que les notifications sont activées pour l'application ARPTC Connect installée, Google Chrome ou Microsoft Edge.\n\nOuvrez ensuite les paramètres du site de ce domaine dans votre navigateur et définissez Notifications sur Autoriser. Dans Chrome ou Edge, cela se trouve généralement dans Paramètres > Confidentialité et sécurité > Paramètres des sites > Notifications. Ensuite, rouvrez l'application installée et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsMac': "Safari ou macOS a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nSous macOS, ouvrez Réglages Système > Notifications, puis sélectionnez ARPTC Connect ou Safari et autorisez les notifications.\n\nSi elles restent bloquées, ouvrez Safari > Réglages > Sites web > Notifications, trouvez le domaine de cette application, puis passez-le sur Autoriser ou supprimez la décision enregistrée. Ensuite, rouvrez l'application installée et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsWeb': "Votre navigateur a bloqué les notifications pour cette application. ARPTC Connect ne peut donc plus afficher la demande d'autorisation.\n\nOuvrez les paramètres du site pour ce domaine, définissez Notifications sur Autoriser, puis rouvrez l'application et activez de nouveau les notifications depuis cette page de profil.",
    'blockedNotificationsDevice': "Cet appareil a bloqué les notifications pour ARPTC Connect.\n\nOuvrez les paramètres système de notification, autorisez les notifications pour ARPTC Connect, puis revenez sur cette page de profil et activez-les de nouveau.",
    'notifications': "Notifications",
    'noNotificationsYet': "Aucune notification pour le moment",
    'noNotificationsDescription': "Les notifications concernant les incidents, les actualités et les workflows apparaîtront ici.",
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
    'incidentOperationsDescription': "Vue opérationnelle en temps réel pour le triage et la résolution IT.",
    'incidentSupervision': "Supervision des incidents",
    'incidentSupervisionDescription': "Visibilité globale en lecture seule sur les incidents actifs, fermés et archivés.",
    'newIncident': "Nouvel incident",
    'newSupportIncident': "Nouvel incident support",
    'submitSupportTicket': "Soumettre un ticket support",
    'submitTicket': "Soumettre le ticket",
    'submitting': "Soumission...",
    'createIncidentManagerDescription': "Créer et catégoriser un incident en une seule étape.",
    'createIncidentUserDescription': "Indiquez à l'IT ce qui est bloqué. L'équipe support catégorisera le reste.",
    'readOnlyIncidentAccess': "Accès incident en lecture seule",
    'onlyUsersAndManagersCreateIncidents': "Seuls les utilisateurs et les managers peuvent créer des tickets d'incident.",
    'titleExampleEmailAccess': "Exemple : Impossible d'accéder à l'e-mail",
    'shortDescription': "Brève description",
    'describeIssue': "Décrivez le problème",
    'describeIssueAndWork': "Décrivez ce qui s'est passé et ce que vous essayiez de faire",
    'affectedItService': "Service IT affecté",
    'selectAffectedService': "Sélectionnez le service que vous ne parvenez pas à joindre",
    'thisIssueBlocksMyWork': "Ce problème bloque mon travail",
    'blockingWorkDescription': "Activez cette option si vous ne pouvez pas poursuivre votre travail normal.",
    'managerCategorization': "Catégorisation manager",
    'managerCategorizationDescription': "Les managers effectuent ensemble les deux premières étapes du workflow : soumission et catégorisation.",
    'affectedAgent': "Agent affecté",
    'searchAffectedAgentHint': "Laissez vide pour créer le ticket pour vous-même",
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
    'completeCategoryImpactUrgency': "Complétez la catégorie, l'impact et l'urgence avant de soumettre.",
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
    'operationalQueueDescription': "Incidents actifs triés d'abord par priorité, puis du plus ancien au plus récent.",
    'noActiveIncident': "Aucun incident actif",
    'newOperationalTicketsWillAppearHere': "Les nouveaux tickets opérationnels apparaîtront ici.",
    'myAssignedTickets': "Mes tickets assignés",
    'myAssignedTicketsDescription': "Incidents actifs actuellement assignés à vous.",
    'ticketsByPriority': "Tickets par priorité",
    'ticketsByStatus': "Tickets par statut",
    'ticketsByAffectedService': "Tickets par service affecté",
    'agingTickets': "Vieillissement des tickets",
    'ticket': "Ticket",
    'priority': "Priorité",
    'age': "Âge",
    'createdAtColumn': "Créé le",
    'openTicketsQueueDescription': "Tickets soumis par les utilisateurs et non encore catégorisés.",
    'unassignedTicketsQueueDescription': "Tickets catégorisés en attente d'assignation à un membre IT.",
    'assignedToMeQueueDescription': "Tickets actifs assignés au manager actuel.",
    'solvedTicketsQueueDescription': "Tickets résolus en attente de clôture.",
    'noTicketsFound': "Aucun ticket trouvé",
    'queueEmpty': "Cette file est vide.",
    'tryAnotherSearchOrStatus': "Essayez une autre recherche ou un autre filtre de statut.",
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
    'selectResolutionCodeBeforeSolved': "Sélectionnez un code de résolution avant de marquer le ticket comme résolu.",
    'selectResolutionCodeBeforeClosing': "Sélectionnez un code de résolution avant de fermer le ticket.",
    'closedAt': "Fermé le",
    'archiveEligible': "Archivable le",
    'internalNotes': "Notes internes",
    'addNote': "Ajouter une note",
    'addInternalNoteHint': "Seul le personnel IT peut voir les notes internes",
    'adding': "Ajout...",
    'internalNoteAdded': "Note interne ajoutée.",
    'workflowStepSubmitTicket': "Étape 1 : Soumettre le ticket",
    'workflowStepSubmitTicketDescription': "Le demandeur fournit les informations de base.",
    'workflowStepCategorizeTicket': "Étape 2 : Catégoriser le ticket",
    'workflowStepCategorizeOpenDescription': "Complétez le triage et passez ce ticket en cours de traitement.",
    'workflowStepCategorizeActiveDescription': "La catégorisation opérationnelle peut encore être mise à jour tant que le ticket est actif.",
    'workflowStepAssignTicket': "Étape 3 : Assigner le ticket",
    'workflowStepAssignTicketDescription': "Assignez l'incident au personnel IT. Le statut du ticket ne change pas ici.",
    'workflowStepSolveTicket': "Étape 4 : Résoudre le ticket",
    'workflowStepSolveTicketDescription': "Enregistrez le résumé de résolution avant la clôture.",
    'workflowStepCloseTicket': "Étape 5 : Fermer le ticket",
    'workflowStepCloseTicketDescription': "Fermez le ticket une fois la solution validée.",
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
    'cancelTicketWarning': "Cette action ne doit être utilisée que si l'incident est une fausse alerte. Le ticket quittera la file opérationnelle.",
    'keepTicket': "Conserver le ticket",
    'cancelling': "Annulation...",
    'ticketCancelled': "Ticket annulé.",
    'selectServiceCategoryImpactUrgency': "Sélectionnez d'abord le service affecté, la catégorie, l'impact et l'urgence.",
    'selectItStaffAssignee': "Sélectionnez le membre IT qui résoudra l'incident.",
    'enterResolutionSummaryBeforeSolved': "Saisissez un résumé de résolution avant de marquer comme résolu.",
    'enterResolutionSummaryBeforeClosing': "Saisissez un résumé de résolution avant de fermer.",
    'myIncidents': "Mes incidents",
    'createAndFollowIncidents': "Créez et suivez vos incidents IT",
    'activeIncidents': "Actifs",
    'closedAndArchived': "Fermés et archivés",
    'noActiveIncidentUserDescription': "Vos incidents ouverts apparaîtront ici.",
    'noClosedIncident': "Aucun incident fermé",
    'closedAndArchivedDescription': "Les incidents fermés et archivés apparaîtront ici.",
    'loadingIncidents': "Chargement des incidents...",
    'unableToLoadIncidents': "Impossible de charger les incidents",
    'incidentAccessUnavailable': "Accès aux incidents indisponible",
    'incidentAccessUnavailableDescription': "Aucune permission de Gestion des incidents n'est attribuée à cet agent.",
    'noIncidentDashboardAccess': "Vous n'avez pas accès au tableau de bord de Gestion des incidents.",
    'loadingIncidentAccess': "Chargement des accès aux incidents...",
    'loadingIncidentDashboardAccess': "Chargement des accès au tableau de bord des incidents...",
    'unableToLoadIncidentAccess': "Impossible de charger les accès aux incidents",
    'unableToLoadIncidentDashboardAccess': "Impossible de charger les accès au tableau de bord des incidents",
    'incidentParameters': "Paramètres des incidents",
    'incidentParametersDescription': "Configurez les services IT, les catégories et les codes de résolution utilisés par les tickets support.",
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
    'recentCriticalTicketsDescription': "Derniers incidents P1 et P2. Cette liste est en lecture seule pour les admins.",
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
    'manageDepartmentsServicesBureauxAgents': "Gérer les départements, services, bureaux, modules et agents.",
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
    'tasksDescription': "Gestion des tickets d'intervention",
    'newTask': "Nouvelle tâche",
    'taskDetails': "Détails de la tâche",
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
    'deleteTask': "Supprimer la tâche",
    'deleteTaskConfirmation': "Voulez-vous vraiment supprimer \"{taskLabel}\" ?",
    'taskDeleted': "Tâche supprimée",
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
    'refundRequestsWillAppearHere': "Vos demandes de remboursement apparaîtront ici",
    'addDependantsToRequestVouchers': "Ajoutez vos dépendants pour demander des bons",
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
    'failedToLoadDashboardStatistics': "Échec du chargement des statistiques du tableau de bord",
    'dashboardDataDoesNotExist': "Les données du tableau de bord n'existent pas",
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
    'permissionAdminDescription': "Peut superviser le module selon le modèle d'accès configuré.",
    'permissionManagerDescription': "Peut gérer le travail opérationnel dans le module.",
    'permissionUserDescription': "Peut utiliser le module pour son propre travail.",
    'permissionNoneDescription': "Aucun accès à ce module.",
    'requiredField': "Ce champ est obligatoire",
    'enterTitle': "Saisissez un titre",
    'enterShortDescription': "Saisissez une brève description",
    'enterName': "Saisissez un nom",
    'enterEmail': "Saisissez un e-mail",
    'invalidEmail': "Saisissez un e-mail valide",
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
  },
};
