import 'package:flutter_test/flutter_test.dart';
import 'package:i_cant_cook/utils/instagram_share.dart';

void main() {
  group('InstagramShare.extractInstagramUrl', () {
    test('accepts reel / p / tv / reels path kinds', () {
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/reel/ABC123/'),
        'https://www.instagram.com/reel/ABC123/',
      );
      expect(
        InstagramShare.extractInstagramUrl('https://instagram.com/p/XYZ789/'),
        'https://instagram.com/p/XYZ789/',
      );
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/tv/QQQ/'),
        'https://www.instagram.com/tv/QQQ/',
      );
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/reels/RRR/'),
        'https://www.instagram.com/reels/RRR/',
      );
    });

    test('accepts the /<user>/reel/<id> shape', () {
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/chef.jo/reel/ABC123/'),
        'https://www.instagram.com/chef.jo/reel/ABC123/',
      );
    });

    test('extracts a URL embedded in shared caption text', () {
      const shared =
          'Best pasta ever 🍝 check it out https://www.instagram.com/reel/ABC123/ #recipe';
      expect(
        InstagramShare.extractInstagramUrl(shared),
        'https://www.instagram.com/reel/ABC123/',
      );
    });

    test('strips tracking query params and fragments', () {
      expect(
        InstagramShare.extractInstagramUrl(
            'https://www.instagram.com/reel/ABC123/?igsh=abcd&utm_source=ig#foo'),
        'https://www.instagram.com/reel/ABC123/',
      );
    });

    test('handles instagr.am short host', () {
      expect(
        InstagramShare.extractInstagramUrl('https://instagr.am/p/XYZ/'),
        'https://instagr.am/p/XYZ/',
      );
    });

    test('returns null for non-Instagram hosts', () {
      expect(
        InstagramShare.extractInstagramUrl('https://www.tiktok.com/@x/video/1'),
        isNull,
      );
      expect(
        InstagramShare.extractInstagramUrl('https://example.com/recipe/p/1/'),
        isNull,
      );
    });

    test('returns null for Instagram profile/home links (no post id)', () {
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/chef.jo/'),
        isNull,
      );
      expect(
        InstagramShare.extractInstagramUrl('https://www.instagram.com/'),
        isNull,
      );
    });

    test('returns null when there is no URL at all', () {
      expect(InstagramShare.extractInstagramUrl('just some text'), isNull);
      expect(InstagramShare.extractInstagramUrl(''), isNull);
    });

    test('isInstagramShare mirrors extract', () {
      expect(InstagramShare.isInstagramShare('https://www.instagram.com/reel/A/'), isTrue);
      expect(InstagramShare.isInstagramShare('https://www.instagram.com/chef/'), isFalse);
    });
  });
}
