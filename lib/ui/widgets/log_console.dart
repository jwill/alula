import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../state/app_signals.dart';

class LogConsoleDrawer extends StatefulWidget {
  final AppSignals appSignals;

  const LogConsoleDrawer({super.key, required this.appSignals});

  @override
  State<LogConsoleDrawer> createState() => _LogConsoleDrawerState();
}

class _LogConsoleDrawerState extends State<LogConsoleDrawer> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context) {
      final isExpanded = widget.appSignals.isConsoleExpanded.value;
      final logs = widget.appSignals.consoleLogs.value;
      final isBusy = widget.appSignals.isBusy.value;
      final busyMsg = widget.appSignals.busyMessage.value;

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: isExpanded ? 240 : 42,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          children: [
            // Header Bar
            InkWell(
              onTap: () {
                widget.appSignals.isConsoleExpanded.value = !isExpanded;
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Process Console',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    if (isBusy) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        busyMsg,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ] else ...[
                      Text(
                        '(${logs.length} lines)',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                    const Spacer(),
                    if (isExpanded && logs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => widget.appSignals.clearLogs(),
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                  ],
                ),
              ),
            ),
            // Expanded Log Viewer
            if (isExpanded)
              Expanded(
                child: Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.all(12),
                  child: logs.isEmpty
                      ? Center(
                          child: Text(
                            'No command logs yet. Actions will stream here.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final line = logs[index];
                            final isError = line.startsWith('[!]') || line.startsWith('[ERROR]');
                            final isCommand = line.startsWith('\$');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: SelectableText(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isError
                                      ? theme.colorScheme.error
                                      : isCommand
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                  fontWeight: isCommand ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
