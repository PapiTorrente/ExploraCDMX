//Imports para usar Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

//Imports para usar el inicio de sesión con Google
import 'package:google_sign_in/google_sign_in.dart';

//Import para usar el logo de Google
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//Imports para la página principal
import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'pantallas/calendario.dart';
import 'pantallas/usuario.dart';

import 'package:url_launcher/url_launcher.dart'; //Import para abrir enlaces.
import 'package:cached_network_image/cached_network_image.dart'; //Import para cargar imagenes de internet con cache.
import 'package:flex_color_picker/flex_color_picker.dart'; //Import del selector de color
import 'package:syncfusion_flutter_calendar/calendar.dart'; //Import del calendario
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart'; //Import del selector de fechas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();
  runApp(const ExploraCDMXApp());
}

class ExploraCDMXApp extends StatelessWidget {
  const ExploraCDMXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //Titulo efectivo de la aplicación.
      title: 'Explora CDMX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/* ESPACIO PARA LA AUTENTICACIÓN / INICIO DE SESIÓN */
class ServicioAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //OBTENER EL ESTADO DE AUTENTICACIÓN
  Stream<User?> get userChanges => _auth.authStateChanges();

  //FUNCIÓN DE REGISTRO
  Future<User?> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //Registro de usuario exitoso
      return userCredential.user;
    } on FirebaseAuthException {
      return null;
    }
  }

  //FUNCIÓN DE INICIO DE SESIÓN
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      //Inicio de sesión exitoso
      return userCredential.user;
    } on FirebaseAuthException {
      return null;
    }
  }

  //FUNCIÓN INICIO DE SESIÓN CON GOOGLE
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email'],
      );

      final GoogleSignInAuthentication googleAuth = account.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

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

/* CLASE PARA MOSTRAR PRIMERO LA PANTALLA DE INICIO O EL INICIO DE LA APP */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

//============================================================//
// Decisión de si mostrar primero página de inicio de sesión  //
// O página principal de la app                               //
//============================================================//
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: ServicioAuth().userChanges, // Escucha el estado
      builder: (context, datosFirebase) {
        // Muestra una pantalla de carga mientras se decide
        if (datosFirebase.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si el usuario SI está logueado, muestra la página de principa.
        if (datosFirebase.hasData && datosFirebase.data != null) {
          return const PPrincipal(title: 'Hora de Explorar');
        }

        // Si el usuario NO está logueado, muestra la página de inicio de sesión.
        return const PInicioSesion();
      },
    );
  }
}

//============================================================//
// PÁGINA DE INICIO DE SESIÓN                                 //
//============================================================//
class PInicioSesion extends StatefulWidget {
  const PInicioSesion({super.key});

  @override
  State<PInicioSesion> createState() => _PInicioSesionState();
}

class _PInicioSesionState extends State<PInicioSesion> {
    //Controlador de autenticación por correo y contraseña
    final TextEditingController _controladorCorreo = TextEditingController();
    final TextEditingController _controladorContra = TextEditingController();

    /* MÉTODO DE DESECHO DE CONTROLADORES */
    @override
    void dispose() {
      _controladorCorreo.dispose();
      _controladorContra.dispose();
      super.dispose();
    }
    /* FIN MÉTODO DE DESECHO DE CONTROLADORES */

    /* MÉTODO DE INICIO DE SESIÓN */
    void _inicioHandler() async {
      final email = _controladorCorreo.text.trim();
      final password = _controladorContra.text.trim();

      if(email.isEmpty || password.isEmpty) {
        _mostrarSnackBar("Error. Correo y contraseña obligatorios.");
        return;
      }

      try {
        User? user = await ServicioAuth().signIn(
            email: email, password: password);

        if (user != null) {
          _mostrarSnackBar("Inicio de sesión exitoso.", isError: false);
        } else {
          _mostrarSnackBar("Error en el inicio de sesión.");
          return;
        }
      } on FirebaseAuthException catch (e) {
        String mensajeError = "";
        if(e.code == 'user-not-found' || e.code == 'wrong-password') {
          mensajeError == "Usuario no encontrado o contraseña invalida.";
        } else if(e.code == 'invalid-email') {
          mensajeError == "No es un correo.";
        }
        _mostrarSnackBar(mensajeError);
      } catch (e) {
        _mostrarSnackBar("Ha sucedido un error. Intente nuevamente.");
      }
    }
    /* FIN MÉTODO DE INICIO DE SESIÓN */

    /* MÉTODO DE INICIO DE SESIÓN CON GOOGLE */
    void _signInWithGoogle() async {
      try {
        User? user = await ServicioAuth().signInWithGoogle();
        if (user != null) {
          _mostrarSnackBar("Sesión iniciada con Google.", isError: false);
        }
      } catch (e) {
        _mostrarSnackBar("Error al iniciar sesión con Google.");
        return;
      }
    }
    /* FIN MÉTODO DE INICIO DE SESIÓN CON GOOGLE */

    /* MÉTODO DE REGISTRO DE USUARIO */
    // Lleva a la página de registro.
    void _registroHandler() async {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PRegistroUsuario()),
      );
    }
    /* FIN MÉTODO DE REGISTRO DE USUARIO */

    /* MÉTODO PARA RECUPERAR CONTRASEÑA */
    void _recuperarContrasenia() {
      final email = _controladorCorreo.text.trim();

      if(email.isEmpty) {
        _mostrarSnackBar("Error. No hay correo para enviar recuperación de contraseña.");
      }

      ServicioAuth().resetPass(email: email);
      _mostrarSnackBar("Correo enviado con éxito.");

    }
    /* FIN MÉTODO PARA RECUPERAR CONTRASEÑA */

    //ESQUELETO MOSTRAR MENSAJES
    void _mostrarSnackBar(String message, {bool isError = true}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
    }

    //Inicio de Sesión
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Column(
                    children: [
                      Text(
                          "ExploraCDMX",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 38,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      Text(
                          "Inicia Sesión",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ]
                ),

                //CAMPOS PARA CORREO Y CONTRASEÑA
                Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      //CAMPO PARA CORREO
                      TextField(
                        controller: _controladorCorreo,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 16),

                      //CAMPO PARA CONTRASEÑA
                      TextField(
                        controller: _controladorContra,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: 'Contraseña', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 16),
                    ]
                  )
                ),

                //BOTÓN DE INICIO DE SESIÓN
                ElevatedButton(
                  onPressed: _inicioHandler,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 80),
                    backgroundColor: Colors.pinkAccent
                  ),
                  child: Text(
                    "¡INICIAR SESIÓN!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                    )
                  ),
                ),
                SizedBox(height: 16),

                // BOTÓN DE INICIO DE SESIÓN CON GOOGLE
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 26),
                    side: BorderSide(color: Colors.pink, width: 2),
                  ),
                  icon: FaIcon(
                    FontAwesomeIcons.google,
                    size: 20,
                  ),
                  label: Text(
                    "INICIAR SESIÓN CON GOOGLE",
                    style: TextStyle(fontSize: 16, color: Colors.pink),
                  ),
                ),
                SizedBox(height: 16),

                //BOTÓN DE REGISTRO
                OutlinedButton(
                  onPressed: _registroHandler,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 90),
                    side: BorderSide(color: Colors.pink, width: 2)
                  ),
                  child: Text(
                    "¡REGÍSTRAME!",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.pink
                    )
                  )
                ),

                SizedBox(height: 10),
                //BARRA ESPACIADORA DE CONCEPTOS
                const Divider(),
                SizedBox(height: 10),

                OutlinedButton(
                    onPressed: _recuperarContrasenia,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 46),
                      side: BorderSide(color: Colors.pink, width: 2)
                    ),
                    child: Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.pink
                      ),
                    )
                )
              ]
          )
        ),
      );
    }
}

//============================================================//
// PÁGINA DE REGISTRO DE USUARIO                              //
//============================================================//
class PRegistroUsuario extends StatefulWidget {
  const PRegistroUsuario({super.key});

  @override
  State<PRegistroUsuario> createState() => _PRegistroUsuarioState();
}

class _PRegistroUsuarioState extends State<PRegistroUsuario> {
  //Controlador de autenticación por correo y contraseña
  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorContra = TextEditingController();

  /* MÉTODO DE DESECHO DE CONTROLADORES */
  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContra.dispose();
    super.dispose();
  }
  /* FIN MÉTODO DE DESECHO DE CONTROLADORES */

  /* MÉTODO DE REGISTRO DE USUARIO */
  void _registroHandler() async {
    final email = _controladorCorreo.text.trim();
    final password = _controladorContra.text.trim();

    if(email.isEmpty) {
      _mostrarSnackBar("Error. No colocaste un correo.");
      return;
    }

    if(password.length < 8) {
      _mostrarSnackBar("Error. La contraseña es menor a 8 caracteres");
      return;
    }

    try {
      User? user = await ServicioAuth().signUp(
          email: email, password: password);

      if (user != null) {
        _mostrarSnackBar("Registro exitoso.", isError: false);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError = "";
      if(e.code == 'email-already-in-use') {
        mensajeError = "Correo en uso. Intente otro correo.";
      } else if(e.code == 'invalid-email') {
        mensajeError = "No es un correo.";
      } else if(e.code == 'weak-password') {
        mensajeError = "La contraseña es débil.";
      }
      _mostrarSnackBar(mensajeError);
    } catch (e) {
      _mostrarSnackBar("Ha sucedido un error. Intente nuevamente.");
    }
  }
  /* FIN MÉTODO DE REGISTRO DE USUARIO */

  //ESQUELETO MOSTRAR MENSAJES
  void _mostrarSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  //Registro de Usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Column(
                    children: [
                      Text(
                          "ExploraCDMX",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 38,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      Text(
                          "Crea tu Cuenta",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ]
                ),

                //CAMPOS PARA CORREO Y CONTRASEÑA
                Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                        children: [
                          //CAMPO PARA CORREO
                          TextField(
                            controller: _controladorCorreo,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 16),

                          //CAMPO PARA CONTRASEÑA
                          TextField(
                            controller: _controladorContra,
                            obscureText: true,
                            decoration: InputDecoration(
                                labelText: 'Contraseña (Mínimo 6 carácteres)', border: OutlineInputBorder()),
                          ),
                          SizedBox(height: 16),
                        ]
                    )
                ),

                //BOTÓN DE REGISTRO
                OutlinedButton(
                    onPressed: _registroHandler,
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 26),
                        side: BorderSide(color: Colors.pink, width: 2)
                    ),
                    child: Text(
                        "Finalizar Registro",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.pink
                        )
                    )
                )
              ]
          )
      ),
    );
  }
}

//============================================================//
// PÁGINA DE LA APLICACIÓN                                    //
//============================================================//
/* WIDGET CON ESTADO QUE CAMBIA SEGÚN LA INTERACCIÓN CON EL USUARIO*/
class PPrincipal extends StatefulWidget {
  const PPrincipal({super.key, required this.title});
  final String title;
  @override
  State<PPrincipal> createState() => _PPrincipalState();
}

class _PPrincipalState extends State<PPrincipal> {
      final GlobalKey<CalendarioState> _calendarioKey = GlobalKey<CalendarioState>();

      //Variable que almacena la fecha elegida por el usuario para su evento en calendario.
      DateTime _fechaElegida = DateTime.now();
      Color _colorElegido = Colors.pinkAccent;

      //Variable que almacena la selección del usuario tomada de los ChoiceChips.
      String? _seleccionTipo;

      //Variable que almacena la selección del usuario tomada de los radio buttons.
      String? _seleccionAlcaldia;

      //Lista de tipo de lugar. Se carga desde el principio.
      final List<String> _tipoLugar = [
        "Bar", "Cafetería", "Cine", "Espacio Cultural", "Espacio Público",
        "Espacio Recreativo", "Librería", "Museo", "Parque Público", "Restaurante"
      ];

      //Lista de alcaldías. Se carga desde el principio.
      final List<String> _listaAlcaldias = [
        "Álvaro Obregón", "Azcapotzalco", "Benito Juárez", "Cuajimalpa",
        "Coyoacán", "Cuauhtémoc", "Gustavo A. Madero", "Iztacalco",
        "Iztapalapa", "Magdalena Contreras", "Miguel Hidalgo", "Tláhuac",
        "Tlalpan", "Venustiano Carranza", "Xochimilco"
      ];

      //Lista global que guarda los resultados de las consultas al aplicar o no un filtro.
      List<QueryDocumentSnapshot> _resultadosLugares = [];

      //Controlador de la animación de la página.
      final PageController _controladorPagina = PageController(initialPage: 0);

      //Indice del elemento en la lista _paginas usado para cambiar entre ellos.
      var _indiceMenu = 0;

      @override
      void initState() {
        super.initState();
        //Llamada al metodo asíncrono.
        _entrada();

      }

      @override
      void dispose() {
        _controladorPagina.dispose();
        super.dispose();
      }

      void _itemPresionado(int indice) {
        setState(() {
          //Establece el indice del menu con el indice proporcionado
          _indiceMenu = indice;
          //Anima el cambio de la pantalla
          _controladorPagina.animateToPage(
            indice,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }

      void _paginaCambiada(int indice) {
        setState(() {
          _indiceMenu = indice;
        });
      }

      //============================================================//
      // MÉTODOS DE TARJETAS                                        //
      //============================================================//
      void _mostrarTarjetaGrande(doc) {
        //Guarda el string almacenado en el campo 'enlaceWeb' para los enlaces webs.
        String eWeb = '${doc['enlaceWeb']}';
        String textoEWeb = eWeb.isNotEmpty
            ? "Más información en su sitio web. ¡Presioname!"
            : "Este lugar no tiene sitio web. ¡No me presiones!";

        //Cambia de tipo de dato 'String' a 'Uri' para ser manejado por
        //la dependencia url_launcher y ser enviado al navegador del dispositivo.
        final enlace = Uri.parse(eWeb);
        //Función asíncrona que muestra una ventana sobre toda la aplicación y
        //bloquea el resto de la aplicación.
        showDialog(
          context: context,
          builder: (context) {

            /* CÓDIGO DE LA TARJETA GRANDE */
            return Dialog(
              insetPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                padding: EdgeInsets.all(10),

                //DECORACIÓN PARA EL CONTENEDOR DE LA TARJETA GRANDE
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  border: Border.all(
                      width: 6,
                      color: Colors.pinkAccent
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),

                //CONTENIDO DENTRO DE LA TARJETA GRANDE
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
                  children: [

                    //CONTENEDOR PARA LA IMAGEN EN LA TARJETA GRANDE
                    Container(
                        height: 170,
                        width: double.infinity,

                        //DECORACIÓN DEL CONTENEDOR DE LA IMAGEN EN LA TARJETA
                        //GRANDE
                        decoration: BoxDecoration(
                            border: Border.all(width: 6, color: Colors.pink.shade800),
                            borderRadius: BorderRadius.circular(2)
                        ),

                        //IMAGEN DE LA TARJETA GRANDE
                        //Descarga las imágenes desde el enlace y las guarda
                        //en el caché del dispositivo.
                        child: CachedNetworkImage(
                          imageUrl: doc['imagen'],
                          fit: BoxFit.cover,

                          //PLACEHOLDER PARA LA ESPERA DE LA CARGA DE LA IMAGEN.
                          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                          //WIDGET DE ERROR SI NO SE CARGÓ LA IMAGEN.
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                    ),

                    //TEXTO DEL TITULO DE LA TARJETA GRANDE
                    // Scroll para evitar que el texto largo rompa la pantalla
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${doc['nombre']}",
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                            Text(
                                "${doc['descripcion']}",
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    decoration: TextDecoration.none
                                )
                            ),
                            Text(
                                "Ubicación:",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    decoration: TextDecoration.none
                                )
                            ),
                            Text(
                                "${doc['ubicacion']}",
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    decoration: TextDecoration.none
                                )
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 8),

                    // BOTONES (Se quedan fijos abajo)
                    //CONTENEDOR PARA EL ENLACE WEB
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.pink.shade800,
                          border: Border.all(
                              width: 8,
                              color: Colors.pink.shade800
                          ),
                          borderRadius: BorderRadius.circular(6)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          //ESPACIO PARA EL BOTÓN DEL ENLACE WEB DÓNDE DEBE
                          //COLOCARSE EL ENLACE DINÁMICAMENTE
                          ElevatedButton(
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  )
                              ),
                              onPressed: () => launchUrl(
                                  enlace,
                                  mode: LaunchMode.externalApplication
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  textoEWeb,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              )
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.pink.shade800,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              )
                          ),
                          onPressed: () => _agregarAlCalendario(doc['nombre']),
                          child: Text("Agendar"),
                        ),
                        ElevatedButton(
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.pink.shade800,
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              )
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cerrar"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
            /* FIN CÓDIGO DE LA TARJETA GRANDE */
          },
        );
      }

      //Función usada en el método de agregar al calendario.
      void _mostrarSelectorFecha() {
        showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 365))
        ).then((value) {
          _fechaElegida = value!;
        });
      }

      void _agregarAlCalendario(String titulo) {
        //Función asíncrona que muestra una ventana sobre toda la aplicación y
        //bloquea el resto de la aplicación.
        showDialog(
          builder: (context) {

            /* CÓDIGO DE LA TARJETA PARA AGREGAR AL CALENDARIO */
            return Dialog(
              insetPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8)),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    border: Border.all(
                        width: 4,
                        color: Colors.pinkAccent
                    ),
                    borderRadius: BorderRadius.circular(8)
                ),

                //CONTENIDO DENTRO DE LA TARJETA DE AGREGAR AL CALENDARIO
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    //CONTENEDOR PARA EL TEXTO DE LA FECHA DE INICIO
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.pink.shade800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              width: 3,
                              color: Colors.pink.shade800
                          )
                      ),
                      child: Column(
                        children: [
                          MaterialButton(
                              onPressed: _mostrarSelectorFecha,
                              child: Text(
                                "Selecciona día y hora",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    decoration: TextDecoration.none
                                ),
                              ),
                          ),
                          SizedBox(height: 6),
                        ],
                      ),
                    ),

                    SizedBox(height: 8),

                    //CONTENEDOR PARA LA ELECCIÓN DE COLOR
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              width: 8,
                              color: Colors.pink.shade800
                          )
                      ),

                      child: ColorPicker(
                        borderRadius: 4,
                        spacing: 4,
                        hasBorder: true,
                        borderColor: Colors.black,
                        enableShadesSelection: false,
                        showRecentColors: true,
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.both: false,
                          ColorPickerType.primary: true,
                          ColorPickerType.accent: false,
                          ColorPickerType.custom: false,
                        },
                        selectedPickerTypeColor: Colors.white,
                        heading: Text(
                          "Elige un color",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              decoration: TextDecoration.none
                          ),
                        ),
                        subheading: Text(
                          "Elige la variación",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              decoration: TextDecoration.none
                          ),
                        ),
                        onColorChanged: (Color value) {
                          _colorElegido = value;
                        },
                      ),
                    ),

                    SizedBox(height: 8),

                    //ESPACIO PARA LOS BOTONES DE LA PANTALLA DE AGENDAR EVENTO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //CONTENEDOR DEL BOTÓN DE FINALIZAR AGENDA
                        ElevatedButton(
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.pink.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                )
                            ),
                            onPressed: () {
                              //Llamada a función para agendar un evento
                              //al calendario y permite observarlo en el
                              // calendario. Necesita el nombre del
                              //evento a agendar
                              //_agendarVisitaLugar(titulo);
                              _calendarioKey.currentState?.agendarVisitaLugar(titulo, _fechaElegida, _fechaElegida, _colorElegido);

                              //Reestablece los valores
                              _fechaElegida = DateTime.now();
                              _colorElegido = Colors.pinkAccent;

                              //Cierra la tarjeta de agregar
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "¡Todo Listo!",
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            )
                        ),

                        //CONTENEDOR DEL BOTÓN PARA CERRAR LA TARJETA DE AGENDAR
                        ElevatedButton(
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.pink.shade800,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                )
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Cerrar",
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            )
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
            /* FIN CÓDIGO DE LA TARJETA PARA AGREGAR AL CALENDARIO*/
          },
          context: context,
        );
      }

      Widget _tarjetaRosaInicio(var doc) {
        return Container(
          height: 160,
          //ESPACIO HACIA ADENTRO DE LA TARJETA EN LA PANTALLA PRINCIPAL
          padding: EdgeInsets.all(4),
          //ESPACIO HACIA AFUERA DE LA TARJETA EN LA PANTALLA PRINCIPAL
          margin: EdgeInsets.all(10),
          //DECORACIÓN DEL BORDE DEL CONTENEDOR DE TODA LA TARJETA EN LA PANTALLA PRINCIPAL
          decoration: BoxDecoration(
              color: Colors.pinkAccent,
              border: Border.all(
                  width: 6,
                  color: Colors.pinkAccent
              ),
              borderRadius: BorderRadius.circular(8)
          ),

          //CONTENIDO DENTRO DE LA TARJETA EN LA PANTALLAA PRINCIPAL
          child: Column(
            children: [

              //CONTENEDOR DE LA IMAGEN EN LA TARJETA DE LA PANTALLA PRINCIPAL
              Container(
                height: 80,
                //DECORACIÓN DEL BORDE DEL CONTENEDOR DE LA IMAGEN EN LA
                //TARJETA DE LA PANTALLA PRINCIPAL
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 4,
                        color: Colors.pink.shade800
                    ),
                    borderRadius: BorderRadius.circular(2)
                ),

                //IMAGEN EN LA TARJETA DE LA PÁGINA PRINCIPAL
                //SizedBox forza a que la imagen ocupe el tamaño que queremos
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  //Descarga las imágenes desde el enlace y las guarda en el
                  //caché del dispositivo.
                  child: CachedNetworkImage(
                    imageUrl: doc['imagen'],
                    fit: BoxFit.cover,
                    //WIDGET DE ERROR SI NO SE CARGÓ LA IMAGEN.
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),

              //TEXTO DEL TITULO DE LA TARJETA EN LA PÁNTALLA PRINCIPAL
              Flexible(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      doc['nombre'],
                      //Permite que si el texto no es suficiente, se muestren
                      //tres puntos.
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                      ),
                    ),
                  )
              ),

              //CONTENEDOR DEL TEXTO Y BOTÓN DE LA TARJETA EN LA PANTALLA
              //PRINCIPAL
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            doc['etiqueta'],
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: Colors.black
                            ),
                          ),
                        )
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.pink.shade800,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              )
                          ),
                          onPressed: (){
                            //Llamada a la función '_mostrarTarjetaGrande'
                            _mostrarTarjetaGrande(doc);
                          },
                          child: Text(
                            "Más",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                            ),
                          )
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }

      //============================================================//
      // MÉTODOS DEL FILTRO                                         //
      //============================================================//

      void _mostrarFiltrador() {
        showDialog(
          context: context,
          builder: (context) {

            /* CÓDIGO DE LA TARJETA GRANDE */
            return Dialog(
              insetPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                padding: EdgeInsets.all(10),

                //DECORACIÓN PARA EL CONTENEDOR DE LA TARJETA GRANDE
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  border: Border.all(
                      width: 6,
                      color: Colors.pinkAccent
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),

                //CONTENIDO DENTRO DE LA TARJETA GRANDE
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
                  children: [
                    StatefulBuilder(
                      builder: (context, setInnerState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Titulo
                          Align(
                            alignment: AlignmentGeometry.center,
                            child: Text(
                                "Filtro",
                                softWrap: true,
                                style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                          ),

                          //Subtítulo
                          Text(
                              "Por tipo de lugar:",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  decoration: TextDecoration.none
                              )
                          ),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 1.0,
                            children: _tipoLugar.map((String tipo) {
                              return ChoiceChip(
                                label: Text(tipo),
                                selected: _seleccionTipo == tipo,
                                selectedColor: Colors.pink.shade700,
                                backgroundColor: Colors.white70,
                                onSelected: (seleccionado) {
                                  setInnerState(() {
                                    _seleccionTipo = seleccionado ? tipo : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          //Subtítulo
                          Text(
                              "Por alcaldía:",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  decoration: TextDecoration.none
                              )
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 80, 0),
                            child: DropdownButtonFormField<String>(
                              initialValue: _seleccionAlcaldia,
                              items: _listaAlcaldias.map((String alcaldias) {
                                return DropdownMenuItem(
                                  value: alcaldias,
                                  child: Text(
                                    alcaldias,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (nuevoValor) {
                                setInnerState(() {
                                  _seleccionAlcaldia = nuevoValor;
                                });
                              },
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                hintText: "Selecciona una alcaldía",
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.pink.shade800,
                                        width: 4.0
                                    )
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.pink.shade800,
                                        width: 4.0
                                    )
                                ),
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              menuMaxHeight: 200,
                              isDense: true, //Menú desplegable con igual tamaño al botón.
                              isExpanded: true, //El texto no empuja al botón.
                              padding: EdgeInsets.all(4),
                              dropdownColor: Colors.pink,
                            ),
                          ),

                          SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.pink.shade800,
                                    foregroundColor: Colors.white,
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.bold
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                ),
                                onPressed: () {
                                  _aplicarFiltros(_seleccionTipo, _seleccionAlcaldia);
                                  Navigator.pop(context); // Close the filter card
                                },
                                child: Text("Filtrar"),
                              ),
                              ElevatedButton(
                                style: TextButton.styleFrom(
                                    backgroundColor: Colors.pink.shade800,
                                    foregroundColor: Colors.white,
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.bold
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                ),
                                onPressed: () {
                                  setInnerState(() {
                                    _seleccionTipo = null;
                                    _seleccionAlcaldia = null;
                                  });
                                  _limpiarFiltro();
                                },
                                child: Text("Limpiar Filtro"),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            /* FIN CÓDIGO DE LA TARJETA GRANDE */
          },
        );
      }

      void _aplicarFiltros(String? tipo, String? alcaldia) async {
        Query consulta = FirebaseFirestore.instance
            .collection('coleccion-lugares');
        if(tipo != null) {
          consulta = consulta.where("etiqueta", isEqualTo: tipo);
        }

        if(alcaldia != null) {
          consulta = consulta.where("alcaldia", isEqualTo: alcaldia);
        }

        final datos = await consulta.get();

        setState(() {
          _resultadosLugares = datos.docs;
        });
      }

      void _limpiarFiltro() async {
        final datos = await FirebaseFirestore.instance.collection('coleccion-lugares').get();

        setState(() {
          _resultadosLugares = datos.docs;
        });
      }

      /* LISTA DE PÁGINAS QUE ES LLENADO A FUTURO DE MANERA ASÍNCRONA */
      Future<void> _entrada() async {
        //Variable para obtener las colecciones de lugares para agendar en la
        //aplicación
        final datos = await FirebaseFirestore.instance.collection('coleccion-lugares').get();
        setState(() {
          _resultadosLugares = datos.docs;
        });
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: PageView(
            controller: _controladorPagina,
            onPageChanged: _paginaCambiada,
            children: [
              ListView( // Código para la pantalla principal.
                children: [
                  Container(
                      padding: EdgeInsets.only(top: 18),
                      child: Column(
                          children: [
                            Text(
                                "¡Hola!",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                            Text(
                                "¿A dónde irás hoy?",
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold
                                )
                            )
                          ]
                      )
                  ),

                  /* CÓDIGO DE LA TARJETA QUE SE LLENA CON LOS ELEMENTOS DE 'datosFirebase' */
                  for (var doc in _resultadosLugares)
                    _tarjetaRosaInicio(doc)
                ],
              ),
              Calendario(),
              Usuario()
            ],
          ),

          floatingActionButton: _indiceMenu == 0 ?
          FloatingActionButton(
              tooltip: 'Filtrar',
              mini: true,
              backgroundColor: Colors.grey.shade100,
              onPressed: _mostrarFiltrador,
              child: Icon(Icons.filter_alt)
          )
          : null ,


          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _indiceMenu,
            backgroundColor: Colors.grey.shade100,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black38,
            onTap: _itemPresionado,
            items: const <BottomNavigationBarItem> [
              BottomNavigationBarItem(
                  icon: Icon(
                      Icons.home
                  ),
                  label: "Inicio"
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                      Icons.calendar_month
                  ),
                  label: "Calendario"
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.account_box
                  ),
                  label: "Tú"
              )
            ],
          ),

        );
      }
}