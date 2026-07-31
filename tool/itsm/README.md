# ITSM Phase 2 provisioning

Generate the deterministic seed from the Dart domain definitions:

```bash
dart run tool/itsm/generate_phase2_seed.dart > tool/seeds/itsm_phase2_seed.json
```

Review the create-only plan without connecting to Firebase:

```bash
node tool/itsm/provision_phase2_seed.js
```

Applying data is always an explicit operator action and is not part of normal
application deployment:

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
node tool/itsm/provision_phase2_seed.js --apply --project=project-id
```

Existing documents are skipped. `--overwrite` must be provided explicitly to
replace deterministic documents, and should not be used against production
without an approved change and backup.
