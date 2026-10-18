import 'package:cloud_firestore/cloud_firestore.dart';

class Comunidad {
  final String id;
  final String nombre;
  final String estado;
  final String municipio;
  final String parroquia;
  final DateTime? fechaCreacion;

  Comunidad({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.municipio,
    required this.parroquia,
    this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'estado': estado,
      'municipio': municipio,
      'parroquia': parroquia,
      'fechaCreacion': fechaCreacion != null
          ? Timestamp.fromDate(fechaCreacion!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Comunidad.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Comunidad(
      id: id,
      nombre: map['nombre'] ?? '',
      estado: map['estado'] ?? '',
      municipio: map['municipio'] ?? '',
      parroquia: map['parroquia'] ?? '',
      fechaCreacion: map['fechaCreacion'] is Timestamp
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : null,
    );
  }
}