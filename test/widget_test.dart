import 'package:aether_observatory/scene/atmosphere_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aether Observatory configuration', () {
    test('every ObservatoryMood has a matching MoodConfig', () {
      for (final mood in ObservatoryMood.values) {
        final config = kMoodConfigs[mood];
        expect(config, isNotNull, reason: 'Missing MoodConfig for $mood');
        expect(config!.mood, mood);
        expect(config.orbColors.length, 3);
        expect(config.exposure, greaterThan(0.0));
      }
    });

    test('sunDirectionFromAngles produces unit-length vectors', () {
      final dir = MoodConfig.sunDirectionFromAngles(25.0, -140.0);
      expect(dir.length, closeTo(1.0, 1e-5));
      expect(dir.y, greaterThan(0.0));
    });

    test('QualityTier renderScale descends from ultra to performance', () {
      expect(
        QualityTier.ultra.renderScale,
        greaterThan(QualityTier.balanced.renderScale),
      );
      expect(
        QualityTier.balanced.renderScale,
        greaterThan(QualityTier.performance.renderScale),
      );
    });
  });
}
