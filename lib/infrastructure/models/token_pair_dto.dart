import '../../domain/entities/app_user.dart';

/// Represents the combined result of login (or register+login):
/// the user identity + both tokens.
class TokenPairDto {
  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;

  const TokenPairDto({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  AppUser toEntity() => AppUser(id: userId, email: email, token: accessToken);
}
