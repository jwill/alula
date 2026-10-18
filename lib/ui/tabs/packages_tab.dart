import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../state/app_signals.dart';

class PackagesTab extends SignalWidget {
  final AppSignals appSignals;

  const PackagesTab({super.key, required this.appSignals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packages = appSignals.packagesList.value;
    final isBusy = appSignals.isBusy.value;

    // Group packages by category
    final categories = <String, List<dynamic>>{};
    for (final pkg in packages) {
      categories.putIfAbsent(pkg.category, () => []).add(pkg);
    }

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
                      'Android SDK Package Manager',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Install or update platforms, build tools, and system images via Android CLI.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () {
                        appSignals.installPackage('platforms/android-35 build-tools/35.0.0 platform-tools emulator');
                      },
                icon: const Icon(Icons.download),
                label: const Text('Install Bundle'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ...categories.entries.map((entry) {
            final categoryName = entry.key;
            final items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Icon(
                          item.isInstalled ? Icons.check_circle : Icons.arrow_circle_down,
                          color: item.isInstalled ? Colors.green : theme.colorScheme.primary,
                        ),
                        title: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(item.packagePath, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        trailing: OutlinedButton(
                          onPressed: isBusy ? null : () => appSignals.installPackage(item.packagePath),
                          child: Text(item.isInstalled ? 'Reinstall' : 'Install'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }
}
