import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart'; //Import para abrir enlaces.

//Imports para usar Firebase
import 'package:firebase_auth/firebase_auth.dart';

//Imports para usar sesiones de Google
import 'package:google_sign_in/google_sign_in.dart';

import 'package:exploracdmx/notificaciones.dart';

class ServicioAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //OBTENER EL ESTADO DE AUTENTICACIÓN
  Stream<User?> get userChanges => _auth.authStateChanges();

  //FUNCIÓN PARA OBTENER CORREO DE USUARIO
  Future<User?> borrarCuenta() async {
    await _auth.currentUser?.delete();
    return null;
  }

  //FUNCIÓN PARA REESTABLECER CONTRASEÑA
  Future<User?> resetPass({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
    return null;
  }

  //FUNCIÓN DE FIN DE SESIÓN
  Future<User?> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
    return null;
  }
}

class Usuario extends StatefulWidget {
  @override
  _UsuarioState createState() => _UsuarioState();
}

class _UsuarioState extends State<Usuario> {
  //Correo del usuario.
  late final correo = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Container(
              padding: EdgeInsets.only(top: 42),
              child: Text(
                  "Tu Cuenta",
                  style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold
                  )
              )
          ),
          Container(
            padding: EdgeInsets.all(3),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Tu correo es:",
                    style: TextStyle(
                        fontSize: 22
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    correo.toString(),
                    style: TextStyle(
                        fontSize: 20
                    ),
                  ),
                )
              ],
            ),
          ),

          SizedBox(height: 16),

          //BOTÓN PARA REESTABLECER CONTRASEÑA
          ElevatedButton(
            onPressed: () async {
              await ServicioAuth().resetPass(email: correo.toString());
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                )
            ),
            child: Text(
                "Reestablecer Contraseña",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black
                )
            ),
          ),

          SizedBox(height: 16),

          const Divider(),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(3),
            child: Text(
              "¿Problemas con la Aplicación?",
              style: TextStyle(
                  fontSize: 20
              ),
            ),
          ),

          SizedBox(height: 16),

          //BOTÓN PARA ENVIAR UN CORREO
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  )
              ),
              onPressed: () => launchUrl(
                  Uri.parse('mailto:exploracdmx.nacionalurbenia@gmail.com'),
                  mode: LaunchMode.externalApplication
              ),
              child: Text(
                "Envíanos un Correo",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black
                ),
              )
          ),

          SizedBox(height: 16),

          const Divider(),

          SizedBox(height: 16),

          //BOTÓN PARA CERRAR SESIÓN
          ElevatedButton(
            onPressed: () async {
              await ServicioAuth().signOut();
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 27),
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                )
            ),
            child: Text(
                "CERRAR SESIÓN",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black
                )
            ),
          ),

          SizedBox(height: 16),

          //BOTÓN PARA ELIMINAR USUARIO
          ElevatedButton(
              onPressed: () async {
                await ServicioAuth().borrarCuenta();
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  backgroundColor: Colors.pink.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  )
              ),
              child: Text(
                  "BORRAR CUENTA",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white
                  )
              )
          )
        ]
    );
  }
}