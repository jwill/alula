import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../state/app_signals.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/packages_tab.dart';
import 'tabs/avd_studio_tab.dart';
import 'tabs/doctor_tab.dart';
import 'widgets/log_console.dart';

class StudioShell extends SignalWidget {
  final AppSignals appSignals;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const StudioShell({
    super.key,
    required this.appSignals,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIndex = appSignals.activeTab.value;
    final isBusy = appSignals.isBusy.value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flutter_dash, color: Colors.blue),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Flutter & Android SDK Studio',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v1.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: isBusy ? null : () => appSignals.refreshEnvironment(),
            tooltip: 'Refresh Environment Status',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (isBusy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: activeIndex,
                  onDestinationSelected: (index) {
                    appSignals.activeTab.value = index;
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Packages'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.phone_android_outlined),
                      selectedIcon: Icon(Icons.phone_android),
                      label: Text('Emulators'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.medical_services_outlined),
                      selectedIcon: Icon(Icons.medical_services),
                      label: Text('Doctor'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: activeIndex,
                    children: [
                      DashboardTab(appSignals: appSignals),
                      PackagesTab(appSignals: appSignals),
                      AvdStudioTab(appSignals: appSignals),
                      DoctorTab(appSignals: appSignals),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LogConsoleDrawer(appSignals: appSignals),
        ],
      ),
    );
  }
}
