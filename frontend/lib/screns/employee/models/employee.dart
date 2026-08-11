class Employee {
  final int id;
  final String name;
  final String email;
  final String contactPhone;
  final String birthday;
  final String photo;
  final int locationId;
  final String locationIdName;
  final int roleId;
  final String roleIdName;
  final int workingSpecialtyId;
  final String identityCard;
  final String qualificationFile;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.contactPhone,
    required this.birthday,
    required this.photo,
    required this.locationId,
    required this.locationIdName,
    required this.roleId,
    required this.roleIdName,
    required this.workingSpecialtyId,
    required this.identityCard,
    required this.qualificationFile,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['data'];
    return Employee(
      id: employeeJson['id'],
      name: employeeJson['name'],
      email: employeeJson['email'],
      contactPhone: employeeJson['contactPhone'],
      birthday: employeeJson['birthday'],
      photo: employeeJson['photo'],
      locationId: employeeJson['locationId'],
      locationIdName: employeeJson['locationIdName'],
      roleId: employeeJson['roleId'],
      roleIdName: employeeJson['roleIdName'],
      workingSpecialtyId: employeeJson['workingSpecialtyId'],
      identityCard: employeeJson['identityCard'],
      qualificationFile: employeeJson['qualificationFile'],
    );
  }
}
