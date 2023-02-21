import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'object_event.dart';
part 'object_state.dart';

class ObjectBloc extends Bloc<ObjectEvent, ObjectState> {
  ObjectBloc() : super(ObjectInitial()) {
    on<ObjectEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
