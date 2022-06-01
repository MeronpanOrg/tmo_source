

import 'package:http_source/models/filter.dart';

class ContentType extends FilterTriState {
  final String id;
  const ContentType(
      {required String name,
      required this.id,
      TriState state = TriState.stateIgnore})
      : super(name: name, state: state);

  ContentType copyWith({required TriState state}) {
    return ContentType(name: name, id: id, state: state);
  }

  ContentType copy() {
    return ContentType(
      name: name,
      id: id,
    );
  }
}
