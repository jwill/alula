import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../state/app_signals.dart';

class DoctorTab extends SignalWidget {
  final AppSignals appSignals;

  const DoctorTab({super.key, required this.appSignals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctorText = appSignals.doctorOutput.value;
    final isBusy = appSignals.isBusy.value;
    final androidInfo = appSignals.androidCliInfo.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flutter Doctor & Diagnostics',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify toolchain integrity and execute one-click repairs.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: isBusy ? null : () => appSignals.runDoctor(),
                icon: const Icon(Icons.refresh),
                label: const Text('Run Diagnostics'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : () => appSignals.acceptLicenses(),
                icon: const Icon(Icons.verified),
                label: const Text('Fix Licenses (Accept All)'),
              ),
              if (androidInfo.sdkPath.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => appSignals.relinkSdk(androidInfo.sdkPath),
                  icon: const Icon(Icons.link),
                  label: const Text('Re-link Android SDK Path'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Doctor Output:',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SelectableText(
              doctorText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
