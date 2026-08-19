import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

class SessionLoadingScreen extends StatelessWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingProfile),
          ],
        ),
      ),
    );
  }
}
