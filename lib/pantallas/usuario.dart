import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart'; //Import para abrir enlaces.

//Imports para usar Firebase
import 'package:firebase_auth/firebase_auth.dart';

//Imports para usar sesiones de Google
import 'package:google_sign_in/google_sign_in.dart';

//Import para debug de notificaciones
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
  const Usuario({super.key});

  @override
  _UsuarioState createState() => _UsuarioState();
}

class _UsuarioState extends State<Usuario> {
  //Color Principal es rosa mexicano. Se usa en el fondo de los botones "poco" importantes.
  final Color _colorPrincipal = Color.fromARGB(255, 228, 0, 124);
  //Color Secundario es rosa "obscuro". Se usa en el fondo de los botones "muy" importantes.
  final Color _colorSecundario = Color.fromARGB(255, 137, 0, 75);

  //Correo del usuario.
  late final correo = FirebaseAuth.instance.currentUser?.email;

  //ESQUELETO MOSTRAR MENSAJES
  void _mostrarSnackBar(String mensaje, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
      ),
    );
  }

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
              try {
                await ServicioAuth().resetPass(email: correo.toString());
                _mostrarSnackBar("Solicitud enviada. ¡Revisa tu correo!", esError: false);
              } catch (e) {
                _mostrarSnackBar("No se pudo envíar la solicitud. Intenta de nuevo.");
              }
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: _colorPrincipal,
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

          //BOTÓN PARA ENVIAR NOTIFICACIÓN (DEBUG)
          /*
          ElevatedButton(
            onPressed: Notificacion().enviarNotificacion,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: _colorPrincipal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                )
            ),
            child: Text(
                "Enviar notificacion",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.black
                )
            ),
          ),

          SizedBox(height: 16),
           */

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
                  backgroundColor: _colorPrincipal,
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
              try {
                await ServicioAuth().signOut();
                _mostrarSnackBar("Sesión finalizada con éxito.", esError: false);
              } catch (e) {
                _mostrarSnackBar("Problemas al cerrar sesión.");
              }
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 27),
                backgroundColor: _colorPrincipal,
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
                try {
                  await ServicioAuth().borrarCuenta();
                  _mostrarSnackBar("Cuenta eliminada con éxito.", esError: false);
                } catch (e) {
                  _mostrarSnackBar("Problemas al eliminar cuenta.");
                }
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
          ),

          Expanded(
            child: SizedBox()
          ),

          //VERSIÓN
          Align(
            alignment: Alignment.center,
            child: Text(
              "v3.0.2",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                decoration: TextDecoration.none
              )
            ),
          )
        ]
    );
  }
}