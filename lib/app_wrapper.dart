import 'package:file_app/main.dart';
import 'package:flutter/cupertino.dart';
import 'login_screen.dart';

class AppWrapper extends StatefulWidget {
  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoggedIn = false;

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si no está logueado, muestra la pantalla de Login
    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Si está logueado, muestra tu App Principal
    return MyApp();
  }
}