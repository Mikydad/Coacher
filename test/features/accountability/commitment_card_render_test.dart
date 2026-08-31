import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/accountability/presentation/cards/commitment_card.dart';

/// FR-12 capture smoke tests: every card state × aspect lays out with the
/// real plate assets and captures at exactly 1080×1920 / 1080×1080.
///
/// Side product: the captures are written to build/commitment_card_samples/
/// as real PNGs for visual review — the bundled CardSans faces are loaded
/// from the asset bundle so the samples show real glyphs, exactly as
/// exported on devices.

Future<void> _loadCardFont() async {
  final loader = FontLoader(kCardFontFamily);
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/card/Roboto-$w.ttf'));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sep1 = DateTime(2026, 9, 1);
  final aug30 = DateTime(2026, 8, 30);
  final sep15 = DateTime(2026, 9, 15);
  final cases = <(String, CommitmentCardData)>[
    (
      'pledge',
      CommitmentCardData(
        state: CommitmentCardState.pledge,
        goalTitle: 'Finish my portfolio',
        deadline: sep1,
        displayName: 'Miko',
        note: "I'm putting in the work today for the future I want tomorrow.",
      ),
    ),
    (
      'success',
      CommitmentCardData(
        state: CommitmentCardState.success,
        goalTitle: 'Finish my portfolio',
        deadline: sep1,
        completedOn: aug30,
        displayName: 'Miko',
        note: 'Discipline today. Freedom tomorrow.',
        unitsPassed: 28,
        unitsRequired: 30,
      ),
    ),
    (
      'failure',
      CommitmentCardData(
        state: CommitmentCardState.failure,
        goalTitle: 'Finish my portfolio',
        deadline: sep1,
        displayName: 'Miko',
        unitsPassed: 22,
        unitsRequired: 30,
        recommitDate: sep15,
      ),
    ),
    (
      'failure_zero',
      CommitmentCardData(
        state: CommitmentCardState.failure,
        goalTitle: 'Finish my portfolio',
        deadline: sep1,
        displayName: 'Miko',
        unitsPassed: 0,
        unitsRequired: 30,
        recommitDate: sep15,
      ),
    ),
    (
      'failure_surrender',
      CommitmentCardData(
        state: CommitmentCardState.failure,
        goalTitle: 'Finish my portfolio',
        deadline: sep1,
        displayName: 'Miko',
        unitsPassed: 9,
        unitsRequired: 30,
        surrendered: true,
      ),
    ),
  ];

  for (final (name, data) in cases) {
    for (final aspect in CommitmentCardAspect.values) {
      testWidgets('renders $name / ${aspect.name} and captures at 3x', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(720, 1280));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.runAsync(_loadCardFont);

        final key = GlobalKey();
        final size = aspect == CommitmentCardAspect.story
            ? CommitmentCard.storySize
            : CommitmentCard.squareSize;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: RepaintBoundary(
                  key: key,
                  child: CommitmentCard(data: data, aspect: aspect),
                ),
              ),
            ),
          ),
        );
        // Decode the plate asset for real (runAsync escapes fake async),
        // then pump so the decoded frame paints before capture.
        await tester.runAsync(() async {
          await precacheImage(
            AssetImage(plateAssetFor(data.state)),
            key.currentContext!,
          );
        });
        await tester.pump();

        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image? image;
        ByteData? bytes;
        await tester.runAsync(() async {
          image = await boundary.toImage(pixelRatio: 3.0);
          bytes = await image!.toByteData(format: ui.ImageByteFormat.png);
        });

        expect(image!.width, 1080);
        expect(
          image!.height,
          aspect == CommitmentCardAspect.story ? 1920 : 1080,
        );
        expect(bytes, isNotNull);
        expect(bytes!.lengthInBytes, greaterThan(10_000));

        final out = File(
          'build/commitment_card_samples/${name}_${aspect.name}.png',
        );
        await tester.runAsync(() async {
          out.parent.createSync(recursive: true);
          await out.writeAsBytes(bytes!.buffer.asUint8List());
        });
        image!.dispose();
      });
    }
  }
}
