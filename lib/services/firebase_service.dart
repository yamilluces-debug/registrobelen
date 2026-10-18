import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vivienda.dart';
import '../models/familia.dart';
import '../models/persona.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // VIVIENDAS
  // ============================================================

  Future<String> crearVivienda(Vivienda vivienda) async {
    final documento = await _db.collection('viviendas').add(
          vivienda.toMap(),
        );

    return documento.id;
  }

  Future<List<Vivienda>> obtenerViviendas() async {
    final snapshot = await _db
        .collection('viviendas')
        .orderBy('codigo')
        .get();

    return snapshot.docs.map((doc) {
      return Vivienda.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  Future<Vivienda?> obtenerViviendaPorId(
    String viviendaId,
  ) async {
    final doc = await _db
        .collection('viviendas')
        .doc(viviendaId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Vivienda.fromMap(
      doc.id,
      doc.data()!,
    );
  }

  Future<void> actualizarVivienda(
    String viviendaId,
    Vivienda vivienda,
  ) async {
    await _db
        .collection('viviendas')
        .doc(viviendaId)
        .update(
          vivienda.toMap(),
        );
  }

  /// Elimina una vivienda y todos sus datos asociados:
  /// - Familias
  /// - Personas pertenecientes a esas familias
  Future<void> eliminarVivienda(
    String viviendaId,
  ) async {
    final familiasSnapshot = await _db
        .collection('familias')
        .where(
          'viviendaId',
          isEqualTo: viviendaId,
        )
        .get();

    for (final familiaDoc
        in familiasSnapshot.docs) {
      final personasSnapshot = await _db
          .collection('personas')
          .where(
            'familiaId',
            isEqualTo: familiaDoc.id,
          )
          .get();

      for (final personaDoc
          in personasSnapshot.docs) {
        await personaDoc.reference.delete();
      }

      await familiaDoc.reference.delete();
    }

    await _db
        .collection('viviendas')
        .doc(viviendaId)
        .delete();
  }

  Future<String> generarCodigoVivienda() async {
    final snapshot = await _db
        .collection('viviendas')
        .orderBy(
          'codigo',
          descending: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'CASA-001';
    }

    final ultimoCodigo =
        snapshot.docs.first.data()['codigo'] as String;

    final numeroTexto =
        ultimoCodigo.replaceFirst(
      'CASA-',
      '',
    );

    final ultimoNumero =
        int.tryParse(numeroTexto) ?? 0;

    final siguienteNumero =
        ultimoNumero + 1;

    return 'CASA-${siguienteNumero.toString().padLeft(3, '0')}';
  }

  // ============================================================
  // FAMILIAS
  // ============================================================

  Future<String> generarCodigoFamilia(
    String viviendaId,
  ) async {
    final vivienda =
        await obtenerViviendaPorId(viviendaId);

    if (vivienda == null) {
      throw Exception(
        'La vivienda no existe',
      );
    }

    final snapshot = await _db
        .collection('familias')
        .where(
          'viviendaId',
          isEqualTo: viviendaId,
        )
        .get();

    final numeroFamilia =
        snapshot.docs.length + 1;

    return '${vivienda.codigo}-$numeroFamilia';
  }

  Future<String> crearFamilia(
    Familia familia,
  ) async {
    final documento = await _db
        .collection('familias')
        .add(
          familia.toMap(),
        );

    return documento.id;
  }

  Future<List<Familia>> obtenerFamiliasDeVivienda(
    String viviendaId,
  ) async {
    final snapshot = await _db
        .collection('familias')
        .where(
          'viviendaId',
          isEqualTo: viviendaId,
        )
        .get();

    return snapshot.docs.map((doc) {
      return Familia.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  Future<List<Familia>> obtenerFamilias() async {
    final snapshot = await _db
        .collection('familias')
        .orderBy('codigo')
        .get();

    return snapshot.docs.map((doc) {
      return Familia.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  Future<void> actualizarFamilia(
    String familiaId,
    Familia familia,
  ) async {
    await _db
        .collection('familias')
        .doc(familiaId)
        .update(
          familia.toMap(),
        );
  }

  /// Elimina una familia y todas las personas
  /// pertenecientes a ella.
  Future<void> eliminarFamilia(
    String familiaId,
  ) async {
    final personasSnapshot = await _db
        .collection('personas')
        .where(
          'familiaId',
          isEqualTo: familiaId,
        )
        .get();

    for (final personaDoc
        in personasSnapshot.docs) {
      await personaDoc.reference.delete();
    }

    await _db
        .collection('familias')
        .doc(familiaId)
        .delete();
  }

  /// Asigna una persona como jefe de familia.
  Future<void> asignarJefeFamilia(
  String familiaId,
  String personaId,
) async {
  final familiaRef =
      _db.collection('familias').doc(familiaId);

  final familiaDoc = await familiaRef.get();

  if (!familiaDoc.exists ||
      familiaDoc.data() == null) {
    throw Exception(
      'La familia no existe.',
    );
  }

  final datosFamilia = familiaDoc.data()!;

  final jefeAnteriorId =
      datosFamilia['jefeFamiliaId']
          ?.toString() ??
      '';

  // ============================================================
  // DESMARCAR AL JEFE ANTERIOR
  // ============================================================

  if (jefeAnteriorId.isNotEmpty &&
      jefeAnteriorId != personaId) {
    await _db
        .collection('personas')
        .doc(jefeAnteriorId)
        .update({
      'esJefeFamilia': false,
    });
  }

  // ============================================================
  // ASIGNAR NUEVO JEFE A LA FAMILIA
  // ============================================================

  await familiaRef.update({
    'jefeFamiliaId': personaId,
  });

  // ============================================================
  // MARCAR NUEVO JEFE
  // ============================================================

  await _db
      .collection('personas')
      .doc(personaId)
      .update({
    'esJefeFamilia': true,
  });
}
  // ============================================================
  // PERSONAS
  // ============================================================

  Future<String> crearPersona(
    Persona persona,
  ) async {
    final documento = await _db
        .collection('personas')
        .add(
          persona.toMap(),
        );

    return documento.id;
  }

  Future<List<Persona>> obtenerPersonas() async {
    final snapshot = await _db
        .collection('personas')
        .orderBy('nombreApellido')
        .get();

    return snapshot.docs.map((doc) {
      return Persona.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  Future<List<Persona>> obtenerPersonasDeFamilia(
    String familiaId,
  ) async {
    final snapshot = await _db
        .collection('personas')
        .where(
          'familiaId',
          isEqualTo: familiaId,
        )
        .get();

    return snapshot.docs.map((doc) {
      return Persona.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  Future<Persona?> obtenerPersonaPorId(
    String personaId,
  ) async {
    final doc = await _db
        .collection('personas')
        .doc(personaId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Persona.fromMap(
      doc.id,
      doc.data()!,
    );
  }

  Future<void> actualizarPersona(
    String personaId,
    Persona persona,
  ) async {
    await _db
        .collection('personas')
        .doc(personaId)
        .update(
          persona.toMap(),
        );
  }

  /// Actualiza únicamente la familia a la que pertenece
  /// una persona y si es jefe de familia.
  ///
  /// Se utiliza cuando primero registramos al jefe y
  /// posteriormente creamos la familia.
  Future<void> actualizarFamiliaDePersona(
    String personaId,
    String familiaId, {
    bool esJefeFamilia = false,
  }) async {
    await _db
        .collection('personas')
        .doc(personaId)
        .update({
      'familiaId': familiaId,
      'esJefeFamilia': esJefeFamilia,
    });
  }

  Future<void> eliminarPersona(
    String personaId,
  ) async {
    await _db
        .collection('personas')
        .doc(personaId)
        .delete();
  }
}