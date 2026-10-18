import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../models/environment_models.dart';
import '../../state/app_signals.dart';

class DashboardTab extends SignalWidget {
  final AppSignals appSignals;

  const DashboardTab({super.key, required this.appSignals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flutter = appSignals.flutterInfo.value;
    final java = appSignals.javaInfo.value;
    final android = appSignals.androidCliInfo.value;
    final avds = appSignals.avdsList.value;
    final isBusy = appSignals.isBusy.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environment Health & Quick Actions',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 3 Health Cards with uniform height
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildHealthCard(
                          context,
                          title: 'Flutter SDK',
                          icon: const FlutterLogo(),
                          status: flutter.status,
                          line1: 'Version: ${flutter.version} (${flutter.channel})',
                          line2: flutter.path.isNotEmpty ? flutter.path : 'Searching PATH...',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHealthCard(
                          context,
                          title: 'Java Runtime (JDK)',
                          icon: Icons.coffee,
                          status: java.status,
                          line1: java.rawVersion,
                          line2: java.javaHome.isNotEmpty ? java.javaHome : 'Auto-detected via PATH',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHealthCard(
                          context,
                          title: 'Android CLI & SDK',
                          icon: Icons.android,
                          status: android.status,
                          line1: android.sdkVersion.isNotEmpty && android.sdkVersion != 'Unknown'
                              ? 'SDK Version: ${android.sdkVersion}'
                              : 'CLI Version: ${android.version}',
                          extraLine: android.sdkVersion.isNotEmpty && android.sdkVersion != 'Unknown'
                              ? 'CLI Version: ${android.version}'
                              : null,
                          line2: android.sdkPath.isNotEmpty ? android.sdkPath : 'No SDK located',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  _buildHealthCard(
                    context,
                    title: 'Flutter SDK',
                    icon: const FlutterLogo(size: 24),
                    status: flutter.status,
                    line1: 'Version: ${flutter.version} (${flutter.channel})',
                    line2: flutter.path.isNotEmpty ? flutter.path : 'Searching PATH...',
                  ),
                  const SizedBox(height: 16),
                  _buildHealthCard(
                    context,
                    title: 'Java Runtime (JDK)',
                    icon: Icons.coffee,
                    status: java.status,
                    line1: java.rawVersion,
                    line2: java.javaHome.isNotEmpty ? java.javaHome : 'Auto-detected via PATH',
                  ),
                  const SizedBox(height: 16),
                  _buildHealthCard(
                    context,
                    title: 'Android CLI & SDK',
                    icon: Icons.android,
                    status: android.status,
                    line1: android.sdkVersion.isNotEmpty && android.sdkVersion != 'Unknown'
                        ? 'SDK Version: ${android.sdkVersion}'
                        : 'CLI Version: ${android.version}',
                    extraLine: android.sdkVersion.isNotEmpty && android.sdkVersion != 'Unknown'
                        ? 'CLI Version: ${android.version}'
                        : null,
                    line2: android.sdkPath.isNotEmpty ? android.sdkPath : 'No SDK located',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () {
                        if (avds.isNotEmpty) {
                          appSignals.launchAvd(avds.first.name);
                        } else {
                          appSignals.createAvd('medium_phone');
                        }
                      },
                icon: const Icon(Icons.play_arrow),
                label: Text(avds.isNotEmpty ? 'Launch ${avds.first.name}' : 'Create Default AVD'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => appSignals.runDoctor(),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Run Flutter Doctor'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => appSignals.acceptLicenses(),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Accept All Licenses'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => appSignals.refreshEnvironment(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Available Virtual Devices (AVDs)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => appSignals.activeTab.value = 2,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Manage Devices'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (avds.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.phone_android, size: 40, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('No emulators created yet.', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
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
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: avds.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final avd = avds[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: avd.isRunning ? Colors.green.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.smartphone,
                        color: avd.isRunning ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(avd.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (avd.isRunning) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  avd.pid != null ? 'PID ${avd.pid}' : 'Running',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      avd.isRunning
                          ? 'Active emulator session (PID: ${avd.pid ?? 'Active'})'
                          : 'Profile: ${avd.profile} | API Level: ${avd.apiLevel}',
                    ),
                    trailing: avd.isRunning
                        ? Chip(
                            avatar: const Icon(Icons.check, size: 14, color: Colors.green),
                            label: Text(
                              avd.pid != null ? 'PID: ${avd.pid}' : 'Running',
                              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                            side: BorderSide.none,
                          )
                        : FilledButton.tonalIcon(
                            onPressed: isBusy ? null : () => appSignals.launchAvd(avd.name),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Launch'),
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context, {
    required String title,
    required dynamic icon,
    required ToolStatus status,
    required String line1,
    String? extraLine,
    required String line2,
  }) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText;

    switch (status) {
      case ToolStatus.ok:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ToolStatus.warning:
        statusColor = Colors.orange;
        statusText = 'Warning';
        break;
      case ToolStatus.error:
        statusColor = Colors.red;
        statusText = 'Missing';
        break;
      case ToolStatus.loading:
        statusColor = Colors.grey;
        statusText = 'Checking...';
        break;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon is Widget)
                  icon
                else if (icon is IconData)
                  Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line1,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (extraLine != null && extraLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    extraLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  line2,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
