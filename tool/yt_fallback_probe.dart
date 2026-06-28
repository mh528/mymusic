// Live probe: verifies the youtube_explode_dart fallback path works independently
// of the ANDROID_VR direct path. Uses a fake HttpClient that always returns
// LOGIN_REQUIRED to force the fallback, then confirms a URL is returned.
// Usage: dart run tool/yt_fallback_probe.dart [videoId]
// Exit 0 = pass. Exit 1 = fallback is broken.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mymusic/data/youtube_music_service.dart';
import 'package:mymusic/models/settings.dart';

/// HttpClient that always responds with a LOGIN_REQUIRED player response,
/// forcing YouTubeMusicService to skip the direct path and use the fallback.
class _LoginRequiredClient implements HttpClient {
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeRequest();

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

class _FakeRequest implements HttpClientRequest {
  final _response = _FakeResponse();
  @override
  void write(Object? obj) {}
  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  Future<HttpClientResponse> close() async => _response;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final _body = jsonEncode({
    'playabilityStatus': {'status': 'LOGIN_REQUIRED', 'reason': 'forced by probe'},
  });

  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode(_body)).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

Future<void> main(List<String> args) async {
  final videoId = args.isNotEmpty ? args[0] : 'dQw4w9WgXcQ';
  print('--- yt_fallback_probe: videoId=$videoId ---');
  print('(Direct path forced to LOGIN_REQUIRED — testing explode fallback only)');

  final svc = YouTubeMusicService(createClient: () => _LoginRequiredClient());
  bool ok = false;

  try {
    final url = await svc.getStreamUrl(videoId, quality: AudioQuality.auto);
    if (url == null) {
      print('FALLBACK_NULL — explode fallback returned null');
    } else {
      print('FALLBACK_OK len=${url.length}');
      ok = true;
    }
  } catch (e, st) {
    print('FALLBACK_ERROR: $e\n$st');
  } finally {
    svc.dispose();
  }

  print('--- ${ok ? "PASS" : "FAIL"} ---');
  exit(ok ? 0 : 1);
}
