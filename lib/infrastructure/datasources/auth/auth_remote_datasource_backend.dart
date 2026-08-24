import 'package:dio/dio.dart';
import 'package:plant_dashboard/infrastructure/datasources/auth/auth_remote_datasource.dart';

import '../../models/app_user_dto.dart';

/// Contrato abstracto del DataSource de autenticación.
/// Las implementaciones concretas (Fake, Firebase, Cognito, etc.) deben extender esta clase.
 class AuthRemoteDataSourceBackend implements AuthRemoteDataSource{

  final dio = Dio(BaseOptions(
      baseUrl: "http://127.0.0.1:8000"
      ));



  AuthRemoteDataSourceBackend();
  
  @override
  Future<AppUserDto> signIn(String email, String password) async{

    try {
      print('antes del post');
      final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password
    });
    final String token = response.data['access_token'] as String;
    print('respuesta: ${response.data}');
    return AppUserDto(id: 'fake-id', email: email, token: token);
    } catch (e, st) {
      print('error login: $e');
    print(st);
    rethrow;
    }
  }

  @override
  Future<AppUserDto> register(String name, String email, String password) async {

    try {
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password
      });

      if (response.statusCode == 201){
        return await signIn(email, password);
      }
      throw Exception('Registro fallido: ${response.statusCode}');
    } catch (e) {
      throw Exception('Fallo: $e');
    }

  }
 
  @override
  Future<void> signOut() async {}



 
}
