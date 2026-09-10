import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/domain/heatmap_color_scale.dart';

void main() {
  test('maps minimum activation to blue and maximum activation to green', () {
    final minimum = heatmapRgb(0);
    final maximum = heatmapRgb(1);

    expect((minimum.red, minimum.green, minimum.blue), (0x15, 0x55, 0xd1));
    expect((maximum.red, maximum.green, maximum.blue), (0x00, 0xc8, 0x53));
    expect(heatmapOverlayOpacity, 0.6);
  });

  test('clamps activation values before applying the color scale', () {
    expect(heatmapRgb(-1).blue, heatmapRgb(0).blue);
    expect(heatmapRgb(2).green, heatmapRgb(1).green);
  });
}
