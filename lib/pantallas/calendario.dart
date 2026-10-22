import 'package:flutter/material.dart'; //Import para usar widgets y hacer interfaces
import 'package:syncfusion_flutter_calendar/calendar.dart'; //Import del calendario
import 'package:flex_color_picker/flex_color_picker.dart'; //Import del selector de color

//Imports para usar Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:exploracdmx/notificaciones.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  CalendarioState createState() => CalendarioState();
}

class CalendarioState extends State<Calendario> {
  //Variables que almacenan la fecha y hora elegidas por el usuario para su evento en calendario.
  DateTime _fechaElegida = DateTime.now();
  TimeOfDay _horaElegida = TimeOfDay.now();

  //Variables que almacenan las fechas iniciales y finales obtenidas de firebase al editar un evento.
  DateTime? _fechaCargada;
  TimeOfDay _horaCargada = TimeOfDay.now();

  //Color elegido por el usuario. Por defecto es pinkAccent.
  Color _colorElegido = Colors.pink;

  //Lista que almacena los eventos del calendario.
  final List<Appointment> _reuniones = [];

  //Fuente de los datos para el llenado del calendario.
  MeetingDataSource? _dataSource;

  final TextEditingController _controladorMinutos = TextEditingController();

  int _minutosAntesEvento = 0;

  @override
  void initState() {
    super.initState();
    _controladorMinutos.text = _minutosAntesEvento.toString();
    //Guarda la lista de reuniones para visualizarlos en el calendario.
    _dataSource = MeetingDataSource(_reuniones);
    //Función que carga los eventos guardados en Firebase, eventos anteriormente
    //guardados y necesarios para cuando inicie la aplicación.
    _cargarEventosDesdeFirestore();
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
        resourceIds: [
          data['idNotificacion']?.toString() ?? '',
          data['minutos']?.toString() ?? '',
        ],
        
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      //Agrega los eventos a la lista de eventos.
      _reuniones.addAll(eventosCargados);
      //Envia a la fuente de datos del calendario la lista de eventos obtenida
      //de Firebase
      _dataSource!.notifyListeners(CalendarDataSourceAction.reset, _reuniones);
    });
  }


  /* FUNCIONES PARA EDITAR UN EVENTO DEL CALENDARIO */
  void _mostrarSelectorFecha() {
    showDatePicker(
        context: context,
        initialDate: _fechaCargada,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365)),
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        helpText: "Elige la fecha",
        cancelText: "Cancelar",
        confirmText: "Confirmar"
    ).then((value) {
      setState(() {
        _fechaElegida = value!;
      });
    });
  }

  void _mostrarSelectorHora() {
    showTimePicker(
      context: context,
      initialTime: _horaCargada,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      orientation: Orientation.portrait,
      helpText: "Elige la hora",
      hourLabelText: "Hora",
      minuteLabelText: "Minuto",
      cancelText: "Cancelar",
      confirmText: "Confirmar",
    ).then((value) {
      setState(() {
        _horaElegida = value!;
      });
    });
  }

  void _editarReunion(Appointment reunion) {
    setState(() {
      _fechaCargada = reunion.startTime;
      _horaCargada = TimeOfDay.fromDateTime(reunion.startTime);
      _colorElegido = reunion.color;
      _controladorMinutos.text = reunion.resourceIds![1].toString();
    });

    showDialog(
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(8)),
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.pinkAccent,
                border: Border.all(width: 4, color: Colors.pinkAccent),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.pink.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        )),
                    onPressed: _mostrarSelectorFecha,
                    child: Text(
                      "Elige el día",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          decoration: TextDecoration.none),
                    )
                ),

                SizedBox(height: 8),

                ElevatedButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.pink.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        )),
                    onPressed: _mostrarSelectorHora,
                    child: Text(
                      "Elige la hora",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          decoration: TextDecoration.none),
                    )
                ),

                SizedBox(height: 8),

                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(8),
                      border:
                      Border.all(width: 8, color: Colors.pink.shade800)),
                  child: ColorPicker(
                    borderRadius: 4,
                    spacing: 4,
                    hasBorder: true,
                    borderColor: Colors.black,
                    enableShadesSelection: false,
                    showRecentColors: false,
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.both: false,
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: false,
                      ColorPickerType.custom: false,
                    },
                    selectedPickerTypeColor: Colors.white,
                    heading: Text(
                      "Elige el color",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          decoration: TextDecoration.none),
                    ),
                    onColorChanged: (Color value) {
                      _colorElegido = value;
                    },
                  ),
                ),

                SizedBox(height: 8),

                const Divider(color: Colors.black),

                SizedBox(height: 8),

                Align(
                  alignment: Alignment.center,
                  child: Text(
                      "Notificaciones",
                      style: TextStyle(
                        fontSize: 18,
                      )
                  ),
                ),
                TextFormField(
                    onChanged: ((value) {
                      setState(() {
                        _minutosAntesEvento = int.parse(value);
                      });
                    }),
                    controller: _controladorMinutos,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Minutos antes del evento",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        labelStyle: TextStyle(
                          color: Colors.black,
                        )
                    )
                ),

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
                            )),
                        onPressed: () {
                          DateTime _fechaReunion = DateTime(_fechaElegida.year, _fechaElegida.month, _fechaElegida.day, _horaElegida.hour, _horaElegida.minute);
                          _guardarCambiosReunion(reunion,_fechaReunion, _fechaReunion, _colorElegido, _minutosAntesEvento);

                          //Reestablece los valores
                          _fechaElegida = DateTime.now();
                          _horaElegida = TimeOfDay.now();
                          _fechaReunion = DateTime.now();
                          _colorElegido = Colors.pinkAccent;

                          //Cierra la tarjeta de agregar
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Guardar cambios",
                          style: TextStyle(color: Colors.white),
                        )),

                    //CONTENEDOR DEL BOTÓN PARA CERRAR LA TARJETA DE AGENDAR
                    ElevatedButton(
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.pink.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            )),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cerrar",
                          style: TextStyle(color: Colors.white),
                        )),
                  ],
                )
              ],
            ),
          ),
        );
      },
      context: context,
    );
  }

  /* FUNCIONES PARA ACTUALIZAR UN EVENTO DEL CALENDARIO */
  void _guardarCambiosReunion(Appointment reunion, DateTime _fechaInicial, DateTime _fechaFinal, Color color, int minutosAnterior) async {
    final String iD = reunion.id.toString();
    final int idNotifEliminar = int.parse(reunion.resourceIds![0].toString());
    final int idNotificacion = iD.hashCode + _fechaInicial.day;
    String? minutos = minutosAnterior.toString();
    Color _colorElegido = color;

    try {
      setState(() {
        //Crea un evento con la información actualizada.
        final eventoActualizado = Appointment(
          id: iD,
          startTime: _fechaInicial,
          endTime: _fechaFinal,
          subject: reunion.subject,
          color: _colorElegido,
          resourceIds: [
            idNotificacion,
            minutos,
          ],
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
        'startTime': _fechaInicial.toIso8601String(),
        'endTime': _fechaFinal.toIso8601String(),
        'subject': reunion.subject,
        'color': _colorElegido.toARGB32(),
        'idNotificacion': idNotificacion,
        'minutos': minutos
      };
      
      Notificacion.actualizarNotificacion(idNotifEliminar, _fechaInicial, int.parse(minutos!), reunion.subject);

      FirebaseFirestore
          .instance
          .collection('eventos')
          .doc(iD)
          .update(eventoActualizadoFirestore);
    } catch (e) {
      //print("Error al actualizar: $e");
    }
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
                      Notificacion.cancelarNotificacion(int.parse(reunion.notes!));
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