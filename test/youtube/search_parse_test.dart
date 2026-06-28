import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mymusic/data/youtube_music_service.dart';

// Fake HttpClient that returns a preset response for search POST requests.
// The player endpoint (getStreamUrlDirect) is not exercised here.
class _FakeSearchClient implements HttpClient {
  final String responseBody;
  final int statusCode;
  _FakeSearchClient(this.responseBody, {this.statusCode = 200});

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _FakeRequest(responseBody, statusCode);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

class _FakeRequest implements HttpClientRequest {
  final String body;
  final int status;
  _FakeRequest(this.body, this.status);

  @override
  void write(Object? obj) {}

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(body, status);

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
    return Stream.value(utf8.encode(_body))
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError(i.memberName.toString());
}

YouTubeMusicService _svcWith(String json, {int status = 200}) =>
    YouTubeMusicService(createClient: () => _FakeSearchClient(json, statusCode: status));

// Minimal response with no contents key — tests graceful degradation.
const _emptyResponse = '{"responseContext":{}}';

// HTML error page — simulates YouTube returning non-JSON.
const _htmlResponse = '<!DOCTYPE html><html><body>Error 429</body></html>';

String _wrapSections(List<Map<String, dynamic>> sections) => jsonEncode({
      'contents': {
        'tabbedSearchResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'sectionListRenderer': {'contents': sections}
                }
              }
            }
          ]
        }
      }
    });

Map<String, dynamic> _songItem(String videoId, String title, String artist) => {
      'musicResponsiveListItemRenderer': {
        'overlay': {
          'musicItemThumbnailOverlayRenderer': {
            'content': {
              'musicPlayButtonRenderer': {
                'playNavigationEndpoint': {
                  'watchEndpoint': {'videoId': videoId}
                }
              }
            }
          }
        },
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': title}
                ]
              }
            }
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Song'},
                  {'text': ' • '},
                  {'text': artist},
                ]
              }
            }
          },
        ],
        'thumbnail': {'musicThumbnailRenderer': {'thumbnail': {'thumbnails': []}}},
        'fixedColumns': [
          {
            'musicResponsiveListItemFixedColumnRenderer': {
              'text': {
                'runs': [
                  {'text': '3:45'}
                ]
              }
            }
          }
        ],
      }
    };

Map<String, dynamic> _albumSection(String title, String artist, String browseId) => {
      'itemSectionRenderer': {
        'contents': [
          {
            'musicResponsiveListItemRenderer': {
              'navigationEndpoint': {
                'browseEndpoint': {'browseId': browseId}
              },
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': title}
                      ]
                    }
                  }
                },
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Album'},
                        {'text': ' • '},
                        {'text': artist},
                        {'text': ' • '},
                        {'text': '2020'},
                      ]
                    }
                  }
                },
              ],
            }
          }
        ]
      }
    };

Map<String, dynamic> _artistSection(String name, String browseId) => {
      'itemSectionRenderer': {
        'contents': [
          {
            'musicResponsiveListItemRenderer': {
              'navigationEndpoint': {
                'browseEndpoint': {'browseId': browseId}
              },
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': name}
                      ]
                    }
                  }
                },
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Artist'}
                      ]
                    }
                  }
                },
              ],
            }
          }
        ]
      }
    };

void main() {
  group('YouTubeMusicService search parsing', () {
    test('parses song from itemSectionRenderer', () async {
      final json = _wrapSections([
        {'itemSectionRenderer': {'contents': [_songItem('abc123', 'Creep', 'Radiohead')]}}
      ]);
      final svc = _svcWith(json);
      final results = await svc.search('Radiohead');
      svc.dispose();

      expect(results.songs, hasLength(1));
      expect(results.songs.first.videoId, 'abc123');
      expect(results.songs.first.title, 'Creep');
      expect(results.songs.first.artist, 'Radiohead');
      expect(results.songs.first.id, 'yt_abc123');
    });

    test('parses album from itemSectionRenderer', () async {
      final json = _wrapSections([_albumSection('Pablo Honey', 'Radiohead', 'MPREb_xyz')]);
      final svc = _svcWith(json);
      final results = await svc.search('Radiohead');
      svc.dispose();

      expect(results.albums, hasLength(1));
      expect(results.albums.first.title, 'Pablo Honey');
      expect(results.albums.first.artist, 'Radiohead');
      expect(results.albums.first.id, 'MPREb_xyz');
      expect(results.albums.first.year, 2020);
    });

    test('parses artist from itemSectionRenderer', () async {
      final json = _wrapSections([_artistSection('Radiohead', 'UCq19-LqvG35A-30oyAiPiqA')]);
      final svc = _svcWith(json);
      final results = await svc.search('Radiohead');
      svc.dispose();

      expect(results.artists, hasLength(1));
      expect(results.artists.first.name, 'Radiohead');
      expect(results.artists.first.id, 'UCq19-LqvG35A-30oyAiPiqA');
    });

    test('song with missing videoId is skipped', () async {
      // Item without overlay/watchEndpoint → no videoId → _parseSong returns null
      final json = _wrapSections([
        {
          'itemSectionRenderer': {
            'contents': [
              {
                'musicResponsiveListItemRenderer': {
                  'flexColumns': [
                    {'musicResponsiveListItemFlexColumnRenderer': {'text': {'runs': [{'text': 'No ID Song'}]}}},
                    {'musicResponsiveListItemFlexColumnRenderer': {'text': {'runs': [{'text': 'Song'}]}}},
                  ],
                }
              }
            ]
          }
        }
      ]);
      final svc = _svcWith(json);
      final results = await svc.search('test');
      svc.dispose();

      expect(results.songs, isEmpty);
    });

    test('missing tabbedSearchResultsRenderer returns empty without throwing', () async {
      final svc = _svcWith(_emptyResponse);
      final results = await svc.search('test');
      svc.dispose();

      expect(results.songs, isEmpty);
      expect(results.albums, isEmpty);
      expect(results.artists, isEmpty);
    });

    test('HTML body (non-JSON) returns empty without throwing', () async {
      final svc = _svcWith(_htmlResponse);
      final results = await svc.search('test');
      svc.dispose();

      expect(results.songs, isEmpty);
    });

    test('parses multiple songs and albums together', () async {
      final json = _wrapSections([
        {'itemSectionRenderer': {'contents': [_songItem('v1', 'Song One', 'Artist A')]}},
        {'itemSectionRenderer': {'contents': [_songItem('v2', 'Song Two', 'Artist B')]}},
        _albumSection('Album One', 'Artist A', 'MPREb_1'),
      ]);
      final svc = _svcWith(json);
      final results = await svc.search('test');
      svc.dispose();

      expect(results.songs, hasLength(2));
      expect(results.albums, hasLength(1));
    });

    test('real fixture file parses without error', () async {
      final fixtureJson = File('test/fixtures/yt_search_sample.json').readAsStringSync();
      final svc = _svcWith(fixtureJson);
      final results = await svc.search('Radiohead');
      svc.dispose();

      // The fixture has real data — just verify it doesn't crash and returns something
      expect(results.songs.length + results.albums.length + results.artists.length,
          greaterThan(0));
      // All songs must have non-empty videoId
      for (final song in results.songs) {
        expect(song.videoId, isNotEmpty);
      }
    });
  });
}
