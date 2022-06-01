import 'package:riverpod/riverpod.dart';
import 'package:http_source/models/filter.dart' show TriState;
import 'package:tmo_source/data/data_sources/remote/filters/tmo_filters.dart';
import 'package:tmo_source/data/data_sources/remote/filters/tmo_request.dart';


final tmoFilterProvider =
    StateNotifierProvider<TMOFilterNotifier, TMORequest>((ref) {
  return TMOFilterNotifier();
});

class TMOFilterNotifier extends StateNotifier<TMORequest> {
  TMOFilterNotifier()
      : super(
          TMORequest.init(),
        );

  void restore() {
    state = TMORequest.init();
  }

  void changeTypeSelectionState(int newIndex) {
    state = state.copyWith(typeSelection: TypeSelection(state: newIndex));
  }

  void changeStatusSelectionState(int newIndex) {
    state = state.copyWith(statusSelection: StatusSelection(state: newIndex));
  }

  void changeTranslationStatusSelectionState(int newIndex) {
    state = state.copyWith(
        translationStatusSelection:
            TranslationStatusSelection(state: newIndex));
  }

  void changeDemographySelectionState(int newIndex) {
    state = state.copyWith(
        demographySelection: DemographySelection(state: newIndex));
  }

  void changeFilterBySelectionState(int newIndex) {
    state =
        state.copyWith(filterBySelection: FilterBySelection(state: newIndex));
  }

  void changeSortState(int newIndex, bool ascending) {
    final newState = Direction(index: newIndex, ascending: ascending);

    final sort = state.sort.copyWith(state: newState);

    state = state.copyWith(sort: sort);
  }

  void changeContentTypeListState(int index, bool? check) {
    final list = [...state.contentTypeList.content];

    final copy = list[index].copy();

    ContentType newValue;

    if (check == null) {
      newValue = copy.copyWith(state: TriState.stateExclude);
    } else if (check == true) {
      newValue = copy.copyWith(state: TriState.stateInclude);
    } else {
      newValue = copy.copyWith(state: TriState.stateIgnore);
    }

    list.removeAt(index);
    list.insert(index, newValue);

    state = state.copyWith(contentTypeList: ContentTypeList(content: list));
  }

  void changeGenreListState(int index, bool? check) {
    final list = [...state.genreList.genres];

    final copy = list[index].copy();

    Genre newValue;

    if (check == null) {
      newValue = copy.copyWith(state: TriState.stateExclude);
    } else if (check == true) {
      newValue = copy.copyWith(state: TriState.stateInclude);
    } else {
      newValue = copy.copyWith(state: TriState.stateIgnore);
    }

    list.removeAt(index);
    list.insert(index, newValue);

    state = state.copyWith(genreList: GenreList(genres: list));
  }
}
