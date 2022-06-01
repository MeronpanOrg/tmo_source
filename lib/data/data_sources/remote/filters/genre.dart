
import 'package:http_source/models/filter.dart';


class Genre extends FilterTriState {
  final String id;

  const Genre(
      {required String name,
      required this.id,
      TriState state = TriState.stateIgnore})
      : super(name: name, state: state);

  Genre copyWith({required TriState state}) {
    return Genre(name: name, id: id, state: state);
  }

  Genre copy() {
    return Genre(
      name: name,
      id: id,
    );
  }
}
