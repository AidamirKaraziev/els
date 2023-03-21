part of 'object_bloc.dart';

enum ObjectRepository {
  unknown,
  requestInProgress,
  requestInSuccess,
  requestFailure,
}

class MyObjectState {
  final List modelObjectList;
  final ObjectRepository objectStatus;
  final Set<int> cartIds;

  MyObjectState({
    this.modelObjectList = const [],
    this.objectStatus = ObjectRepository.unknown,
    this.cartIds = const {},
  });

  MyObjectState copyWith({
    List ? modelObjectList,
    ObjectRepository ? objectStatus,
    Set<int> ? cartIds,
}) => MyObjectState(
    modelObjectList: modelObjectList ?? this.modelObjectList,
    objectStatus: objectStatus ?? this.objectStatus,
    cartIds: cartIds ?? this.cartIds,
  );
}
