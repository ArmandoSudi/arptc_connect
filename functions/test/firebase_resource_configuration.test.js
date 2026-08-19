'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const projectRoot = path.resolve(__dirname, '..', '..');
const currentBucket = 'arptc-connect.firebasestorage.app';
const removedBucket = 'arptc-connect.appspot.com';

test('runtime Firebase configurations use the provisioned Storage bucket', () => {
  const files = [
    'functions/index.js',
    'lib/firebase_options.dart',
    'web/firebase-messaging-sw.js',
    'macos/Runner/GoogleService-Info.plist',
  ];

  for (const relativePath of files) {
    const source = fs.readFileSync(path.join(projectRoot, relativePath), 'utf8');
    assert.match(source, new RegExp(currentBucket.replaceAll('.', '\\.')));
    assert.doesNotMatch(source, new RegExp(removedBucket.replaceAll('.', '\\.')));
  }
});
