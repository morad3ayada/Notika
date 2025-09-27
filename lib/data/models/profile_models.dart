import 'package:equatable/equatable.dart';

class TeacherProfile extends Equatable {
  final String teacherId;
  final String subject;
  final String specialty;
  final String jobDescription;
  final String userId;
  final String userName;
  final String userType;
  final String fullName;
  final String firstName;
  final String secondName;
  final String? thirdName;
  final String? fourthName;
  final String? phone;
  final String? email;
  final String? address;
  final String? gender;
  final DateTime? birthDate;

  const TeacherProfile({
    this.teacherId = '',
    this.subject = '',
    this.specialty = '',
    this.jobDescription = '',
    required this.userId,
    required this.userName,
    required this.userType,
    required this.fullName,
    required this.firstName,
    required this.secondName,
    this.thirdName,
    this.fourthName,
    this.phone,
    this.email,
    this.address,
    this.gender,
    this.birthDate,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      teacherId: json['teacherId']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      jobDescription: json['jobDescription']?.toString() ?? json['jobDesciption']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      secondName: json['secondName']?.toString() ?? '',
      thirdName: json['thirdName']?.toString(),
      fourthName: json['fourthName']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      gender: json['gender']?.toString(),
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'teacherId': teacherId,
        'subject': subject,
        'specialty': specialty,
        'jobDescription': jobDescription,
        'userId': userId,
        'userName': userName,
        'userType': userType,
        'fullName': fullName,
        'firstName': firstName,
        'secondName': secondName,
        'thirdName': thirdName,
        'fourthName': fourthName,
        'phone': phone,
        'email': email,
        'address': address,
        'gender': gender,
        'birthDate': birthDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        teacherId,
        subject,
        specialty,
        jobDescription,
        userId,
        userName,
        userType,
        fullName,
        firstName,
        secondName,
        thirdName,
        fourthName,
        phone,
        email,
        address,
        gender,
        birthDate,
      ];
}

class Organization extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String? url;
  final DateTime? startStudyDate;
  final DateTime? endStudyDate;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;

  const Organization({
    required this.id,
    required this.name,
    this.logo,
    this.url,
    this.startStudyDate,
    this.endStudyDate,
    this.address,
    this.phone,
    this.email,
    this.website,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      url: json['url']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      startStudyDate: json['startStudyDate'] != null
          ? DateTime.tryParse(json['startStudyDate'].toString())
          : null,
      endStudyDate: json['endStudyDate'] != null
          ? DateTime.tryParse(json['endStudyDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'url': url,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'startStudyDate': startStudyDate?.toIso8601String(),
        'endStudyDate': endStudyDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        logo,
        url,
        address,
        phone,
        email,
        website,
        startStudyDate,
        endStudyDate,
      ];
}

class TeacherClass extends Equatable {
  final String? schoolId;
  final String? schoolName;
  final String? levelId;
  final String? levelName;
  final String? classId;
  final String? className;
  final String? subjectId;
  final String? subjectName;
  final String? levelSubjectId;

  const TeacherClass({
    this.schoolId,
    this.schoolName,
    this.levelId,
    this.levelName,
    this.classId,
    this.className,
    this.subjectId,
    this.subjectName,
    this.levelSubjectId,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) => TeacherClass(
        schoolId: json['schoolId']?.toString(),
        schoolName: json['schoolName']?.toString(),
        levelId: json['levelId']?.toString(),
        levelName: json['levelName']?.toString(),
        classId: json['classId']?.toString(),
        className: json['className']?.toString(),
        subjectId: json['subjectId']?.toString(),
        subjectName: json['subjectName']?.toString(),
        levelSubjectId: json['levelSubjectId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'schoolId': schoolId,
        'schoolName': schoolName,
        'levelId': levelId,
        'levelName': levelName,
        'classId': classId,
        'className': className,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'levelSubjectId': levelSubjectId,
      };

  @override
  List<Object?> get props => [
        schoolId,
        schoolName,
        levelId,
        levelName,
        classId,
        className,
        subjectId,
        subjectName,
        levelSubjectId,
      ];
}

class ProfileResult extends Equatable {
  final TeacherProfile profile;
  final List<TeacherClass> classes;
  final Organization? organization;

  const ProfileResult({
    required this.profile,
    this.classes = const [],
    this.organization,
  });

  @override
  List<Object?> get props => [profile, classes, organization];
}
