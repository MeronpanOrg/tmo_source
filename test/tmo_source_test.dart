import 'package:flutter_test/flutter_test.dart';
import 'package:http_source/http_source.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tmo_source/data/data_sources/remote/filters/tmo_filters.dart';
import 'package:tmo_source/data/data_sources/remote/tmo_source.dart';
import 'package:tmo_source/data/repositories/tmo_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final sourceProvider = StateProvider<AHttpSource>((ref) {
  return TmoRepository(
    TmoSource(dio: ref.read(dioProvider), isSFWMode: false, showAllScans: true),
  );
});

void main() {
  final container = ProviderContainer();
  final source = container.read(sourceProvider);

  test(
    'search berserk',
    () async {
      final mangaPages = await source.fetchSearchManga(
        1,
        'berserk',
        FilterList(
          list: [
            const TypeSelection(),
            const DemographySelection(),
            const StatusSelection(),
            const TranslationStatusSelection(),
            const FilterBySelection(),
            Sort(values: sortables, state: Direction(index: 0)),
            ContentTypeList(content: content),
            GenreList(genres: genres)
          ],
        ),
      );
      expect(mangaPages.mangas.isNotEmpty, true);
    },
  );

  test(
    'Get populars',
    () async {
      final mangasPage = await source.fetchPopularManga(1);
      expect(mangasPage.mangas.isNotEmpty && mangasPage.hasNextpage, true);
    },
  );
  test(
    'Get latest',
    () async {
      final mangasPage = await source.fetchLatestUpdates(1);
      expect(mangasPage.mangas.isNotEmpty && mangasPage.hasNextpage, true);
    },
  );
  test(
    'Get 10 populars',
    () async {
      List<MangasPage?> mangasPages = [];
      const oneSec = Duration(seconds: 1);
      await Future.forEach<int>(
        List<int>.generate(10, (index) => index + 1),
        (element) async {
          await Future.delayed(
            oneSec,
            () async {
              final mangasPage = await source.fetchPopularManga(element);
              mangasPages.add(mangasPage);
            },
          );
        },
      );
      // print(mangasPages);

      expect(mangasPages.length, equals(10));
    },
  );
  test(
    'Get manga details',
    () async {
      final manga = Manga(
          title: 'Hajimete no Sameshima-kun',
          url:
              'https://lectortmo.com/library/manga/53882/hajimete-no-sameshima-kun',
          thumbnailUrl:
              'https://otakuteca.com/images/books/cover/5f776cf4b7571.jpg');
      final res = await source.fetchMangaDetails(manga);

      expect(res.manga.description.isNotEmpty, true);
    },
  );
}
