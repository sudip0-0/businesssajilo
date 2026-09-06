import 'dart:io';
import 'dart:typed_data';

import 'package:businesssajilo/web/theme/web_theme.dart';
import 'package:businesssajilo/web/theme/web_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

const _assets = {
  'Barlow': [
    'assets/fonts/Barlow-Regular.ttf',
    'assets/fonts/Barlow-Medium.ttf',
    'assets/fonts/Barlow-SemiBold.ttf',
    'assets/fonts/Barlow-Bold.ttf',
  ],
  'Spectral': [
    'assets/fonts/Spectral-Regular.ttf',
    'assets/fonts/Spectral-Medium.ttf',
    'assets/fonts/Spectral-SemiBold.ttf',
    'assets/fonts/Spectral-Bold.ttf',
    'assets/fonts/Spectral-Italic.ttf',
  ],
  'IBM Plex Mono': [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-Medium.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ],
  'Inter': [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ],
  'Noto Sans Devanagari': ['assets/fonts/NotoSansDevanagari-Regular.ttf'],
};

Set<int> _cmap(String path) {
  final list = Uint8List.fromList(File(path).readAsBytesSync());
  final parser = TtfParser(ByteData.view(list.buffer));
  return {
    for (final entry in parser.charToGlyphIndexMap.entries)
      if (entry.value != 0) entry.key,
  };
}

Set<int> _union(Iterable<String> paths) {
  final all = <int>{};
  for (final path in paths) {
    all.addAll(_cmap(path));
  }
  return all;
}

void main() {
  late Map<String, Set<int>> cmaps;

  Set<int> chain(String primary) {
    final families = [primary, ...WebTypography.fontFamilyFallback];
    final covered = <int>{};
    for (final family in families) {
      covered.addAll(cmaps[family]!);
    }
    return covered;
  }

  setUpAll(() {
    cmaps = {
      for (final entry in _assets.entries) entry.key: _union(entry.value),
    };
  });

  test('production web fallbacks are Inter then Noto Sans Devanagari', () {
    expect(WebTypography.fontFamily, 'Barlow');
    expect(WebTypography.serifFamily, 'Spectral');
    expect(WebTypography.monoFamily, 'IBM Plex Mono');
    expect(WebTypography.fontFamilyFallback, ['Inter', 'Noto Sans Devanagari']);
    final theme = WebTheme.light();
    expect(theme.textTheme.bodyMedium?.fontFamily, WebTypography.fontFamily);
    expect(
      theme.dataTableTheme.dataTextStyle?.fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      theme.textTheme.titleLarge?.fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      theme.textTheme.labelMedium?.fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      theme.textTheme.bodyMedium
          ?.copyWith(color: const Color(0xFF111111))
          .fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      WebTypography.serif().fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      WebTypography.mono().fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
    expect(
      WebTypography.eyebrow().fontFamilyFallback,
      WebTypography.fontFamilyFallback,
    );
  });

  test('bundled latin and Devanagari cmaps parse', () {
    expect(cmaps['Inter']!.contains(0x41), isTrue);
    expect(cmaps['Barlow']!.contains(0x41), isTrue);
    expect(cmaps['Spectral']!.contains(0x41), isTrue);
    expect(cmaps['IBM Plex Mono']!.contains(0x41), isTrue);
    expect(cmaps['Noto Sans Devanagari']!.contains(0x0930), isTrue);
    expect(cmaps['Inter']!.contains(0x202F), isTrue);
  });

  test('Barlow plus production fallbacks cover dashboard UI punctuation', () {
    final covered = chain(WebTypography.fontFamily);
    expect(
      covered,
      containsAll(const [0x00A9, 0x2022, 0x2026, 0x2014, 0x202F]),
    );
  });

  test(
    'Spectral plus production fallbacks cover dashboard metric punctuation',
    () {
      final covered = chain(WebTypography.serifFamily);
      expect(
        covered,
        containsAll(const [0x2026, 0x2014, 0x0930, 0x0942, 0x202F]),
      );
    },
  );

  test('IBM Plex plus production fallbacks cover money Devanagari', () {
    final covered = chain(WebTypography.monoFamily);
    expect(covered, containsAll(const [0x0930, 0x0942, 0x202F]));
  });
}
