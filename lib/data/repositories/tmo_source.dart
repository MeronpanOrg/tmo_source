import 'package:dio/dio.dart';
import 'package:http_source/models/filter_list.dart';
import 'package:http_source/models/manga.dart';
import 'package:http_source/models/manga_details.dart';
import 'package:http_source/models/mangas_page.dart';
import 'package:tmo_source/data/data_sources/remote/filters/tmo_request.dart';
import 'package:tmo_source/data/data_sources/remote/tmo_data_source.dart';
import 'package:tmo_source/domain/repositories/itmo_source.dart';

class TmoSource extends ITmoSource {
  final TmoDataSource source;

  @override
  String get id => '$baseUrl/$lang/$versionId';

  TmoSource(this.source);

  @override
  Future<MangasPage> fetchPopularManga(int page) async {
    late MangasPage mangasPage;
    try {
      final res = await source.popularMangaRequest(page);
      mangasPage = await source.popularMangaParse(res);
    } on DioError catch (_) {
      return MangasPage([], false);
    }
    return mangasPage;
  }

  @override
  Future<MangasPage> fetchLatestUpdates(int page) async {
    late MangasPage mangasPage;
    try {
      final res = await source.latestUpdatesRequest(page);
      mangasPage = await source.latestUpdatesParse(res);
    } on DioError catch (_) {
      return MangasPage([], false);
    }
    return mangasPage;
  }

  @override
  Future<MangaDetails> fetchMangaDetails(Manga manga) async {
    late MangaDetails mangaDetails;
    try {
      final res = await source.mangaDetailsRequest(manga);
      final mangaParsed = await source.mangaDetailsParse(res);
      final chapters = await source.chapterListParse(res);

      mangaDetails = MangaDetails(manga: mangaParsed, chapters: chapters);
    } on DioError catch (_) {
      return MangaDetails(manga: manga, chapters: []);
    }
    return mangaDetails;
  }

  @override
  Future<MangasPage> fetchSearchManga(
      int page, String query, FilterList filterList) async {
    late MangasPage mangasPage;
    try {
      final res = await source.searchMangaRequest(page, query, filterList);
      mangasPage = await source.popularMangaParse(res);
    } on DioError catch (_) {
      return MangasPage([], false);
    }
    return mangasPage;
  }

  @override
  FilterList getFilterList() {
    return TMORequest.init().getFilterList();
  }
}
