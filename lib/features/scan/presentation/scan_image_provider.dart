import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ScanImageProviderFactory = ImageProvider<Object> Function(String path);

final scanImageProviderFactoryProvider = Provider<ScanImageProviderFactory>((
  ref,
) {
  return (path) => FileImage(File(path));
});
