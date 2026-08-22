import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the macOS sandbox entitlements.
///
/// Under App Sandbox — mandatory for Mac App Store distribution — an app that
/// is not granted `com.apple.security.network.client` cannot open outbound
/// connections, so LabFox cannot reach any GitLab instance. Nothing else in CI
/// notices: `flutter analyze` and `flutter test` never build or launch the
/// macOS app, so losing this entitlement would ship a silently dead app.
void main() {
  const networkClient = 'com.apple.security.network.client';

  for (final name in const ['Release', 'DebugProfile']) {
    test('$name.entitlements grants the network client entitlement', () {
      final file = File('macos/Runner/$name.entitlements');
      expect(
        file.existsSync(),
        isTrue,
        reason: '${file.path} is missing; the macOS runner is not scaffolded',
      );
      expect(
        file.readAsStringSync(),
        contains(networkClient),
        reason:
            'Without $networkClient a sandboxed macOS build cannot reach a '
            'GitLab instance. See issue #167.',
      );
    });
  }
}
