import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Login {

  // Obtenemos para empezar, la dirección a la API alojada en nuestro servidor que interactúa con la Base de datos PostgreSQL.
  final String baseUrl = dotenv.env['API_BBDD_URL'] ??
  (throw Exception('ERROR: Variable API_BBDD_URL en fichero .env NO ENCONTRADA'));

  // La palabra reservada Future expresa en lenguaje Dart una "promesa" de un valor a devolver
  // (En este caso de tipo bool), es el sistema que tiene Dart a la hora de no congelarse al esperar
  // X o Y valor.
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'), // Petición HTTP POST con el endpoint de login
        headers: {'Content-Type': 'application/json'}, // Formato JSON
        body: jsonEncode({'username': username, 'password': password}), // Y le pasamos los datos a enviar.
      );

      // Si responde con código 200, el inicio de sesión ha sido exitoso.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['auth'] == true; // Si el dato "auth" de la respuesta en JSON (Consultar código dart de la API de BBDD en ubuntu) es true,
                                     // es que ha salido bien.
      }
      return false;
    } catch (e) {
      print("Error de conexión: $e");
      return false;
    }
  }

  // Función de registro.
  Future<String> register(String username, String password) async {
    final response = await http.post( // Mismo principio que el explicado anteriormente
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response.body; // Aquí recibimos el mensaje de éxito o error
  }
}