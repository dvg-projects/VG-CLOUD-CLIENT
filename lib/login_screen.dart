import 'package:file_app/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_service.dart';
import 'main.dart'; // Importa tu clase de lógica

/**
 * Pantalla cuyo estado no cambia (StatelessWidget).
 * Construye la pantalla como tal, es la que arrancamos en base al main y "runApp()".
 */
class LoginScreen extends StatefulWidget {
  // Para determinar si el inicio de sesión ha sido exitoso.
  final VoidCallback onLoginSuccess;
  LoginScreen({required this.onLoginSuccess});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController(); // Texto de nombre de usuario
  final _passController = TextEditingController(); // Texto de contraseña
  bool _isLoading = false; // Controla el estado del botón
  final _auth = Login();   // La clase "Login" dentro de login_service, la que gestiona la lógica de inicio de sesión.

  void _handleLogin() async {
    setState(() => _isLoading = true); // Primero, hacemos que muestre una barra de carga
    // NOTA -> La eliminamos en caso de que las credenciales sean INCORRECTAS, pero de lo contrario
    // no lo eliminamos, pues la app borra de la pila de pantallas esta misma pantalla (Como figura este mismo cñodigo a partir
    // de la línea 53). SI ESTO CAMBIASE EN EL FUTURO, Y NO ELIMINÁSEMOS LA PRESENTE PANTALLA, DEBEMOS INCLUIR EN ALGÚN PUNTO DICHA
    // DETENCIÓN DE CARGA, de lo contrario nunca se dentrá.

    bool success = await _auth.login(
        _userController.text,
        _passController.text
    );

    if (success) {
      // 1. Guardamos la sesión persistente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _userController.text); // IMPORTANTÍSIMO el nombre de usuario porque sólo permitimos accionar en
                                                               // ficheros u directorios que cuelguen del directorio raíz de cada usuario respectivo.

      // 2. Mostramos el mensaje de bienvenida
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('¡Bienvenid@ ${_userController.text}!'),
            backgroundColor: Colors.green
        ),
      );

      // 3. Esperamos a que lea el mensaje
      await Future.delayed(const Duration(seconds: 2));

      // 4. DIRECCIONAMOS DIRECTAMENTE A LA HOME BORRANDO EL LOGIN DE LA MEMORIA
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyApp()),
              (route) => false, // Esto destruye el historial para que no pueda volver atrás
        );
      }

    } else {
      setState(() => _isLoading = false); // Ha terminado de cargar, así que eliminamos la barra de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario o contraseña incorrectos'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_queue, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text("VGCloud", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),

              // Tarjeta blanca para el formulario
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passController,
                      obscureText: true, // Para ocultar la contraseña
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Botón Inteligente
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Iniciar Sesión", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: ()
                // Vamos a la pantalla de registro gracias a Navigator.push
                { Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );},
                child: Text("¿No tienes cuenta? Regístrate"),
              )
            ],
          ),
        ),
      ),
    );
  }
}