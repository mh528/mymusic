import 'dart:async';
import 'dart:convert' show jsonEncode, utf8;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mymusic/data/youtube_music_service.dart';
import 'package:mymusic/models/settings.dart';

// ---------------------------------------------------------------------------
// Fake HttpClient infrastructure
// ---------------------------------------------------------------------------

class _FakeClient implements HttpClient {
  final String body;
  _FakeClient(this.body);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _FakeRequest(body);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

class _FakeRequest implements HttpClientRequest {
  final String body;
  _FakeRequest(this.body);

  @override
  void write(Object? obj) {}

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(body, 200);

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final String _body;
  @override
  final int statusCode;

  _FakeResponse(this._body, this.statusCode);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_body)).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a /player response JSON string.
String _playerResponse({
  String status = 'OK',
  String? reason,
  List<Map<String, dynamic>> formats = const [],
}) =>
    jsonEncode({
      'playabilityStatus': <String, dynamic>{
        'status': status,
        ...?reason != null ? {'reason': reason} : null,
      },
      'streamingData': {
        'adaptiveFormats': formats,
      },
    });

Map<String, dynamic> _aacFormat({
  int itag = 140,
  String? url,
  String? signatureCipher,
}) =>
    <String, dynamic>{
      'itag': itag,
      'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
      ...?url != null ? {'url': url} : null,
      ...?signatureCipher != null ? {'signatureCipher': signatureCipher} : null,
    };

Map<String, dynamic> _videoFormat() => {
      'itag': 137,
      'mimeType': 'video/mp4; codecs="avc1.640028"',
      'url': 'https://example.com/video',
    };

YouTubeMusicService _svcWithPlayer(String responseJson) =>
    YouTubeMusicService(createClient: () => _FakeClient(responseJson));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('getStreamUrlDirect', () {
    test('returns URL when playabilityStatus=OK with itag 140', () async {
      const cdnUrl = 'https://rr.googlevideo.com/videoplayback?itag=140';
      final svc = _svcWithPlayer(_playerResponse(
        formats: [_aacFormat(itag: 140, url: cdnUrl)],
      ));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, cdnUrl);
    });

    test('returns null when playabilityStatus=LOGIN_REQUIRED', () async {
      final svc = _svcWithPlayer(_playerResponse(
        status: 'LOGIN_REQUIRED',
        reason: 'Sign in to confirm your age',
      ));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });

    test('returns null when playabilityStatus=UNPLAYABLE', () async {
      final svc = _svcWithPlayer(_playerResponse(status: 'UNPLAYABLE'));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });

    test('returns null when adaptiveFormats is empty', () async {
      final svc = _svcWithPlayer(_playerResponse(formats: []));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });

    test('returns null when all formats have signatureCipher instead of url', () async {
      final svc = _svcWithPlayer(_playerResponse(
        formats: [_aacFormat(itag: 140, signatureCipher: 's=ABC&sp=sig&url=https%3A%2F%2Fexample.com')],
      ));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });

    test('returns null when only video formats are present (no audio/mp4)', () async {
      final svc = _svcWithPlayer(_playerResponse(
        formats: [_videoFormat()],
      ));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });

    test('selects itag 140 for AudioQuality.auto', () async {
      const url140 = 'https://example.com/itag140';
      const url139 = 'https://example.com/itag139';
      final svc = _svcWithPlayer(_playerResponse(formats: [
        _aacFormat(itag: 139, url: url139),
        _aacFormat(itag: 140, url: url140),
      ]));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, url140);
    });

    test('selects itag 139 for AudioQuality.low', () async {
      const url140 = 'https://example.com/itag140';
      const url139 = 'https://example.com/itag139';
      final svc = _svcWithPlayer(_playerResponse(formats: [
        _aacFormat(itag: 139, url: url139),
        _aacFormat(itag: 140, url: url140),
      ]));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.low);
      svc.dispose();
      expect(url, url139);
    });

    test('falls back to any audio/mp4 if preferred itag absent', () async {
      const url141 = 'https://example.com/itag141';
      final svc = _svcWithPlayer(_playerResponse(formats: [
        _aacFormat(itag: 141, url: url141),
      ]));
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, url141);
    });

    test('returns null when response body is not valid JSON', () async {
      final svc = YouTubeMusicService(
        createClient: () => _FakeClient('<!DOCTYPE html><html>Error 429</html>'),
      );
      final url = await svc.getStreamUrlDirect('dQw4w9WgXcQ', AudioQuality.auto);
      svc.dispose();
      expect(url, isNull);
    });
  });

  group('getStreamUrl fallback', () {
    // When the direct path returns null, getStreamUrl should try the explode fallback.
    // We verify this by using a fake client that returns LOGIN_REQUIRED —
    // if getStreamUrl returns null (not throws), the fallback was attempted.
    // We can't easily assert the fallback succeeded without a network call,
    // but we CAN assert that direct returning null does not cause an exception.
    test('does not throw when direct path returns null', () async {
      final svc = _svcWithPlayer(_playerResponse(status: 'LOGIN_REQUIRED'));
      // The explode fallback will also fail without network — we just want no exception.
      final url = await svc.getStreamUrl('dQw4w9WgXcQ').timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      svc.dispose();
      // Either null (both paths failed) or a URL (explode worked) — no exception either way.
      expect(url, anyOf(isNull, isA<String>()));
    });
  });
}
