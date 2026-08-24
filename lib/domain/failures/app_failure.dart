sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
}

class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure() : super('Credenciales inválidas');
}

class EmailAlreadyExistsFailure extends AppFailure {
  const EmailAlreadyExistsFailure() : super('El correo ya está registrado');
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure()
      : super('Sesión expirada, inicia sesión de nuevo');
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}
