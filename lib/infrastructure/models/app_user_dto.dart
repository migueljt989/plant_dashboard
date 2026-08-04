import '../../domain/entities/app_user.dart';

class AppUserDto {
  final String id;
  final String email;
  final String token;

  const AppUserDto({required this.id, required this.email, required this.token});

  factory AppUserDto.fromJson(Map<String, dynamic> json) =>
      AppUserDto(id: json['id'] as String, email: json['email'] as String, token: json['token']);

  Map<String, dynamic> toJson() => {'id': id, 'email': email};

  AppUser toEntity() => AppUser(id: id, email: email, token: token);
}
