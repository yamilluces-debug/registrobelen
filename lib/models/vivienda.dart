import 'package:cloud_firestore/cloud_firestore.dart';

class Vivienda {
  final String id;
  final String comunidadId;
  final String codigo;
  final String direccion;

  // Servicios básicos
  final bool tieneLuz;
  final bool tieneAgua;
  final String gasLena;
  final bool tieneBanoSanitario;

  // Condiciones de la vivienda
  final String material;
  final String techo;
  final String piso;

  // Higiene del hogar
  final String higiene;

  // Animales
  final Map<String, int> animales;

  final DateTime? fechaRegistro;

  Vivienda({
    required this.id,
    required this.comunidadId,
    required this.codigo,
    required this.direccion,
    required this.tieneLuz,
    required this.tieneAgua,
    required this.gasLena,
    required this.tieneBanoSanitario,
    required this.material,
    required this.techo,
    required this.piso,
    required this.higiene,
    required this.animales,
    this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'comunidadId': comunidadId,
      'codigo': codigo,
      'direccion': direccion,
      'tieneLuz': tieneLuz,
      'tieneAgua': tieneAgua,
      'gasLena': gasLena,
      'tieneBanoSanitario': tieneBanoSanitario,
      'material': material,
      'techo': techo,
      'piso': piso,
      'higiene': higiene,
      'animales': animales,
      'fechaRegistro': fechaRegistro != null
          ? Timestamp.fromDate(fechaRegistro!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Vivienda.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Vivienda(
      id: id,
      comunidadId: map['comunidadId'] ?? '',
      codigo: map['codigo'] ?? '',
      direccion: map['direccion'] ?? '',
      tieneLuz: map['tieneLuz'] ?? false,
      tieneAgua: map['tieneAgua'] ?? false,
      gasLena: map['gasLena'] ?? '',
      tieneBanoSanitario: map['tieneBanoSanitario'] ?? false,
      material: map['material'] ?? '',
      techo: map['techo'] ?? '',
      piso: map['piso'] ?? '',
      higiene: map['higiene'] ?? '',
      animales: Map<String, int>.from(
        map['animales'] ?? {},
      ),
      fechaRegistro: map['fechaRegistro'] is Timestamp
          ? (map['fechaRegistro'] as Timestamp).toDate()
          : null,
    );
  }
}