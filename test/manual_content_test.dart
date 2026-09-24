import 'package:ad_shop_pos/modules/manual/manual_content.dart';
import 'package:ad_shop_pos/modules/manual/manual_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integrity tests for the in-app manual's content graph.
///
/// The manual is authored as plain data, so a typo in a `relatedIds` entry or
/// a duplicated id would only show up as a broken link at runtime. These tests
/// catch that at build time instead.
void main() {
  test('guide ids are unique', () {
    final ids = ManualGuides.all.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate guide id');
  });

  test('every quick-start reference resolves', () {
    for (final id in ManualGuides.quickStartIds) {
      expect(ManualGuides.byId(id), isNotNull, reason: 'unknown quick-start id "$id"');
    }
    expect(ManualGuides.quickStart().length, ManualGuides.quickStartIds.length);
  });

  test('every related-guide reference resolves', () {
    for (final guide in ManualGuides.all) {
      for (final id in guide.relatedIds) {
        expect(
          ManualGuides.byId(id),
          isNotNull,
          reason: 'guide "${guide.id}" links to unknown guide "$id"',
        );
      }
      // A guide should never link to itself.
      expect(guide.relatedIds.contains(guide.id), isFalse);
    }
  });

  test('every topic has at least one guide', () {
    for (final category in ManualCategory.values) {
      expect(
        ManualGuides.inCategory(category),
        isNotEmpty,
        reason: 'category "${category.label}" has no guides',
      );
    }
  });

  test('action buttons are wired to a tab or a route, never neither', () {
    for (final guide in ManualGuides.all) {
      for (final action in guide.blocks.whereType<ManualAction>()) {
        final hasTab = action.tabIndex != null;
        final hasRoute = action.route != null && action.route!.isNotEmpty;
        expect(
          hasTab || hasRoute,
          isTrue,
          reason: 'action "${action.label}" in "${guide.id}" goes nowhere',
        );
        if (hasTab) {
          // The shell has five tabs — 0 Home … 4 More.
          expect(action.tabIndex, inInclusiveRange(0, 4));
        }
        if (hasRoute) {
          expect(action.route!.startsWith('/'), isTrue);
        }
      }
    }
  });

  test('byId returns null for an unknown guide', () {
    expect(ManualGuides.byId('does-not-exist'), isNull);
  });

  group('search', () {
    test('finds guides by a keyword that is not in the title', () {
      final results = ManualGuides.search('refund');
      expect(results, isNotEmpty);
      expect(results.map((g) => g.id), contains('returns'));
    });

    test('ranks title matches before body matches', () {
      final results = ManualGuides.search('backup');
      expect(results, isNotEmpty);
      // The backup guides come first when searching "backup".
      expect(results.first.title.toLowerCase(), contains('backup'));
    });

    test('is case-insensitive and trims whitespace', () {
      expect(ManualGuides.search('  PRINTER  '), isNotEmpty);
    });

    test('an empty query returns every guide', () {
      expect(ManualGuides.search('   ').length, ManualGuides.all.length);
    });

    test('a nonsense query finds nothing', () {
      expect(ManualGuides.search('zzzqqqxyz'), isEmpty);
    });
  });
}
