import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sidepal/features/feedback/application/feedback_context_collector.dart';
import 'package:sidepal/features/feedback/application/tester_mode_controller.dart';
import 'package:sidepal/features/settings/application/crashlytics_test_sink.dart';
import 'package:sidepal/features/settings/presentation/about_support_screen.dart';

class _FixedTesterMode extends TesterModeController {
  _FixedTesterMode(bool value) {
    state = value;
  }
}

class _FakeSink implements CrashlyticsTestSink {
  _FakeSink({this.collectionEnabled = true});

  @override
  final bool collectionEnabled;

  int nonFatalCalls = 0;
  int crashCalls = 0;

  @override
  Future<void> sendNonFatal() async => nonFatalCalls++;

  @override
  Future<void> crash() async => crashCalls++;
}

const _versionLabel = 'SIDEPAL V1.0.1 BUILD 2';

Widget _host({
  required bool testerMode,
  required _FakeSink sink,
  bool crashTriggerEnabled = true,
}) =>
    ProviderScope(
      overrides: [
        testerModeProvider.overrideWith((ref) => _FixedTesterMode(testerMode)),
        crashlyticsTestSinkProvider.overrideWithValue(sink),
        packageInfoProvider.overrideWith(
          (_) async => PackageInfo(
            appName: 'SidePal',
            packageName: 'io.sidepal.app',
            version: '1.0.1',
            buildNumber: '2',
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: VersionFooter(crashTriggerEnabled: crashTriggerEnabled),
        ),
      ),
    );

Future<void> _pumpAndLongPress(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.pump();
  expect(find.text(_versionLabel), findsOneWidget);
  await tester.longPress(find.text(_versionLabel));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('long-press does nothing when tester mode is off', (
    tester,
  ) async {
    final sink = _FakeSink();
    await _pumpAndLongPress(tester, _host(testerMode: false, sink: sink));

    expect(find.text('Crashlytics smoke test'), findsNothing);
    expect(sink.nonFatalCalls, 0);
    expect(sink.crashCalls, 0);
  });

  testWidgets('Send non-fatal records the event and confirms', (tester) async {
    final sink = _FakeSink();
    await _pumpAndLongPress(tester, _host(testerMode: true, sink: sink));

    expect(find.text('Crashlytics smoke test'), findsOneWidget);
    await tester.tap(find.text('Send non-fatal'));
    await tester.pumpAndSettle();

    expect(sink.nonFatalCalls, 1);
    expect(sink.crashCalls, 0);
    expect(find.textContaining('Test event sent'), findsOneWidget);
  });

  testWidgets('Crash app forwards to the sink and sends no snackbar', (
    tester,
  ) async {
    final sink = _FakeSink();
    await _pumpAndLongPress(tester, _host(testerMode: true, sink: sink));

    await tester.tap(find.text('Crash app'));
    await tester.pumpAndSettle();

    expect(sink.crashCalls, 1);
    expect(sink.nonFatalCalls, 0);
    expect(find.textContaining('Test event sent'), findsNothing);
  });

  testWidgets('Cancel touches nothing', (tester) async {
    final sink = _FakeSink();
    await _pumpAndLongPress(tester, _host(testerMode: true, sink: sink));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Crashlytics smoke test'), findsNothing);
    expect(sink.nonFatalCalls, 0);
    expect(sink.crashCalls, 0);
  });

  testWidgets('warns honestly when collection is off (debug builds)', (
    tester,
  ) async {
    await _pumpAndLongPress(
      tester,
      _host(testerMode: true, sink: _FakeSink(collectionEnabled: false)),
    );
    expect(
      find.textContaining('Collection is off in this build'),
      findsOneWidget,
    );
  });

  testWidgets('no warning when collection is on', (tester) async {
    await _pumpAndLongPress(
      tester,
      _host(testerMode: true, sink: _FakeSink(collectionEnabled: true)),
    );
    expect(
      find.textContaining('Collection is off in this build'),
      findsNothing,
    );
  });

  testWidgets('a non-tester build compiles the trigger out even in tester mode', (
    tester,
  ) async {
    final sink = _FakeSink();
    await _pumpAndLongPress(
      tester,
      _host(testerMode: true, sink: sink, crashTriggerEnabled: false),
    );
    expect(find.text('Crashlytics smoke test'), findsNothing);
    expect(sink.crashCalls, 0);
  });
}
