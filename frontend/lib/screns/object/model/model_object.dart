// class ModelObject {
//   final int id;
//   final String name;
//   final String email;
//   final String contactPhone;
//   final String birthday;
//   final String photo;
//   final int locationId;
//   final String locationIdName;
//   final int roleId;
//   final String roleIdName;
//   final int workingSpecialtyId;
//   final String identityCard;
//   final String qualificationFile;
//
//   ModelObject({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.contactPhone,
//     required this.birthday,
//     required this.photo,
//     required this.locationId,
//     required this.locationIdName,
//     required this.roleId,
//     required this.roleIdName,
//     required this.workingSpecialtyId,
//     required this.identityCard,
//     required this.qualificationFile,
//   });
//
//   factory ModelObject.fromJson(Map<String, dynamic> json) {
//     final modelObjectJson = json['data'];
//     return ModelObject(
//       id: modelObjectJson['id'],
//       name: modelObjectJson['name'],
//       email: modelObjectJson['email'],
//       contactPhone: modelObjectJson['contactPhone'],
//       birthday: modelObjectJson['birthday'],
//       photo: modelObjectJson['photo'],
//       locationId: modelObjectJson['locationId'],
//       locationIdName: modelObjectJson['locationIdName'],
//       roleId: modelObjectJson['roleId'],
//       roleIdName: modelObjectJson['roleIdName'],
//       workingSpecialtyId: modelObjectJson['workingSpecialtyId'],
//       identityCard: modelObjectJson['identityCard'],
//       qualificationFile: modelObjectJson['qualificationFile'],
//     );
//   }
// }