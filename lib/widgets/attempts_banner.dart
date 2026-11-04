import 'package:flutter/material.dart';

/// Bandeau d'avertissement qui indique le nombre de tentatives échouées.
class AttemptsBanner extends StatelessWidget {
  const AttemptsBanner({super.key, required this.failedAttempts, required this.max});

  final int failedAttempts;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocked = failedAttempts >= max;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: failedAttempts == 0
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: blocked ? scheme.errorContainer : scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(blocked ? Icons.rocket_launch : Icons.warning_amber,
                      color: blocked ? scheme.onErrorContainer : scheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      blocked
                          ? 'Houston, nous avons un problème !'
                          : 'Tentative échouée $failedAttempts/$max',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: blocked ? scheme.onErrorContainer : scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
