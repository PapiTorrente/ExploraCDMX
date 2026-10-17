import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'package:syncfusion_flutter_calendar/calendar.dart'; //Import del calendario
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart'; //Import del selector de fechas
import 'package:flex_color_picker/flex_color_picker.dart'; //Import del selector de color

//Imports para usar Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Calendario extends StatefulWidget {
  @override
  CalendarioState createState() => CalendarioState();
}

class CalendarioState extends State<Calendario> {
  //Fecha de inicio y final para antes de seleccionar.
  DateTime now = DateTime.now();

  //Fecha de inicio de un solo evento que se muestra en el calendario.
  DateTime? _fechaInicio = DateTime.now();

  //Fecha de finalización de un solo evento que se muestra en el calendario.
  DateTime? _fechaFinal = DateTime.now();

  //Color elegido por el usuario. Por defecto es pinkAccent.
  Color? _colorElegido = Colors.pinkAccent;

  //Lista que almacena los eventos del calendario.
  final List<Appointment> _reuniones = [];

  //Fuente de los datos para el llenado del calendario.
  MeetingDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    //Guarda la lista de reuniones para visualizarlos en el calendario.
    _dataSource = MeetingDataSource(_reuniones);
    //Función que carga los eventos guardados en Firebase, eventos anteriormente
    //guardados y necesarios para cuando inicie la aplicación.
    _cargarEventosDesdeFirestore();
  }

  void _fijarFechaInicial(DateTime fechaNueva) {
    setState(() {
      _fechaInicio = fechaNueva;
    });
  }

  void _fijarFechaFinal(DateTime fechaNueva) {
    setState(() {
      _fechaFinal = fechaNueva;
    });
  }

  /*FUNCION PARA GARGAR LOS EVENTOS GUARDADOS EN FIREBASE*/
  Future<void> _cargarEventosDesdeFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;
    //Obtiene todos los registros de Firebase de la colección de eventos.
    final datosFirebase = await FirebaseFirestore.instance
        .collection('eventos')
        .where('uid', isEqualTo: user.uid)
        .get();

    //Transforma los registros obtenidos de Firebase en una lista del tipo
    //appointment
    final List<Appointment> eventosCargados = datosFirebase.docs.map((doc) {
      final data = doc.data();
      //Obtiene cada evento en forma de llave-valor para obtener sus elementos
      //y crear una nueva lista para visualizar los eventos en el calendario.
      return Appointment(
        id: doc.id,
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

  /* FUNCIÓN PARA ACTUALIZAR UN EVENTO DEL CALENDARIO */
  void _guardarCambiosReunion(Appointment reunion) async {
    final String iD = reunion.id.toString();

    //Mega Casteo para poder insertar fechas
    final DateTime hoy = _fechaInicio!;
    final DateTime fechaFinal = _fechaFinal!;

    final DateTime startTime = DateTime(hoy.year, hoy.month, hoy.day, hoy.hour, hoy.minute, hoy.second);
    final DateTime endTime = DateTime(fechaFinal.year, fechaFinal.month, fechaFinal.day, fechaFinal.hour, fechaFinal.minute, fechaFinal.second);

    try {
      setState(() {
        //Crea un evento con la información actualizada.
        final eventoActualizado = Appointment(
          id: iD,
          startTime: startTime,
          endTime: endTime,
          subject: reunion.subject,
          color: _colorElegido!,
        );

        //Reemplazar en la lista de reuniones local.
        int index = _reuniones.indexOf(reunion);
        if(index != -1) {
          _reuniones[index] = eventoActualizado;
        }

        //Actualizamos la UI.
        _dataSource!.notifyListeners(CalendarDataSourceAction.reset, _reuniones);
      });

      final eventoActualizadoFirestore = {
        'startTime': _fechaInicio!.toIso8601String(),
        'endTime': _fechaFinal!.toIso8601String(),
        'subject': reunion.subject,
        'color': _colorElegido!.toARGB32(),
      };

      FirebaseFirestore
          .instance
          .collection('eventos')
          .doc(iD)
          .update(eventoActualizadoFirestore);
    } catch (e) {
      //print("Error al actualizar: $e");
    }
  }

  /* FUNCIÓN PARA AGENDAR UN EVENTO EN EL CALENDARIO*/
  void agendarVisitaLugar(String subject, DateTime fechaInicial, DateTime fechaFinal, Color color) async {

    //Crea un evento con la información enviada por el usuario.
    final nuevoEvento = Appointment(
      startTime: fechaInicial,
      endTime: fechaFinal,
      subject: subject,
      color: color,
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

  /* FUNCIÓN PARA EDITAR UN EVENTO DEL CALENDARIO */
  void _editarReunion(Appointment reunion) {
    setState(() {
      _fechaInicio = reunion.startTime;
      _fechaFinal = reunion.endTime;
      _colorElegido = reunion.color;
    });

    final DateTime fechaInicial = reunion.startTime;
    final DateTime fechaFinal = reunion.endTime;

    showDialog(
      builder: (context) {
        return Flex(
          direction: Axis.horizontal,
          children: [

            /* CÓDIGO DE LA TARJETA QUE MUESTRA LOS DATOS DEL CALENDARIO */
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

                    //CONTENIDO DENTRO DE LA TARJETA DE EDICIÓN DE REUNIÓN
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
                                      minimumDateTime: fechaInicial,
                                      maximumDateTime: DateTime(now.year + 4, now.month, now.day),
                                      initialDateTime: fechaInicial,
                                      currentDateTime: fechaInicial,
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
                                      minimumDateTime: fechaInicial,
                                      maximumDateTime: DateTime(now.year + 4, now.month, now.day),
                                      initialDateTime: fechaFinal,
                                      currentDateTime: fechaFinal,
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
                                selectedPickerTypeColor: reunion.color,
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
                                  //Llamada a función para editar un evento al calendario.
                                  _guardarCambiosReunion(reunion);
                                  //Reestablece los valores
                                  _fechaInicio = DateTime.now();
                                  _fechaFinal = DateTime.now();
                                  _colorElegido = Colors.pinkAccent;

                                  //Cierra la tarjeta de agregar
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Guardar cambios",
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

  /* FUNCIÓN PARA ELIMINAR UN EVENTO DEL CALENDARIO */
  void _confirmarEliminacion(Appointment reunion) {
    showDialog(
      builder: (context) {
        return AlertDialog(
          title: Text("Eliminar Evento"),
          content: Text("¿Estás seguro de querer eliminar este evento de tu calendario?"),
          actions: [
            //BOTÓN PARA CANCELAR LA ELIMINACIÓN
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
                  "Cancelar",
                  style: TextStyle(
                      color: Colors.white
                  ),
                )
            ),

            //BOTÓN DE CONFIRMAR LA ELIMINACIÓN
            ElevatedButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.pink.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    )
                ),
                onPressed: () async {
                  //Cierra la tarjeta de agregar
                  try {
                    String docID = reunion.id.toString();
                    await FirebaseFirestore
                        .instance
                        .collection('eventos')
                        .doc(docID)
                        .delete();

                    setState(() {
                      _reuniones.remove(reunion);
                      _dataSource?.notifyListeners(CalendarDataSourceAction.remove, [reunion]);
                    });

                    Navigator.of(context).pop();
                  } catch (e) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  "Si, eliminar",
                  style: TextStyle(
                      color: Colors.white
                  ),
                )
            ),
          ],
        );
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //TEXTO ESTÁTICO EN LA PANTALLA DEL CALENDARIO
        Container(
          padding: EdgeInsets.only(top: 42),
          child: Text(
              "Calendario",
              style: TextStyle(
                  fontSize: 50,
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
                onTap: (CalendarTapDetails detallesCalendarioOT) {
                  if(detallesCalendarioOT.appointments != null && detallesCalendarioOT.appointments!.isNotEmpty) { //Confirmamos que no es nulo ni vacío.
                    //Obtenemos la reunión tocada.
                    final Appointment reunion = detallesCalendarioOT.appointments![0];
                    //Llamamos a la función de edición con la info. de la reunión a editar.
                    _editarReunion(reunion);
                  }
                },
                //FUNCIONALIDAD DE PRESIONADO LARGO (ELIMINAR)
                onLongPress: (CalendarLongPressDetails detallesCalendarioOLP) {
                  if(detallesCalendarioOLP.appointments != null && detallesCalendarioOLP.appointments!.isNotEmpty) { //Confirmamos que no es nulo ni vacío.
                    //Obtenemos la reunión tocada.
                    final Appointment reunion = detallesCalendarioOLP.appointments![0];
                    //Llamamos a la función de eliminación con la info. de la reunión como parámetro.
                    _confirmarEliminacion(reunion);
                  }
                },
              ),
            )
        )
        /* FIN CÓDIGO DEL CALENDARIO EN LA PANTALLA SECUNDARIA*/

      ],
    );
  }
}

/* CÓDIGO CREADO EN LA CLASE DE PROGRAMACIÓN MÓVIL PARA EL USO DEL CALENDARIO */
class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  Object? getId(int index) {
    return appointments![index].id;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }
}