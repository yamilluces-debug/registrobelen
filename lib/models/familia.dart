import 'package:cloud_firestore/cloud_firestore.dart';

class Familia {
  final String id;
  final String comunidadId;
  final String viviendaId;
  final String codigo;
  final String jefeFamiliaId;
  final DateTime? fechaRegistro;

  Familia({
    required this.id,
    required this.comunidadId,
    required this.viviendaId,
    required this.codigo,
    required this.jefeFamiliaId,
    this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'comunidadId': comunidadId,
      'viviendaId': viviendaId,
      'codigo': codigo,
      'jefeFamiliaId': jefeFamiliaId,
      'fechaRegistro': fechaRegistro != null
          ? Timestamp.fromDate(fechaRegistro!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Familia.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Familia(
      id: id,
      comunidadId: map['comunidadId'] ?? '',
      viviendaId: map['viviendaId'] ?? '',
      codigo: map['codigo'] ?? '',
      jefeFamiliaId: map['jefeFamiliaId'] ?? '',
      fechaRegistro: map['fechaRegistro'] is Timestamp
          ? (map['fechaRegistro'] as Timestamp).toDate()
          : null,
    );
  }
}