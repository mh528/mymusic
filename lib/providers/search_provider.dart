import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/music_repository.dart';
import 'yt_library_provider.dart';

class SearchState {
  final String query;
  final SearchResults results;
  final List<String> history;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.results = const SearchResults(),
    this.history = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    List<String>? history,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        results: const SearchResults(),
        isLoading: false,
      );
      return;
    }

    // Prepend to history, deduplicate, cap at 10
    final history = [
      query,
      ...state.history.where((h) => h != query),
    ].take(10).toList();

    state = state.copyWith(
      query: query,
      history: history,
      isLoading: true,
    );

    // Search YouTube Music anonymously
    try {
      final ytSvc = ref.read(youtubeMusicServiceProvider);
      final results = await ytSvc.search(query);
      state = state.copyWith(
        results: results,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        results: const SearchResults(),
        isLoading: false,
      );
    }
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  void clearQuery() {
    state = state.copyWith(
      query: '',
      results: const SearchResults(),
      isLoading: false,
    );
  }
}
