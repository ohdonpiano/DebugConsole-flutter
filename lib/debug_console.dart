library debug_console;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:debug_console/controller.dart';
import 'package:debug_console/log.dart';
import 'package:debug_console/tile.dart';

export 'package:debug_console/log.dart';

part 'package:debug_console/popup.dart';

/// # Debug Console
///
/// A console for debugging Flutter apps, and displaying console messages on the widget.
///
/// Check the console for prints and errors, while you're testing it, all within your app. Make your own logging or watch for console prints.
///
/// ## Features
///
/// * Log your messages
/// * Display console messages and errors
/// * Use different levels for better emphasis
/// * Filter the logs
/// * Add extra actions to execute from the Debug Console menu
/// * Check StackTrace of errors
class DebugConsole extends StatefulWidget {
  final DebugConsoleController controller;
  final List<PopupMenuItem<void>> actions;
  final String? title;
  final bool showScaffold;
  final bool expandStackTrace;
  final String? savePath;

  /// # Debug Console
  ///
  /// A console for debugging Flutter apps, and displaying console messages on the widget.
  ///
  /// Check the console for prints and errors, while you're testing it, all within your app. Make your own logging or watch for console prints.
  ///
  /// ## Features
  ///
  /// * Log your messages
  /// * Display console messages and errors
  /// * Use different levels for better emphasis
  /// * Filter the logs
  /// * Add extra actions to execute from the Debug Console menu
  /// * Check StackTrace of errors
  DebugConsole({
    super.key,
    DebugConsoleController? controller,
    this.actions = const [],
    this.title,
    this.showScaffold = true,
    this.expandStackTrace = false,
    this.savePath,
  }) : controller = controller ?? DebugConsole.instance;

  @override
  State<DebugConsole> createState() => _DebugConsoleState();

  static DebugConsoleController? _instance;

  static DebugConsoleController get instance {
    _instance ??= DebugConsoleController(
        logs: DebugConsoleLog.fromFile(DebugConsole.loadPath));
    return _instance!;
  }

  static String loadPath = 'debug_console.log';

  /// Adds a log to the root controller, attached with a message, level, timestamp and stack trace.
  ///
  /// The default level is `DebugConsoleLogLevel.normal`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.instance.log( ... );
  /// ```
  static void log(
    Object? message, {
    DebugConsoleLevel level = DebugConsoleLevel.normal,
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      instance.log(
        message,
        level: level,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Clears the logs of the root controller.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.instance.clear();
  /// ```
  static void clear() => instance.clear();

  /// Adds a log to the root controller, with the level `DebugConsoleLevel.info`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.log(message, level: DebugConsoleLevel.info, ... );
  /// ```
  static void info(
    Object? message, {
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: DebugConsoleLevel.info,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Adds a log to the root controller, with the level `DebugConsoleLevel.warning`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.log(message, level: DebugConsoleLevel.warning, ... );
  /// ```
  static void warning(
    Object? message, {
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: DebugConsoleLevel.warning,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Adds a log to the root controller, with the level `DebugConsoleLevel.error`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.log(message, level: DebugConsoleLevel.error, ... );
  /// ```
  static void error(
    Object? message, {
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: DebugConsoleLevel.error,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Adds a log to the root controller, with the level `DebugConsoleLevel.fatal`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.log(message, level: DebugConsoleLevel.fatal, ... );
  /// ```
  static void fatal(
    Object? message, {
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: DebugConsoleLevel.fatal,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Adds a log to the root controller, with the level `DebugConsoleLevel.debug`.
  ///
  /// Same as:
  /// ```dart
  /// DebugConsole.log(message, level: DebugConsoleLevel.debug, ... );
  /// ```
  static void debug(
    Object? message, {
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        level: DebugConsoleLevel.debug,
        timestamp: timestamp,
        stackTrace: stackTrace,
      );

  /// Listen for prints and errors, to catch all messages in your app.
  ///
  /// Everything inside that function will be automatically logged.
  ///
  /// ```dart
  /// DebugConsole.listen(() {
  ///   runApp(const MyApp());
  /// });
  /// ```
  ///
  /// * A controller can be given, instead of logging to the root.
  static void listen(void Function() body,
      {DebugConsoleController? controller}) {
    controller ??= DebugConsole.instance;
    runZoned(body,
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            controller!.log(line);
            parent.print(zone, line);
          },
          handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
              Object error, StackTrace stackTrace) {
            controller!.log(error,
                level: DebugConsoleLevel.error, stackTrace: stackTrace);
            parent.handleUncaughtError(zone, error, stackTrace);
          },
        ));
  }
}

class _DebugConsoleState extends State<DebugConsole> {
  StreamSubscription<List<DebugConsoleLog>>? subscription;
  List<DebugConsoleLog> logs = [];

  bool expandStackTrace = false;
  bool save = true;
  String filter = '';

  TextEditingController? textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();

    expandStackTrace = widget.expandStackTrace;

    subscription = widget.controller.stream.listen((logs) {
      if (widget.savePath != null && save) saveToFile(logs: logs);

      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      logs = logs.reversed.toList();

      setState(() => this.logs = logs);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showScaffold) {
      return Scaffold(
          appBar: AppBar(
              title: Text(widget.title ?? 'Debug Console'),
              actions: buildScaffoldActions()),
          body: buildBody());
    } else {
      return buildBody();
    }
  }

  Widget buildBody() {
    final filteredLogs = filter.isEmpty
        ? logs
        : logs
            .where((log) => filter.split(',').any((filter) {
                  filter = filter.trim();
                  return filter.isNotEmpty &&
                      log.message.toLowerCase().contains(filter.toLowerCase());
                }))
            .toList();
    return Stack(
      children: [
        logs.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Center(child: Text('No logs')),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 75),
                reverse: true,
                //physics: const AllwaysScrollableFixedPositionScrollPhysics(),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  return DebugConsoleTile(log,
                      key: ValueKey(log.timestamp), expanded: expandStackTrace);
                },
              ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                      hintText: 'Filter logs',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onChanged: (value) => setState(() => filter = value),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    textController!.clear();
                    setState(() => filter = '');
                  },
                ),
                const SizedBox(width: 5),
                FloatingActionButton(
                  tooltip: subscription!.isPaused
                      ? 'Resume logging'
                      : 'Pause logging',
                  onPressed: () => toggleLogging(),
                  child: Icon(
                      subscription!.isPaused ? Icons.play_arrow : Icons.pause),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void saveToFile({List<DebugConsoleLog>? logs, String? path}) {
    path ??= widget.savePath;
    if (path == null) return;
    logs ??= this.logs;

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    logs = logs.reversed.toList();

    final file = File(path);
    if (logs.isEmpty) {
      file.delete();
    } else {
      file.writeAsString(
        logs.map((log) => log.toString()).join('\n'),
      );
    }
  }

  void toggleLogging([bool? paused]) {
    paused ??= subscription!.isPaused;
    setState(() {
      if (paused!) {
        subscription!.resume();
      } else {
        subscription!.pause();
      }
    });
  }

  List<Widget> buildScaffoldActions() {
    return [
      PopupMenuButton<void>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) => [
          ...widget.actions,
          if (widget.actions.isNotEmpty) const PopupMenuDivider(),
          PopupMenuItem(
            child: StatefulBuilder(
              builder: (context, setCheckboxState) => Row(
                children: [
                  const Expanded(child: Text('Pause logging')),
                  Checkbox(
                    value: subscription!.isPaused,
                    onChanged: (value) =>
                        setCheckboxState(() => toggleLogging(!value!)),
                  ),
                ],
              ),
            ),
            onTap: () => toggleLogging(),
          ),
          PopupMenuItem(
            child: StatefulBuilder(
              builder: (context, setCheckboxState) => Row(
                children: [
                  const Expanded(child: Text('Expand StackTrace')),
                  Checkbox(
                    value: expandStackTrace,
                    onChanged: (value) => setCheckboxState(
                        () => setState(() => expandStackTrace = value!)),
                  ),
                ],
              ),
            ),
            onTap: () => setState(() => expandStackTrace = !expandStackTrace),
          ),
          if (widget.savePath != null)
            PopupMenuItem(
              child: StatefulBuilder(
                builder: (context, setCheckboxState) => Row(
                  children: [
                    const Expanded(child: Text('Save')),
                    Checkbox(
                      value: save,
                      onChanged: (value) {
                        if (value!) saveToFile();
                        setCheckboxState(() => setState(() => save = value));
                      },
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (!save) saveToFile();
                setState(() => save = !save);
              },
            ),
          PopupMenuItem(
            onTap: () => widget.controller.clear(),
            child: const Text('Clear'),
          ),
        ],
      )
    ];
  }
}
