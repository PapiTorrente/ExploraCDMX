//Imports para usar Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

//Imports para la página principal
import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'package:url_launcher/url_launcher.dart'; //Import para abrir enlaces.
import 'package:cached_network_image/cached_network_image.dart'; //Import para cargar imagenes de internet con cache.

//Imports para la página del calendario
import 'package:syncfusion_flutter_calendar/calendar.dart'; //Import del calendario
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart'; //Import del selector de fechas
import 'package:flex_color_picker/flex_color_picker.dart'; //Import del selector de color

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ExploraCDMXApp());
}

/* CLASE PRINCIPAL DE UN WIDGET SIN ESTADO */
class ExploraCDMXApp extends StatelessWidget {
  const ExploraCDMXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //Titulo efectivo de la aplicación.
      title: 'Hora de Explorar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/* ESPACIO PARA LA AUTENTICACIÓN / INICIO DE SESIÓN */
class ServicioAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //FUNCIÓN DE REGISTRO
  Future<User?> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //Registro de usuario exitoso
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error de Registro: ${e.message}');
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
    } on FirebaseAuthException catch (e) {
      print('Error de Inicio de Sesión: ${e.message}');
      return null;
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
    return null;
  }

  //OBTENER EL ESTADO DE AUTENTICACIÓN
  Stream<User?> get userChanges => _auth.authStateChanges();
}

/* CLASE PARA MOSTRAR PRIMERO LA PANTALLA DE INICIO O EL INICIO DE LA APP */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: ServicioAuth().userChanges, // Escucha el estado
      builder: (context, snapshot) {
        // Muestra una pantalla de carga mientras se decide
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si el usuario SI está logueado, muestra la página de principa.
        if (snapshot.hasData && snapshot.data != null) {
          return const PPrincipal(title: 'Hora de Explorar');
        }

        // Si el usuario NO está logueado, muestra la página de inicio de sesión.
        return const PInicioSesion();
      },
    );
  }
}

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
    void _InicioHandler() async {
      final email = _controladorCorreo.text.trim();
      final password = _controladorContra.text.trim();

      if(email.isEmpty || password.isEmpty) {
        _mostrarSnackBar("Error. Correo y contraseña obligatorios.");
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

    /* MÉTODO DE REGISTRO DE USUARIO */
    void _RegistroHandler() async {
      final email = _controladorCorreo.text.trim();
      final password = _controladorContra.text.trim();

      if(email.isEmpty) {
        _mostrarSnackBar("Error. No colocaste un correo.");
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
        }
      } on FirebaseAuthException catch (e) {
        String mensajeError = "";
        if(e.code == 'email-already-in-use') {
          mensajeError = "Correo en uso. Intente otro correo.";
        } else if(e.code == 'invalid-email') {
          mensajeError = "No es un correo.";
        }
        _mostrarSnackBar(mensajeError);
      } catch (e) {
        _mostrarSnackBar("Ha sucedido un error. Intente nuevamente.");
      }
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
                Container(
                  child: Column(
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
                          "Inicio de Sesión",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ]
                  )
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
                  onPressed: _InicioHandler,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    backgroundColor: Colors.pinkAccent
                  ),
                  child: Text(
                    "INICIAR SESIÓN",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                    )
                  ),
                ),
                SizedBox(height: 16),

                //BOTÓN DE REGISTRO
                OutlinedButton(
                  onPressed: _RegistroHandler,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 26),
                    side: BorderSide(color: Colors.pink, width: 2)
                  ),
                  child: Text(
                    "REGISTRAME",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.pink
                    )
                  )
                ),

                SizedBox(height: 16),
                //BARRA ESPACIADORA DE CONCEPTOS
                const Divider(),
                SizedBox(height: 16),

                OutlinedButton(
                    onPressed: _recuperarContrasenia,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(16),
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

/* WIDGET CON ESTADO QUE CAMBIA SEGÚN LA INTERACCIÓN CON EL USUARIO*/
class PPrincipal extends StatefulWidget {
  const PPrincipal({super.key, required this.title});
  final String title;
  @override
  State<PPrincipal> createState() => _PPrincipalState();
}

/* ESTADO PRINCIPAL CON EL QUE INICIA LA APLICACIÓN */
class _PPrincipalState extends State<PPrincipal> {
  /* ESPACIO DE LAS VARIABLES GLOBALES */
      //Indice del elemento en la lista _paginas usado para cambiar entre ellos.
      var _indiceMenu = 0;

      //Controlador de la animación de la página.
      final PageController _controladorPagina = PageController(initialPage: 0);

      //Lista de widgets que se mostrarán en la página.
      List<Widget> _paginas = [];

      /*VARIABLES PARA EL USO DEL CALENDARIO*/
      //Fecha de inicio y final para antes de seleccionar.
      DateTime now = DateTime.now();

      //Fecha de inicio de un solo evento que se muestra en el calendario.
      DateTime? _fechaInicio = DateTime.now();

      //Fecha de finalización de un solo evento que se muestra en el calendario.
      DateTime? _fechaFinalizacion = DateTime.now();

      //Color elegido por el usuario. Por defecto es pinkAccent.
      Color? _colorElegido = Colors.pinkAccent;

      //Lista que almacena los eventos del calendario.
      final List<Appointment> _reuniones = [];

      //Fuente de los datos para el llenado del calendario.
      MeetingDataSource? _dataSource;

      late final correo = FirebaseAuth.instance.currentUser?.email;

  /* FIN ESPACIO DE LAS VARIABLES GLOBALES */

  /* METODO DE INICIALIZACIÓN DE TODOS LOS WIDGETS */
      @override
      void initState() {
        super.initState();
        //Llamada al metodo asíncrono.
        _entrada();
        //Guarda la lista de reuniones para visualizarlos en el calendario.
        _dataSource = MeetingDataSource(_reuniones);
        //Función que carga los eventos guardados en Firebase, eventos anteriormente
        //guardados y necesarios para cuando inicie la aplicación.
        _cargarEventosDesdeFirestore();
      }
  /* FIN METODO DE INICIALIZACIÓN DE TODOS LOS WIDGETS */

  /* MÉTODO DE DESECHO DE CONTROLADORES */
  @override
  void dispose() {
    _controladorPagina.dispose();
    super.dispose();
  }
  /* FIN MÉTODO DE DESECHO DE CONTROLADORES */

  /* FUNCIONES DEL CALENDARIO */
      void _fijarFechaInicial(DateTime fechaNueva) {
        setState(() {
          _fechaInicio = fechaNueva;
        });
      }

      void _fijarFechaFinal(DateTime fechaNueva) {
        setState(() {
          _fechaFinalizacion = fechaNueva;
        });
      }

      /*FUNCION PARA AGENDAR UN EVENTO EN EL CALENDARIO*/
      void _agendarVisitaLugar(String subject) async {
        final DateTime hoy = _fechaInicio!;
        final DateTime fechaFinal = _fechaFinalizacion!;
        //Define una hora de inicio de un evento.
        final DateTime startTime = DateTime(
            hoy.year, hoy.month, hoy.day, hoy.hour, hoy.minute, hoy.second);
        //Define una hora de fin de un evento.
        final DateTime endTime = DateTime(
            fechaFinal.year, fechaFinal.month, fechaFinal.day, fechaFinal.hour,
            fechaFinal.minute, fechaFinal.second);

        //Crea un evento con la información enviada por el usuario.
        final nuevoEvento = Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: subject,
          color: _colorElegido!,
        );

        setState(() {
          //Añade un evento a una lista de eventos del calendario.
          _reuniones.add(nuevoEvento);
        });
        //Envia como entrada un evento para guardarlo en Firebase.
        guardarEventoEnFirestore(nuevoEvento);
      }

      /*FUNCION PARA GUARDAR UN EVENTO EN FIREBASE, RECIBE COMO ENTRADA
      * EL EVENTO PARA GUARDARLO EN FIREBASE*/
      Future<void> guardarEventoEnFirestore(Appointment evento) async {
        try {
          //Variable MAP para guardar la información del evento y con ese MAP
          //definido, guardar la información en Firebase.
          final user = FirebaseAuth.instance.currentUser;
          if(user == null) return;

          final eventoData = {
            'uid': user.uid,
            'startTime': evento.startTime.toIso8601String(),
            'endTime': evento.endTime.toIso8601String(),
            'subject': evento.subject,
            'color': evento.color.value32bit,
          };
          //Guarda el registro del evento en Firebase.
          await FirebaseFirestore.instance.collection('eventos').add(eventoData);
        } catch (e) {
          throw Error();
        }
      }

      /*FUNCION PARA GARGAR LOS EVENTOS GUARDADOS EN FIREBASE*/
      Future<void> _cargarEventosDesdeFirestore() async {
        final user = FirebaseAuth.instance.currentUser;
        if(user == null) return;
        //Obtiene todos los registros de Firebase de la colección de eventos.
        final snapshot = await FirebaseFirestore.instance
            .collection('eventos')
            .where('uid', isEqualTo: user.uid)
            .get();

        //Transforma los registros obtenidos de Firebase en una lista del tipo
        //appointment
        final List<Appointment> eventosCargados = snapshot.docs.map((doc) {
          final data = doc.data();
          //Obtiene cada evento en forma de llave-valor para obtener sus elementos
          //y crear una nueva lista para visualizar los eventos en el calendario.
          return Appointment(
            startTime: DateTime.parse(data['startTime']),
            endTime: DateTime.parse(data['endTime']),
            subject: data['subject'],
            color: Color(data['color']),
          );
        }).toList();
        setState(() {
          //Agrega los eventos a la lista de eventos.
          _reuniones.addAll(eventosCargados);
          //Envia a la fuente de datos del calendario la lista de eventos obtenida
          //de Firebase
          _dataSource!.notifyListeners(CalendarDataSourceAction.reset, _reuniones);
        });
      }

      //FUNCION PARA IMPRIMIR EN CONSOLA LOS EVENTOS
      //ALMACENADOS EN FIREBASE - NO ES NECESARIO
      Future<void> obtenerEventos() async {
        try {
          // Referencia a la colección 'eventos'
          CollectionReference eventos = FirebaseFirestore.instance.collection(
              'eventos');

          // Obtener todos los documentos de la colección
          QuerySnapshot snapshot = await eventos.get();

          // Recorrer e imprimir cada documento
          for (var doc in snapshot.docs) {
            // Convertir a Map para acceder a los campos
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Acceder a valores específicos
            String startTime = data['startTime'] ?? 'Fecha no disponible';
            String endTime = data['endTime'] ?? 'Fecha no disponible';
            String subject = data['subject'] ?? 'Sin Asunto';
            int colorValue = data['color'] ?? 0xFF000000; // Negro por defecto
          }
        } catch (e) {
          throw Error();
        }
      }

      List<Appointment> obtenerReuniones() {
        List<Appointment> reuniones = <Appointment>[];
        return reuniones;
      }
  /* FIN FUNCIONES DEL CALENDARIO */

  /* FUNCIONES DEL ASPECTO VISUAL DE LA APLICACIÓN */
      /* FUNCIÓN PARA MOSTRAR LA TARJETA GRANDE */
      void _mostrarTarjetaGrande(doc) {
        //Guarda el string almacenado en el campo 'enlaceWeb' para los enlaces webs.
        String eWeb = '${doc['enlaceWeb']}';
        //Cambia de tipo de dato 'String' a 'Uri' para ser manejado por
        //la dependencia url_launcher y ser enviado al navegador del dispositivo.
        final enlace = Uri.parse(eWeb);
        //Función asíncrona que muestra una ventana sobre toda la aplicación y
        //bloquea el resto de la aplicación.
        showDialog(
          builder: (context) {

            /* CÓDIGO DE LA TARJETA GRANDE */
            return Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                    child: Container(
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.all(10),
                        //DECORACIÓN PARA EL CONTENEDOR DE LA TARJETA GRANDE
                        decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            border: Border.all(
                                width: 6,
                                color: Colors.pinkAccent
                            ),
                            borderRadius: BorderRadius.circular(8)
                        ),

                        //CONTENIDO DENTRO DE LA TARJETA GRANDE
                        child: Column(
                          children: [
                            //CONTENEDOR PARA LA IMAGEN EN LA TARJETA GRANDE
                            Container(
                              height: 170,
                              //DECORACIÓN DEL CONTENEDOR DE LA IMAGEN EN LA TARJETA
                              //GRANDE
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 6,
                                      color: Colors.pink.shade800
                                  ),
                                  borderRadius: BorderRadius.circular(2)
                              ),

                              //IMAGEN DE LA TARJETA GRANDE
                              //SizedBox forza a que la imagen ocupe el tamaño que
                              //queremos
                              child: SizedBox(
                                width: double.infinity,
                                height: 170,
                                //Descarga las imágenes desde el enlace y las guarda
                                //en el caché del dispositivo.
                                child: CachedNetworkImage(
                                  imageUrl: doc['imagen'],
                                  fit: BoxFit.cover,
                                  //PLACEHOLDER PARA LA ESPERA DE LA CARGA DE LA IMAGEN.
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  //WIDGET DE ERROR SI NO SE CARGÓ LA IMAGEN.
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),

                            SizedBox(height: 4,),

                            //TEXTO DEL TITULO DE LA TARJETA GRANDE
                            Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "${doc['nombre']}",
                                  //Permite que ocupe más espacio si no es suficiente
                                  softWrap: true,
                                  style: TextStyle(
                                      fontSize: 32,
                                      color: Colors.black,
                                      decoration: TextDecoration.none,
                                      fontWeight: FontWeight.bold
                                  ),
                                )
                            ),

                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.pinkAccent, width: 4),
                                  right: BorderSide(color: Colors.pinkAccent, width: 2),
                                )
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //TEXTO DE LA DESCRIPCIÓN
                                  Container(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        //CONTENEDOR DEL TEXTO "DESCRIPCIÓN QUE DEBE CAMBIARSE DINÁMICAMENTE
                                        Text(
                                          "${doc['descripcion']}",
                                          //Permite que ocupe más espacio si no es suficiente
                                          softWrap: true,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black,
                                              decoration: TextDecoration.none
                                          ),
                                        )
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 6,),

                                  //TEXTO DE LA UBICACIÓN
                                  Container(
                                    margin: EdgeInsets.only(top: 4, bottom: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        //CONTENEDOR DEL TEXTO UBICACIÓN
                                        Text(
                                          "Ubicación:",
                                          style: TextStyle(
                                              fontSize: 24,
                                              color: Colors.black,
                                              decoration: TextDecoration.none
                                          ),
                                        ),

                                        //CONTENEDOR DEL TEXTO "UBICACIÓN" QUE DEBE CAMBIARSE DINÁMICAMENTE
                                        Text(
                                          "${doc['ubicacion']}",
                                          //Permite que ocupe más espacio si no es suficiente
                                          softWrap: true,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black,
                                              decoration: TextDecoration.none
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 6,),

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
                                            borderRadius: BorderRadius.circular(4),
                                          )
                                      ),
                                      onPressed: () => launchUrl(
                                          enlace,
                                          mode: LaunchMode.externalApplication
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Más información en su sitio web. ¡Presioname!",
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

                            //Empuja el espacio disponible para que los
                            //botones siempre estén abajo.
                            Expanded(child: SizedBox()),

                            //ESPACIO PARA LOS BOTONES DE LA TARJETA GRANDE
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                //CONTENEDOR DEL BOTÓN PARA AGREGAR EVENTO
                                ElevatedButton(
                                    style: TextButton.styleFrom(
                                        backgroundColor: Colors.pink.shade800,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        )
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      //FUNCION PARA MOSTRAR LA TARJETA PARA AGENDAR
                                      //UN EVENTO, DADO UN EVENTO SELECCIONADO
                                      _agregarAlCalendario(doc['nombre']);
                                    },
                                    child: Text(
                                      "Agendar",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold
                                      ),
                                    )
                                ),
                                SizedBox(width: 8),

                                //CONTENEDOR DEL BOTÓN PARA CERRAR LA TARJETA GRANDE
                                ElevatedButton(
                                    style: TextButton.styleFrom(
                                        backgroundColor: Colors.pink.shade800,
                                        foregroundColor: Colors.black,
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold
                                      ),
                                    )
                                )
                              ],
                            )
                          ],
                        )
                    )
                )
              ],
            );
            /* FIN CÓDIGO DE LA TARJETA GRANDE */

          },
          context: context,
        );
      }
      /* FIN FUNCIÓN PARA MOSTRAR TARJETA GRANDE */

      /* FUNCIÓN PARA AGREGAR EL LUGAR AL CALENDARIO, NECESITA COMO ENTRADA
      * EL NOMBRE DEL EVENTO A AGREGAR AL CALENDARIO*/
      void _agregarAlCalendario(String titulo) {
        //Función asíncrona que muestra una ventana sobre toda la aplicación y
        //bloquea el resto de la aplicación.
        showDialog(
          builder: (context) {
            return Flex(
              direction: Axis.horizontal,
              children: [

                /* CÓDIGO DE LA TARJETA PARA AGREGAR AL CALENDARIO */
                Expanded(
                    child: Container(
                        padding: EdgeInsets.all(4), // Hacia adentro
                        margin: EdgeInsets.all(10), // Hacia afuera
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
                          children: [

                            //CONTENEDOR PARA EL TEXTO DE LA FECHA DE INICIO
                            Align(
                                alignment: Alignment.center,
                                child: Container(
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
                                      Text(
                                        "Día y hora de Inicio:",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            decoration: TextDecoration.none
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      SizedBox(
                                        child: CupertinoCalendarPickerButton(
                                          buttonDecoration: PickerButtonDecoration(
                                              backgroundColor: Colors.pinkAccent
                                          ),
                                          minimumDateTime: DateTime(now.year, now.month, now.day),
                                          maximumDateTime: DateTime(now.year + 4, now.month, now.day),
                                          initialDateTime: DateTime.now(),
                                          currentDateTime: DateTime.now(),
                                          mode: CupertinoCalendarMode.dateTime,
                                          timeLabel: 'Inicio',
                                          onDateTimeChanged: (date) {
                                            _fijarFechaInicial(date);
                                          },),
                                      ),
                                    ],
                                  ),
                                )
                            ),

                            SizedBox(height: 10),

                            //CONTENEDOR PARA EL TEXTO DE LA FECHA DE FINALIZACIÓN
                            Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.only(bottom: 10),
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
                                      Text(
                                        "Día y hora de Finalización:",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            decoration: TextDecoration.none
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      SizedBox(
                                        child: CupertinoCalendarPickerButton(
                                          buttonDecoration: PickerButtonDecoration(
                                              backgroundColor: Colors.pinkAccent
                                          ),
                                          minimumDateTime: DateTime.now(),
                                          maximumDateTime: DateTime(2080, 12, 12),
                                          initialDateTime: DateTime.now(),
                                          currentDateTime: DateTime.now(),
                                          mode: CupertinoCalendarMode.dateTime,
                                          timeLabel: 'Final',
                                          onDateTimeChanged: (date) {
                                            _fijarFechaFinal(date);
                                          },),
                                      ),
                                    ],
                                  ),
                                )
                            ),

                            //CONTENEDOR PARA LA ELECCIÓN DE COLOR
                            Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.pinkAccent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          width: 8,
                                          color: Colors.pink.shade800
                                      )
                                  ),

                                  child: ColorPicker(
                                    pickersEnabled: const <ColorPickerType, bool>{
                                      ColorPickerType.primary: true,
                                      ColorPickerType.accent: false,
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
                                )
                            ),

                            //Empuja el espacio disponible para que los
                            //botones siempre estén abajo.
                            Expanded(child: SizedBox()),

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
                                      _agendarVisitaLugar(titulo);
                                      //Reestablece los valores
                                      _fechaInicio = DateTime.now();
                                      _fechaFinalizacion = DateTime.now();
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
                        )
                    )
                )
                /* FIN CÓDIGO DE LA TARJETA PARA AGREGAR AL CALENDARIO*/

              ],
            );
          },
          context: context,
        );
      }
      /* FIN FUNCIÓN PARA AGREGAR EL LUGAR AL CALENDARIO */

      /* FUNCIONES PARA CAMBIAR DE PANTALLA EN EL MENÚ BAJO */
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
      /* FIN DE FUNCIONES PARA CAMBIAR DE PANTALLA EN EL MENÚ BAJO */
  /* FIN FUNCIONES DEL ASPECTO VISUAL DE LA APLICACIÓN */

  /* ASPECTO VISUAL DE LA APLICACIÓN */
      /* LISTA DE PÁGINAS QUE ES LLENADO A FUTURO DE MANERA ASÍNCRONA */
      Future<void> _entrada() async {
        //Variable para obtener las colecciones de lugares para agendar en la
        //aplicación
        final snapshot = await FirebaseFirestore.instance.collection('coleccion-lugares').get();
        _paginas = [
          //AQUI AGREGAR EL COLOR DE LA PÁGINA

          /* CÓDIGO PARA LA PANTALLA PRINCIPAL */
          ListView(
            children: [

              //CONTENEDOR DEL SALUDO EN LA PANTALLA PRINCIPAL
              Container(
                  padding: EdgeInsets.only(top: 18),
                  child: Column(
                      children: [
                        //TEXTOS DEL SALUDO EN LA PANTALLA PRINCIPAL. SON ESTÁTICOS.
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

              /* CÓDIGO DE LA TARJETA QUE SE LLENA CON LOS ELEMENTOS DE 'snapshot'
          * OBTENIDOS DE LA BASE DE DATOS EN FIREBASE */
              for (var doc in snapshot.docs)
                Container(
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
                )
              /* FIN CÓDIGO DE LA TARJETA EN LA PANTALLA PRINCIPAL */

            ],
          ),
          /* FIN CÓDIGO PARA LA PANTALLA PRINCIPAL */

          /* CÓDIGO PARA LA PANTALLA DEL CALENDARIO */
          Column(
            children: [
              //TEXTO ESTÁTICO EN LA PANTALLA DEL CALENDARIO
              Container(
                padding: EdgeInsets.only(top: 18),
                child: Text(
                    "Calendario",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold
                    )
                ),
              ),

              /* CÓDIGO DEL CALENDARIO EN LA PANTALLA SECUNDARIA */
              Flexible(
                  child: Container(
                    margin: EdgeInsets.all(10),
                    //DECORACÍON DE LOS BORDES DEL CONTENEDOR DEL CALENDARIO
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 4,
                            color: Colors.pink.shade800
                        ),
                        borderRadius: BorderRadius.circular(8)
                    ),

                    //CALENDARIO
                    child: SfCalendar(
                      view: CalendarView.month,
                      initialSelectedDate: DateTime.now(),
                      headerStyle: CalendarHeaderStyle(
                          backgroundColor: Colors.pinkAccent,
                          textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black
                          )
                      ),
                      cellBorderColor: Colors.transparent,
                      todayHighlightColor: Colors.pink,
                      selectionDecoration: BoxDecoration(
                          color: Colors.transparent
                      ),
                      monthViewSettings: MonthViewSettings(
                        showAgenda: true,
                      ),
                      //Indicamos de dónde obtendrá los datos, en este caso,
                      //nuestra variable que obtuvo los registros de Firebase
                      dataSource: _dataSource,

                      //FUNCIONALIDAD DE PRESIONADO CORTO (EDITAR)
                      onTap: null,
                      //FUNCIONALIDAD DE PRESIONADO LARGO (ELIMINAR)
                      onLongPress: null,
                    ),
                  )
              )
              /* FIN CÓDIGO DEL CALENDARIO EN LA PANTALLA SECUNDARIA*/
            ],
          ),
          /* FIN CÓDIGO PARA EL CALENDARIO */

          /* CÓDIGO PARA LA PANTALLA DE PERFIL DE USUARIO */
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 18),
                child: Text(
                  "Tu Cuenta",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold
                  )
                )
              ),
              Container(
                padding: EdgeInsets.all(3),
                child: Text(
                  "$correo",
                  style: TextStyle(
                    fontSize: 20
                  ),
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
                    backgroundColor: Colors.pinkAccent
                ),
                child: Text(
                    "Reestablecer mi contraseña",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black
                    )
                ),
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
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 61),
                    backgroundColor: Colors.pinkAccent
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
              OutlinedButton(
                  onPressed: () async {
                    await ServicioAuth().borrarCuenta();
                  },
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 56),
                      backgroundColor: Colors.red,
                      side: BorderSide(color: Colors.red, width: 2)
                  ),
                  child: Text(
                      "BORRAR CUENTA",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black
                      )
                  )
              ),
            ]
          )
          /* FIN CÓDIGO PARA LA PANTALLA DE PERFIL DE USUARIO */
        ];
      }
      /* FIN DE LA LISTA DE PÁGINAS */

      @override
      Widget build(BuildContext context) {

        return Scaffold(
          /* CÓDIGO DE LA VISTA DE LA PÁGINA SELECCIONADA */
          body: PageView(
            controller: _controladorPagina,
            onPageChanged: _paginaCambiada,
            //Physics evita el scroll horizontal para que sea solo por el menu
            physics: const NeverScrollableScrollPhysics(),
            children: _paginas,
          ),
          /* FIN CÓDIGO DE LA VISTA DE LA PÁGINA SELECCIONADA */

          /* CÓDIGO DE LA BARRA DE NAVEGACIÓN */
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _indiceMenu,
            backgroundColor: Colors.pink.shade600,
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
          /* FIN CÓDIGO DE LA BARRA DE NAVEGACIÓN */

        );
      }
  /* FIN ASPECTO VISUAL DE LA APLICACIÓN */
}
/* FIN ESTADO PRINCIPAL CON EL QUE INICIA LA APLICACIÓN */

/* CÓDIGO CREADO EN LA CLASE DE PROGRAMACIÓN MÓVIL PARA EL USO DEL CALENDARIO */
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }
}
