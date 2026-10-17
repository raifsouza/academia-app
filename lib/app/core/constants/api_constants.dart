import 'package:flutter/foundation.dart';

class ApiConstants {
  // Define a URL base dependendo do ambiente
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.academiapowershape.com.br'; // Produção
    }
    return 'https://api.academiapowershape.com.br'; // Desenvolvimento Local (Web)
  }

  // Endpoints utilizando a URL base dinâmica
  static String get apiUrl => '$baseUrl/api';
  static String get loginUrl => '$baseUrl/api/login';
  static String get fcmTokenUrl => '$baseUrl/api/usuarios/fcm-token';
  static String get usuariosUrl => '$baseUrl/api/usuarios';
  static String get alunosUrl => '$baseUrl/api/alunos';
}