import 'package:cloud_firestore/cloud_firestore.dart';

class Persona {
  final String id;
  final String comunidadId;
  final String viviendaId;
  final String familiaId;

  // ============================================================
  // DATOS DE IDENTIFICACIÓN
  // ============================================================

  final String primerNombre;
  final String segundoNombre;
  final String primerApellido;
  final String segundoApellido;

  final DateTime? fechaNacimiento;
  final String sexo;
  final String cedula;

  // ============================================================
  // DATOS SOCIALES
  // ============================================================

  final String escolaridad;
  final String profesion;
  final String ocupacion;

  // ============================================================
  // SALUD
  // ============================================================

  final List<String> patologias;
  final List<String> factoresRiesgo;
  final int grupoDispensarial;

  // ============================================================
  // EMBARAZO
  // ============================================================

  final bool embarazada;
  final int? semanasGestacion;

  // ============================================================
  // VACUNACIÓN
  // ============================================================

  final String? estadoVacunacion;

  // ============================================================
  // JEFE DE FAMILIA
  // ============================================================

  final bool esJefeFamilia;

  final DateTime? fechaRegistro;

  Persona({
    required this.id,
    required this.comunidadId,
    required this.viviendaId,
    required this.familiaId,
    required this.primerNombre,
    this.segundoNombre = '',
    required this.primerApellido,
    this.segundoApellido = '',
    required this.fechaNacimiento,
    required this.sexo,
    required this.cedula,
    required this.escolaridad,
    required this.profesion,
    required this.ocupacion,
    required this.patologias,
    required this.factoresRiesgo,
    required this.grupoDispensarial,
    required this.embarazada,
    this.semanasGestacion,
    this.estadoVacunacion,
    required this.esJefeFamilia,
    this.fechaRegistro,
  });

  // ============================================================
  // NOMBRE COMPLETO
  // ============================================================

  String get nombreApellido {
    return [
      primerNombre,
      segundoNombre,
      primerApellido,
      segundoApellido,
    ]
        .where(
          (parte) => parte.trim().isNotEmpty,
        )
        .join(' ');
  }

  // ============================================================
  // APELLIDOS
  // ============================================================

  String get apellidos {
    return [
      primerApellido,
      segundoApellido,
    ]
        .where(
          (parte) => parte.trim().isNotEmpty,
        )
        .join(' ');
  }

  // ============================================================
  // FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'comunidadId': comunidadId,
      'viviendaId': viviendaId,
      'familiaId': familiaId,

      'primerNombre': primerNombre,
      'segundoNombre': segundoNombre,
      'primerApellido': primerApellido,
      'segundoApellido': segundoApellido,

      // Se conserva para compatibilidad
      // con el sistema anterior.
      'nombreApellido': nombreApellido,

      'fechaNacimiento': fechaNacimiento != null
          ? Timestamp.fromDate(fechaNacimiento!)
          : null,

      'sexo': sexo,
      'cedula': cedula,

      'escolaridad': escolaridad,
      'profesion': profesion,
      'ocupacion': ocupacion,

      'patologias': patologias,
      'factoresRiesgo': factoresRiesgo,
      'grupoDispensarial': grupoDispensarial,

      'embarazada': embarazada,
      'semanasGestacion': semanasGestacion,

      'estadoVacunacion': estadoVacunacion,

      'esJefeFamilia': esJefeFamilia,

      'fechaRegistro': fechaRegistro != null
          ? Timestamp.fromDate(fechaRegistro!)
          : FieldValue.serverTimestamp(),
    };
  }

  // ============================================================
  // DESDE FIRESTORE
  // ============================================================

  factory Persona.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final nombreAntiguo =
        map['nombreApellido']
            ?.toString()
            .trim() ??
        '';

    return Persona(
      id: id,
      comunidadId:
          map['comunidadId'] ?? '',
      viviendaId:
          map['viviendaId'] ?? '',
      familiaId:
          map['familiaId'] ?? '',

      // Registros nuevos
      primerNombre:
          map['primerNombre']?.toString() ??
              nombreAntiguo,

      segundoNombre:
          map['segundoNombre']
                  ?.toString() ??
              '',

      primerApellido:
          map['primerApellido']
                  ?.toString() ??
              '',

      segundoApellido:
          map['segundoApellido']
                  ?.toString() ??
              '',

      fechaNacimiento:
          map['fechaNacimiento'] is Timestamp
              ? (map['fechaNacimiento']
                      as Timestamp)
                  .toDate()
              : null,

      sexo:
          map['sexo'] ?? '',

      cedula:
          map['cedula'] ?? '',

      escolaridad:
          map['escolaridad'] ?? '',

      profesion:
          map['profesion'] ?? '',

      ocupacion:
          map['ocupacion'] ?? '',

      patologias:
          List<String>.from(
        map['patologias'] ?? [],
      ),

      factoresRiesgo:
          List<String>.from(
        map['factoresRiesgo'] ?? [],
      ),

      grupoDispensarial:
          map['grupoDispensarial'] ?? 0,

      embarazada:
          map['embarazada'] ?? false,

      semanasGestacion:
          map['semanasGestacion'],

      estadoVacunacion:
          map['estadoVacunacion'],

      esJefeFamilia:
          map['esJefeFamilia'] ?? false,

      fechaRegistro:
          map['fechaRegistro'] is Timestamp
              ? (map['fechaRegistro']
                      as Timestamp)
                  .toDate()
              : null,
    );
  }
}