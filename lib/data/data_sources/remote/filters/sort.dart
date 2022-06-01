import 'package:http_source/models/filter.dart';
import 'package:http_source/utils/pair.dart';

class Direction {
  final int index;
  final bool ascending;

  Direction({required this.index, this.ascending = false});
}

class Sort extends FilterSort<Direction?, Pair> {
  const Sort({required List<Pair> values, required Direction? state})
      : super(name: 'Ordenar por', values: values, state: state);

  Sort copyWith({Direction? state}) {
    return Sort(values: values, state: state ?? this.state);
  }
}

List<Pair> sortables = [
  const Pair('Me gusta', 'likes_count'),
  const Pair('Alfabético', 'alphabetically'),
  const Pair('Puntuación', 'score'),
  const Pair('Creación', 'creation'),
  const Pair('Fecha estreno', 'release_date'),
  const Pair('Núm. Capítulos', 'num_chapters')
];
