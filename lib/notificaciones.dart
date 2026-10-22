import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:timezone/data/latest_all.dart' as timezone;

class Notificacion {
  static final FlutterLocalNotificationsPlugin _notificacion =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;
  bool get estaInicializado => _inicializado;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    timezone.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('America/Mexico_City'));

    InitializationSettings initializationSettings =
        const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notificacion.initialize(
      settings: initializationSettings,
    );

    await _obtenerPermisoNotificacion();
    _inicializado = true;
  }

  static Future<void> _obtenerPermisoNotificacion() async {
    await _notificacion
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static NotificationDetails detallesNotificacion() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'important_notification',
        'Canal Principal',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //Sólo para ver que todo funciona :D
  Future<void> enviarNotificacion() async {
    return _notificacion.show(
      id: 0,
      title: '¡Hora de Explorar CDMX!',
      body: 'Tienes un evento programado.',
      notificationDetails: detallesNotificacion(),
    );
  }

  static Future<void> programarNotificacion(DateTime fechaReunion, int minutos, String titulo) async {
    final scheduledDate = timezone.TZDateTime.from(
      fechaReunion.subtract(Duration(minutes: minutos)),
      timezone.local,
    );

    //No se puede programar porque la fecha ya pasó.
    if (scheduledDate.isBefore(timezone.TZDateTime.now(timezone.local))) {
      return;
    }

    try{
      await _notificacion.zonedSchedule(
        id: fechaReunion.year + fechaReunion.month + fechaReunion.day + fechaReunion.hour + fechaReunion.minute, //Identificador único.
        title: '¡Hora de Explorar CDMX!',
        body: 'Tienes un evento programado en $minutos minutos para "$titulo".',
        scheduledDate: scheduledDate,
        notificationDetails: detallesNotificacion(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      //print("Programado");
    } catch (e) {
      //print("No se programó");
    }
    return;
  }

  static Future<void> actualizarNotificacion(int idNotifEliminar, DateTime fechaReunion, int minutos, String titulo) async {
    await _notificacion.cancel(id: idNotifEliminar);
    await programarNotificacion(fechaReunion, minutos, titulo);
  }

  static Future<void> cancelarNotificacion(int idNotificacion) async {
    await _notificacion.cancel(id: idNotificacion);
  }
}
