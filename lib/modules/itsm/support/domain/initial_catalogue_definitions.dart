import '../../shared/domain/itsm_common.dart';
import 'localized_value.dart';
import 'service_catalogue.dart';

abstract final class InitialCatalogueDefinitions {
  static const requiredCodes = {
    'report_it_incident',
    'technical_assistance',
    'computer_request',
    'equipment_replacement',
    'equipment_repair',
    'asset_configuration',
    'software_installation',
    'software_licence',
    'account_access',
    'vpn_network_access',
    'equipment_return_transfer',
    'change_request',
    'security_exception',
    'access_correction_revocation',
  };

  static List<ServiceCatalogueItem> build({
    required DateTime createdAt,
    required String createdBy,
  }) {
    final definitions = [
      _Seed(
        code: 'report_it_incident',
        nameEn: 'Report an IT incident',
        nameFr: 'Signaler un incident informatique',
        descriptionEn:
            'Report an unexpected interruption or degradation of an IT service.',
        descriptionFr:
            'Signaler une interruption ou une degradation inattendue '
            "d'un service informatique.",
        category: 'support',
        categoryEn: 'Support',
        categoryFr: 'Assistance',
        icon: 'report_problem',
        workflowId: 'incident-intake',
        groupId: 'service-desk',
        slaId: 'incident-standard',
        fields: [_titleField(), _descriptionField(), _blockingField()],
      ),
      _Seed(
        code: 'technical_assistance',
        nameEn: 'Request technical assistance',
        nameFr: 'Demander une assistance technique',
        descriptionEn:
            'Ask the service desk for help with an IT question or task.',
        descriptionFr:
            "Demander l'aide du centre de services pour une question ou "
            'une tache informatique.',
        category: 'support',
        categoryEn: 'Support',
        categoryFr: 'Assistance',
        icon: 'support_agent',
        workflowId: 'standard-request',
        groupId: 'service-desk',
        slaId: 'request-standard',
        fields: [_titleField(), _descriptionField()],
      ),
      _Seed(
        code: 'computer_request',
        nameEn: 'Request a computer',
        nameFr: 'Demander un ordinateur',
        descriptionEn:
            'Request a laptop or desktop computer for an eligible employee.',
        descriptionFr:
            'Demander un ordinateur portable ou fixe pour un agent eligible.',
        category: 'equipment',
        categoryEn: 'Equipment',
        categoryFr: 'Equipement',
        icon: 'computer',
        workflowId: 'asset-request',
        groupId: 'asset-management',
        slaId: 'asset-request',
        approvalPolicyId: 'manager-and-asset-approval',
        fields: [
          _choiceField(
            key: 'computerType',
            en: 'Computer type',
            fr: "Type d'ordinateur",
            values: const {
              'laptop': ('Laptop', 'Ordinateur portable'),
              'desktop': ('Desktop', 'Ordinateur fixe'),
            },
          ),
          _businessJustificationField(),
        ],
      ),
      _Seed(
        code: 'equipment_replacement',
        nameEn: 'Request equipment replacement',
        nameFr: "Demander le remplacement d'un equipement",
        descriptionEn:
            'Request replacement of assigned equipment that is unsuitable.',
        descriptionFr:
            "Demander le remplacement d'un equipement affecte devenu inadapte.",
        category: 'equipment',
        categoryEn: 'Equipment',
        categoryFr: 'Equipement',
        icon: 'swap_horiz',
        workflowId: 'asset-replacement',
        groupId: 'asset-management',
        slaId: 'asset-request',
        approvalPolicyId: 'manager-and-asset-approval',
        fields: [
          _assetField(),
          _businessJustificationField(),
        ],
        documents: [_evidenceDocument()],
      ),
      _Seed(
        code: 'equipment_repair',
        nameEn: 'Request repair',
        nameFr: 'Demander une reparation',
        descriptionEn: 'Request diagnosis and repair of assigned equipment.',
        descriptionFr:
            "Demander le diagnostic et la reparation d'un equipement affecte.",
        category: 'equipment',
        categoryEn: 'Equipment',
        categoryFr: 'Equipement',
        icon: 'build',
        workflowId: 'asset-repair',
        groupId: 'technical-support',
        slaId: 'asset-repair',
        fields: [_assetField(), _descriptionField()],
        documents: [_evidenceDocument(required: false)],
      ),
      _Seed(
        code: 'asset_configuration',
        nameEn: 'Request asset configuration',
        nameFr: "Demander la configuration d'un equipement",
        descriptionEn:
            'Request an approved configuration change on assigned equipment.',
        descriptionFr:
            'Demander une modification de configuration approuvee sur '
            'un equipement affecte.',
        category: 'equipment',
        categoryEn: 'Equipment',
        categoryFr: 'Equipement',
        icon: 'settings_suggest',
        workflowId: 'asset-configuration',
        groupId: 'technical-support',
        slaId: 'request-standard',
        fields: [_assetField(), _descriptionField()],
      ),
      _Seed(
        code: 'software_installation',
        nameEn: 'Request software installation',
        nameFr: "Demander l'installation d'un logiciel",
        descriptionEn:
            'Request installation of approved software on an assigned device.',
        descriptionFr:
            "Demander l'installation d'un logiciel approuve sur un appareil "
            'affecte.',
        category: 'software',
        categoryEn: 'Software',
        categoryFr: 'Logiciels',
        icon: 'install_desktop',
        workflowId: 'software-installation',
        groupId: 'technical-support',
        slaId: 'request-standard',
        fields: [
          _assetField(),
          CatalogueFieldSchema(
            key: 'softwareName',
            type: CatalogueFieldType.shortText,
            label: _text('Software name', 'Nom du logiciel'),
            required: true,
            maximumLength: 120,
          ),
          _businessJustificationField(),
        ],
      ),
      _Seed(
        code: 'software_licence',
        nameEn: 'Request software licence',
        nameFr: 'Demander une licence logicielle',
        descriptionEn:
            'Request allocation or purchase of a business software licence.',
        descriptionFr:
            "Demander l'attribution ou l'achat d'une licence logicielle.",
        category: 'software',
        categoryEn: 'Software',
        categoryFr: 'Logiciels',
        icon: 'key',
        workflowId: 'software-licence',
        groupId: 'licence-management',
        slaId: 'request-standard',
        approvalPolicyId: 'manager-and-licence-approval',
        fields: [
          CatalogueFieldSchema(
            key: 'softwareName',
            type: CatalogueFieldType.shortText,
            label: _text('Software name', 'Nom du logiciel'),
            required: true,
            maximumLength: 120,
          ),
          _businessJustificationField(),
        ],
      ),
      _Seed(
        code: 'account_access',
        nameEn: 'Request account or access',
        nameFr: 'Demander un compte ou un acces',
        descriptionEn:
            'Request creation, restoration, or modification of system access.',
        descriptionFr:
            "Demander la creation, la restauration ou la modification d'un "
            'acces systeme.',
        category: 'access',
        categoryEn: 'Identity and access',
        categoryFr: 'Identite et acces',
        icon: 'manage_accounts',
        workflowId: 'access-request',
        groupId: 'identity-access',
        slaId: 'access-request',
        approvalPolicyId: 'line-manager-approval',
        fields: [
          _systemField(),
          _accessTypeField(),
          _businessJustificationField()
        ],
      ),
      _Seed(
        code: 'vpn_network_access',
        nameEn: 'Request VPN or network access',
        nameFr: 'Demander un acces VPN ou reseau',
        descriptionEn:
            'Request remote-access or controlled network connectivity.',
        descriptionFr:
            'Demander un acces distant ou une connectivite reseau controlee.',
        category: 'access',
        categoryEn: 'Identity and access',
        categoryFr: 'Identite et acces',
        icon: 'vpn_key',
        workflowId: 'network-access',
        groupId: 'network-operations',
        slaId: 'access-request',
        approvalPolicyId: 'line-manager-and-security-approval',
        fields: [
          _choiceField(
            key: 'accessType',
            en: 'Access type',
            fr: "Type d'acces",
            values: const {
              'vpn': ('VPN', 'VPN'),
              'network': ('Network segment', 'Segment reseau'),
            },
          ),
          _businessJustificationField(),
          CatalogueFieldSchema(
            key: 'requiredUntil',
            type: CatalogueFieldType.date,
            label: _text('Required until', "Necessaire jusqu'au"),
          ),
        ],
      ),
      _Seed(
        code: 'equipment_return_transfer',
        nameEn: 'Request equipment return or transfer',
        nameFr: "Demander le retour ou le transfert d'un equipement",
        descriptionEn:
            'Arrange the governed return or transfer of assigned equipment.',
        descriptionFr:
            "Organiser le retour ou le transfert controle d'un equipement.",
        category: 'equipment',
        categoryEn: 'Equipment',
        categoryFr: 'Equipement',
        icon: 'assignment_return',
        workflowId: 'asset-return-transfer',
        groupId: 'asset-management',
        slaId: 'asset-request',
        fields: [
          _assetField(),
          _choiceField(
            key: 'movementType',
            en: 'Movement',
            fr: 'Mouvement',
            values: const {
              'return': ('Return', 'Retour'),
              'transfer': ('Transfer', 'Transfert'),
            },
          ),
          _descriptionField(required: false),
        ],
      ),
      _Seed(
        code: 'change_request',
        nameEn: 'Submit a change request',
        nameFr: 'Soumettre une demande de changement',
        descriptionEn:
            'Propose a governed change to an IT service or configuration.',
        descriptionFr: 'Proposer un changement controle sur un service ou une '
            'configuration informatique.',
        category: 'governance',
        categoryEn: 'Governance',
        categoryFr: 'Gouvernance',
        icon: 'published_with_changes',
        workflowId: 'change-intake',
        groupId: 'change-management',
        slaId: 'change-assessment',
        approvalPolicyId: 'change-approval',
        fields: [
          _titleField(),
          _descriptionField(),
          _businessJustificationField(),
        ],
      ),
      _Seed(
        code: 'security_exception',
        nameEn: 'Submit a security exception',
        nameFr: 'Soumettre une exception de securite',
        descriptionEn:
            'Request a time-bound exception with compensating controls.',
        descriptionFr:
            'Demander une exception limitee dans le temps avec des mesures '
            'compensatoires.',
        category: 'security',
        categoryEn: 'Security',
        categoryFr: 'Securite',
        icon: 'gpp_maybe',
        workflowId: 'security-exception',
        groupId: 'cybersecurity',
        slaId: 'security-assessment',
        approvalPolicyId: 'security-exception-approval',
        fields: [
          _systemField(),
          _businessJustificationField(),
          CatalogueFieldSchema(
            key: 'compensatingControls',
            type: CatalogueFieldType.longText,
            label: _text(
              'Compensating controls',
              'Mesures compensatoires',
            ),
            required: true,
            minimumLength: 20,
            maximumLength: 3000,
          ),
          CatalogueFieldSchema(
            key: 'expiryDate',
            type: CatalogueFieldType.date,
            label: _text('Requested expiry date', "Date d'expiration demandee"),
            required: true,
          ),
        ],
        documents: [_evidenceDocument()],
      ),
      _Seed(
        code: 'access_correction_revocation',
        nameEn: 'Request access correction or revocation',
        nameFr: "Demander la correction ou la revocation d'un acces",
        descriptionEn:
            'Report inappropriate access and request correction or revocation.',
        descriptionFr:
            'Signaler un acces inapproprie et demander sa correction ou sa '
            'revocation.',
        category: 'access',
        categoryEn: 'Identity and access',
        categoryFr: 'Identite et acces',
        icon: 'person_off',
        workflowId: 'access-correction',
        groupId: 'identity-access',
        slaId: 'access-request',
        fields: [
          _systemField(),
          _accessTypeField(),
          _descriptionField(),
        ],
      ),
    ];

    return definitions
        .asMap()
        .entries
        .map(
          (entry) => entry.value.toModel(
            sortOrder: (entry.key + 1) * 10,
            createdAt: createdAt,
            createdBy: createdBy,
          ),
        )
        .toList(growable: false);
  }

  static CatalogueFieldSchema _titleField() {
    return CatalogueFieldSchema(
      key: 'title',
      type: CatalogueFieldType.shortText,
      label: _text('Title', 'Titre'),
      required: true,
      minimumLength: 5,
      maximumLength: 160,
    );
  }

  static CatalogueFieldSchema _descriptionField({bool required = true}) {
    return CatalogueFieldSchema(
      key: 'description',
      type: CatalogueFieldType.longText,
      label: _text('Description', 'Description'),
      required: required,
      minimumLength: required ? 10 : null,
      maximumLength: 4000,
    );
  }

  static CatalogueFieldSchema _blockingField() {
    return CatalogueFieldSchema(
      key: 'isBlocking',
      type: CatalogueFieldType.boolean,
      label: _text('Is your work blocked?', 'Votre travail est-il bloque ?'),
      required: true,
      defaultValue: false,
    );
  }

  static CatalogueFieldSchema _assetField() {
    return CatalogueFieldSchema(
      key: 'assetId',
      type: CatalogueFieldType.asset,
      label: _text('Affected equipment', 'Equipement concerne'),
      required: true,
    );
  }

  static CatalogueFieldSchema _systemField() {
    return CatalogueFieldSchema(
      key: 'systemName',
      type: CatalogueFieldType.shortText,
      label: _text('System or application', 'Systeme ou application'),
      required: true,
      maximumLength: 160,
    );
  }

  static CatalogueFieldSchema _accessTypeField() {
    return _choiceField(
      key: 'accessAction',
      en: 'Requested action',
      fr: 'Action demandee',
      values: const {
        'create': ('Create', 'Creer'),
        'modify': ('Modify', 'Modifier'),
        'restore': ('Restore', 'Restaurer'),
        'revoke': ('Revoke', 'Revoquer'),
      },
    );
  }

  static CatalogueFieldSchema _businessJustificationField() {
    return CatalogueFieldSchema(
      key: 'businessJustification',
      type: CatalogueFieldType.longText,
      label: _text('Business justification', 'Justification professionnelle'),
      required: true,
      minimumLength: 10,
      maximumLength: 2000,
    );
  }

  static CatalogueFieldSchema _choiceField({
    required String key,
    required String en,
    required String fr,
    required Map<String, (String, String)> values,
  }) {
    return CatalogueFieldSchema(
      key: key,
      type: CatalogueFieldType.singleSelect,
      label: _text(en, fr),
      required: true,
      options: values.entries.map(
        (entry) => CatalogueFieldOption(
          value: entry.key,
          label: _text(entry.value.$1, entry.value.$2),
        ),
      ),
    );
  }

  static CatalogueRequiredDocument _evidenceDocument({
    bool required = true,
  }) {
    return CatalogueRequiredDocument(
      key: 'supportingEvidence',
      label: _text('Supporting evidence', 'Piece justificative'),
      required: required,
      maximumFiles: 5,
      allowedContentTypes: const {
        'application/pdf',
        'image/jpeg',
        'image/png',
      },
    );
  }

  static LocalizedValue _text(String en, String fr) {
    return LocalizedValue(en: en, fr: fr);
  }
}

class _Seed {
  const _Seed({
    required this.code,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.category,
    required this.categoryEn,
    required this.categoryFr,
    required this.icon,
    required this.workflowId,
    required this.groupId,
    required this.slaId,
    this.approvalPolicyId,
    this.fields = const [],
    this.documents = const [],
  });

  final String code;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String category;
  final String categoryEn;
  final String categoryFr;
  final String icon;
  final String workflowId;
  final String groupId;
  final String slaId;
  final String? approvalPolicyId;
  final List<CatalogueFieldSchema> fields;
  final List<CatalogueRequiredDocument> documents;

  ServiceCatalogueItem toModel({
    required int sortOrder,
    required DateTime createdAt,
    required String createdBy,
  }) {
    return ServiceCatalogueItem(
      id: code,
      code: code,
      version: 1,
      name: LocalizedValue(en: nameEn, fr: nameFr),
      description: LocalizedValue(
        en: descriptionEn,
        fr: descriptionFr,
      ),
      categoryId: category,
      categoryName: LocalizedValue(en: categoryEn, fr: categoryFr),
      iconKey: icon,
      eligibility: CatalogueEligibility(),
      visibleRoles: ItsmRole.values,
      workflow: VersionedConfigurationReference(
        id: workflowId,
        version: 1,
      ),
      approvalPolicyId: approvalPolicyId,
      fulfilmentGroupId: groupId,
      slaPolicy: VersionedConfigurationReference(id: slaId, version: 1),
      status: ItsmPublicationState.published,
      sortOrder: sortOrder,
      formFields: fields,
      requiredDocuments: documents,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: createdAt,
      updatedBy: createdBy,
    );
  }
}
