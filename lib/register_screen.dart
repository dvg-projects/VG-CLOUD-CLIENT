import 'package:flutter/material.dart';
import 'login_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confPassController = TextEditingController();
  bool _isLoading = false;
  final _auth = Login();

  void _handleRegister() async {
    setState(() => _isLoading = true);

    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _confPassController.text.isEmpty) {
      // Si hay campos vacíos.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes cumplimentar todo'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false); // Paramos de cargar
    } else if (_passController.text != _confPassController.text) {
      // Si las contraseñas no coinciden

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false); // Paramos de cargar
    } else {
      // Llamamos a tu función de registro (_auth es el nombre que le hemos dado a la instancia de Login(), donde está la lógica de registro)
      String response = await _auth.register(
        _userController.text,
        _passController.text,
      ); // Le mandamos lo que nos ha escrito el usuario.

      setState(() => _isLoading = false);

      // Si el servidor responde con el mensaje de éxito que programamos en Dart
      if (response.contains("éxito")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Registro completado! Ya puedes entrar'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver automáticamente al Login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $response'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Cuenta"),
      ), // Flecha para volver atrás automática
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_queue, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                "VGCloud",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario...',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña...',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _confPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirma tu contraseña...',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text(
                              "Registrarme",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
