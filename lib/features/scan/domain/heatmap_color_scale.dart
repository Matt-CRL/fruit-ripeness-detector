final class HeatmapRgb {
  const HeatmapRgb(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;
}

const heatmapColorStops = <HeatmapRgb>[
  HeatmapRgb(0x15, 0x55, 0xd1),
  HeatmapRgb(0xe5, 0x39, 0x35),
  HeatmapRgb(0xff, 0xdf, 0x00),
  HeatmapRgb(0x00, 0xc8, 0x53),
];

const heatmapOverlayOpacity = 0.6;

HeatmapRgb heatmapRgb(double value) {
  final scaled = value.clamp(0.0, 1.0) * (heatmapColorStops.length - 1);
  final lower = scaled.floor();
  final upper = lower == heatmapColorStops.length - 1 ? lower : lower + 1;
  final amount = scaled - lower;
  final start = heatmapColorStops[lower];
  final end = heatmapColorStops[upper];

  return HeatmapRgb(
    _lerpChannel(start.red, end.red, amount),
    _lerpChannel(start.green, end.green, amount),
    _lerpChannel(start.blue, end.blue, amount),
  );
}

int _lerpChannel(int start, int end, double amount) =>
    (start + (end - start) * amount).round().clamp(0, 255);
