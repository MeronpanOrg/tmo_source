import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http_source/models/filter.dart' show TriState;
import 'package:http_source/models/chapter.dart';
import 'package:http_source/models/filter_list.dart';
import 'package:http_source/models/manga.dart';
import 'package:http_source/models/mangas_page.dart';
import 'package:tmo_source/data/data_sources/remote/filters/tmo_filters.dart';

class TmoSource {
  final Dio dio;
  final bool isSFWMode;
  final bool showAllScans;

  TmoSource(
      {required this.dio, required this.isSFWMode, required this.showAllScans});

  Dio get client => dio;
  String get baseUrl => 'https://lectortmo.com';

  String get _oneShotChapterListSelector => 'li.list-group-item';
  String get _regularChapterListSelector => 'li.p-0.list-group-item';

  final sfwGenderId = ['6', '17', '18', '19'];

  String get getSFWUrlPart => isSFWMode
      ? ''
      : '&exclude_genders%5B%5D=6&exclude_genders%5B%5D=17&'
          'exclude_genders%5B%5D=18&exclude_genders%5B%5D=19&erotic=false';

  Future<Response> popularMangaRequest(int page) async {
    final response = await client.get(
        '$baseUrl/library?order_item=likes_count&order_dir=desc&filter_by=title$getSFWUrlPart&_pg=1&page=$page',
        options: Options(responseType: ResponseType.plain));

    return response;
  }

  Future<MangasPage> popularMangaParse(Response response) async {
    final document = parse(response.data);

    final mangas = document
        .querySelectorAll('div.element')
        .map((e) => popularMangaFromElement(e))
        .toList();

    final hasNextPage = document.querySelector('a.page-link');

    return MangasPage(mangas, hasNextPage != null);
  }

  Future<MangasPage?> fetchPopularManga(int page) async {
    MangasPage? mangasPage;
    try {
      final res = await popularMangaRequest(page);
      mangasPage = await popularMangaParse(res);
    } on DioError  {
      // print(e.message);
    }
    return mangasPage;
  }

  Future<Response> latestUpdatesRequest(int page) async {
    final response = await client.get(
        '$baseUrl/library?order_item=creation&order_dir=desc&filter_by=title$getSFWUrlPart&_pg=1&page=$page',
        options: Options(responseType: ResponseType.plain));

    return response;
  }

  Future<MangasPage> latestUpdatesParse(Response response) async {
    final document = parse(response.data);

    final mangas = document
        .querySelectorAll('div.element')
        .map((e) => popularMangaFromElement(e))
        .toList();

    final hasNextPage = document.querySelector('a.page-link');

    return MangasPage(mangas, hasNextPage != null);
  }

  Future<MangasPage?> fetchLatestUpdates(int page) async {
    MangasPage? mangasPage;
    try {
      final res = await latestUpdatesRequest(page);
      mangasPage = await latestUpdatesParse(res);
    } catch (e) {
      // print(e);
    }
    return mangasPage;
  }

  Future<Response> searchMangaRequest(
      int page, String query, FilterList filters) async {
    final Map<String, String> queryParams = {};

    queryParams.addAll({'page': '$page'});
    queryParams.addAll({'_pg': '1'});
    queryParams.addAll({'title': query});

    if (isSFWMode) {
      for (String element in sfwGenderId) {
        queryParams.addAll({'exlude_gender[]': element});
      }
    }

    for (var element in filters.list) {
      if (element is TypeSelection) {
        queryParams.addAll({'type': (element).toUriPart()});
      }
      if (element is DemographySelection) {
        queryParams.addAll({'demography': (element).toUriPart()});
      }
      if (element is StatusSelection) {
        queryParams.addAll({'status': (element).toUriPart()});
      }
      if (element is TranslationStatusSelection) {
        queryParams.addAll({'translation_status': (element).toUriPart()});
      }
      if (element is FilterBySelection) {
        queryParams.addAll({'filter_by': element.toUriPart()});
      }
      if (element is Sort) {
        if (element.state != null) {
          queryParams
              .addAll({'order_item': sortables[element.state!.index].value});
          queryParams
              .addAll({'order_dir': element.state!.ascending ? 'asc' : 'desc'});
        }
      }
      if (element is ContentTypeList) {
        for (var content in element.content) {
          // If (SFW mode is not enabled) OR (SFW mode is enabled AND filter != erotic) -> Apply filter
          // else -> ignore filter
          if (content.id != 'erotic') {
            switch (content.state) {
              case TriState.stateIgnore:
                queryParams.addAll({content.id: ''});
                break;
              case TriState.stateInclude:
                queryParams.addAll({content.id: 'true'});
                break;
              case TriState.stateExclude:
                queryParams.addAll({content.id: 'false'});
                break;
            }
          }
        }
      }
      if (element is GenreList) {
        for (var genre in element.genres) {
          switch (genre.state) {
            case TriState.stateIgnore:
              break;
            case TriState.stateInclude:
              queryParams.addAll({'genders': genre.id});
              break;
            case TriState.stateExclude:
              queryParams.addAll({'exclude_genders': genre.id});
              break;
          }
        }
      }
    }
    final Uri url = Uri.https('lectortmo.com', '/library', queryParams);

    // print(url.toString());

    final response = await client.getUri(url,
        options: Options(responseType: ResponseType.plain));

    return response;
  }

  Future<MangasPage> searchMangaParse(Response response) async {
    final document = parse(response.data);

    final mangas = document
        .querySelectorAll('div.element')
        .map((e) => popularMangaFromElement(e))
        .toList();

    final hasNextPage = document.querySelector('a.page-link');

    return MangasPage(mangas, hasNextPage != null);
  }

  Future<MangasPage?> fetchSearchManga(
      int page, String query, FilterList filterList) async {
    MangasPage? mangasPage;
    try {
      final res = await searchMangaRequest(page, query, filterList);
      // print(res.realUri.toString());
      mangasPage = await searchMangaParse(res);
    } catch (e) {
      // print(e);
    }
    return mangasPage;
  }

  Manga popularMangaFromElement(Element element) {
    final link = element.querySelector('a');
    final title = element.querySelector('h4.text-truncate');
    final cover = element.querySelector('style');

    final path = cover!.text;

    final start = path.indexOf('(\'') + 2;
    final end = path.indexOf('\')');

    final thumbnailUrl = path.substring(start, end);

    return Manga(
      url: link!.attributes['href']!.trim(),
      title: title!.text,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<Response> mangaDetailsRequest(Manga manga) async {
    final response = await client.get(manga.url,
        options: Options(responseType: ResponseType.plain));

    return response;
  }

  Future<Manga> mangaDetailsParse(Response response) async {
    final document = parse(response.data);

    final title =
        document.querySelector('h2.element-subtitle')?.text ?? ' Sin titulo';

    final list = document.querySelectorAll('h5.card-title');

    String author = 'Sin autor';
    String artist = 'Sin artista';

    if (list.isNotEmpty) {
      author = list[0].attributes['title']?.replaceAll(',', '') ?? 'Sin autor';

      if (list.length > 1) {
        artist =
            list[1].attributes['title']?.replaceAll(',', '') ?? 'Sin artista';
      }
    }

    final description = document.querySelector('p.element-description')?.text ??
        'Sin descripcion';

    final status =
        parseStatus(document.querySelector('span.book-status')?.text ?? '');
    final thumbnailUrl =
        document.querySelector('.book-thumbnail')?.attributes['src'] ?? '';

    return Manga(
        title: title,
        url: response.requestOptions.path,
        description: description,
        author: author,
        artist: artist,
        status: status,
        thumbnailUrl: thumbnailUrl);
  }

  Chapter oneShotChapterFromElement(Element element) {
    final url =
        element.querySelector('div.row > .text-right > a')?.attributes['href'];
    const name = 'One Shot';
    final scanlator =
        element.querySelector('div.col-md-6.text-truncate')?.text.trim();

    return Chapter(
        url: url!,
        name: name,
        dateUpload: 1,
        chapterNumber: 1,
        scanlator: scanlator!);
  }

  Chapter regularChapterFromElement(
      Element element, String chName, String number) {
    final url = element
            .querySelector('div.row > .text-right > a')
            ?.attributes['href'] ??
        '';
    final name = chName;
    final chapterNumber = double.parse(number);
    final scanlator =
        element.querySelector('div.col-md-6.text-truncate')?.text.trim() ?? '';
    final dateUpload =
        element.querySelector('span.badge.badge-primary.p-2')?.text;

    return Chapter(
        url: url,
        name: name,
        dateUpload: 1,
        chapterNumber: chapterNumber,
        scanlator: scanlator);
  }

  Future<List<Chapter>> chapterListParse(Response response) async {
    final document = parse(response.data);

    // One-shot
    if (document.querySelectorAll('div.chapters').isEmpty) {
      return document
          .querySelectorAll(_oneShotChapterListSelector)
          .map((e) => oneShotChapterFromElement(e))
          .toList();
    }

    List<Chapter> chapters = [];

    document.querySelectorAll(_regularChapterListSelector).forEach((element) {
      final chapternumber =
          element.querySelector('a.btn-collapse')?.text ?? 'SN';
      String num = '';
      if (chapternumber.contains(':')) {
        final end = chapternumber.indexOf(':');
        final t = chapternumber.substring(0, end);
        num = t.substring(t.indexOf('o') + 1).trim();
      } else {
        num = chapternumber.substring(chapternumber.indexOf('o') + 1).trim();
      }

      final name =
          element.querySelector('div.col-10.text-truncate')?.text.trim() ??
              'Sin nombre';

      var translators = element.querySelectorAll('ul.chapter-list > li');

      if (showAllScans) {
        var scans = translators
            .map((e) => regularChapterFromElement(e, name, num))
            .toList();
        chapters.addAll(scans);
      } else {
        var scan = regularChapterFromElement(translators.first, name, num);
        chapters.add(scan);
      }
    });
    return chapters;
  }

  Future<MangasPage?> fetchMangaDetails(Manga manga) async {
    Manga? details;
    try {
      final res = await mangaDetailsRequest(manga);
      details = await mangaDetailsParse(res);
    } catch (e) {
      // print(e);
    }
    return MangasPage([details!], false);
  }

  statusEnum parseStatus(String status) {
    switch (status) {
      case 'Publicándose':
        return statusEnum.ongoing;
      case 'Finalizado':
        return statusEnum.completed;
    }
    return statusEnum.unknown;
  }
}
