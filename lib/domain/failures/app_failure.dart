sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}
