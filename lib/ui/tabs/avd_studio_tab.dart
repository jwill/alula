import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../models/environment_models.dart';
import '../../state/app_signals.dart';

class AvdStudioTab extends SignalWidget {
  final AppSignals appSignals;

  const AvdStudioTab({super.key, required this.appSignals});

  void _showCreateAvdDialog(BuildContext context) {
    String selectedProfile = 'medium_phone';
    final profiles = [
      'medium_phone',
      'small_phone',
      'medium_desktop',
      'large_desktop',
      'medium_tablet',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Virtual Device'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Device Hardware Profile:'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedProfile,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: profiles.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedProfile = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    appSignals.createAvd(selectedProfile);
                  },
                  child: const Text('Create Device'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avds = appSignals.avdsList.value;
    final isBusy = appSignals.isBusy.value;

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
                      'Android Virtual Device (AVD) Studio',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Launch, manage, and configure Android emulators without Android Studio.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: isBusy ? null : () => _showCreateAvdDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Device'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (avds.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.smartphone, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('No emulators configured yet.', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Click below to create a standard Pixel-style virtual device.',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: isBusy ? null : () => appSignals.createAvd('medium_phone'),
                        child: const Text('Create "medium_phone" AVD'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 180,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: avds.length,
              itemBuilder: (context, index) {
                final avd = avds[index];
                return _buildAvdCard(context, avd, isBusy);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvdCard(BuildContext context, AvdItem avd, bool isBusy) {
    final theme = Theme.of(context);
    final isDesktop = avd.name.contains('desktop');
    final isTablet = avd.name.contains('tablet');

    IconData deviceIcon = Icons.smartphone;
    if (isDesktop) deviceIcon = Icons.desktop_windows;
    if (isTablet) deviceIcon = Icons.tablet_android;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: avd.isRunning ? Colors.green.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
          width: avd.isRunning ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avd.isRunning ? Colors.green.withValues(alpha: 0.15) : theme.colorScheme.primaryContainer,
                  child: Icon(
                    deviceIcon,
                    color: avd.isRunning ? Colors.green : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avd.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'HW Keyboard: Yes',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: avd.isRunning
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          label: Text(
                            avd.pid != null ? 'Running (PID: ${avd.pid})' : 'Running',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isBusy ? null : () => appSignals.launchAvd(avd.name),
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Launch'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _confirmDelete(context, avd.name),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Delete AVD',
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String avdName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Virtual Device'),
        content: Text('Are you sure you want to delete "$avdName"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              appSignals.deleteAvd(avdName);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
