import 'package:equatable/equatable.dart';

class LoginRequest extends Equatable {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  @override
  List<Object?> get props => [username, password];
}

class Organization extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String? url;
  final DateTime? startStudyDate;
  final DateTime? endStudyDate;

  const Organization({
    required this.id,
    required this.name,
    this.logo,
    this.url,
    this.startStudyDate,
    this.endStudyDate,
  });

  factory Organization.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Organization(id: '', name: 'Unknown');
    }
    return Organization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      logo: json['logo']?.toString(),
      url: json['url']?.toString(),
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
        'startStudyDate': startStudyDate?.toIso8601String(),
        'endStudyDate': endStudyDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, logo, url, startStudyDate, endStudyDate];
}

class UserProfile extends Equatable {
  final String userId;
  final String userName;
  final String userType;
  final String fullName;
  final String firstName;
  final String secondName;
  final String? thirdName;
  final String? fourthName;
  final String? phone;

  const UserProfile({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.fullName,
    required this.firstName,
    required this.secondName,
    this.thirdName,
    this.fourthName,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException('UserProfile JSON is null');
    }
    final userData = json['user'] ?? json;
    return UserProfile(
      userId: userData['userId']?.toString() ?? '',
      userName: userData['userName']?.toString() ?? '',
      userType: userData['userType']?.toString() ?? '',
      fullName: userData['fullName']?.toString() ?? '',
      firstName: userData['firstName']?.toString() ?? '',
      secondName: userData['secondName']?.toString() ?? '',
      thirdName: userData['thirdName']?.toString(),
      fourthName: userData['fourthName']?.toString(),
      phone: userData['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userType': userType,
        'fullName': fullName,
        'firstName': firstName,
        'secondName': secondName,
        'thirdName': thirdName,
        'fourthName': fourthName,
        'phone': phone,
      };

  @override
  List<Object?> get props => [
        userId,
        userName,
        userType,
        fullName,
        firstName,
        secondName,
        thirdName,
        fourthName,
        phone,
      ];
}

class LoginResponse extends Equatable {
  final String token;
  final String userType;
  final UserProfile profile;
  final Organization? organization;
  final String? message;

  const LoginResponse({
    required this.token,
    required this.userType,
    required this.profile,
    this.organization,
    this.message,
  });

  factory LoginResponse.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      throw const FormatException('Invalid LoginResponse: null or not a Map');
    }
    
    // Validate required fields
    if (!json.containsKey('token') || json['token'] == null) {
      throw const FormatException('Missing required field: token');
    }
    if (!json.containsKey('userType') || json['userType'] == null) {
      throw const FormatException('Missing required field: userType');
    }
    
    final profileData = json['profile'] ?? json['user'];
    if (profileData == null) {
      throw const FormatException('Missing required field: profile or user');
    }
    
    return LoginResponse(
      token: json['token'] as String,
      userType: json['userType'] as String,
      profile: UserProfile.fromJson(profileData as Map<String, dynamic>),
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [token, userType, profile, organization, message];
}
