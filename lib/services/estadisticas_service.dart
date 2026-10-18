import 'package:cloud_firestore/cloud_firestore.dart';

class EstadisticasService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // OBTENER TODAS LAS PERSONAS
  // ============================================================

  Future<List<Map<String, dynamic>>> _obtenerPersonas() async {
    final snapshot =
        await _db.collection('personas').get();

    return snapshot.docs
        .map((doc) => doc.data())
        .toList();
  }

  // ============================================================
  // PORCENTAJE
  // ============================================================

  static double calcularPorcentaje(
    int cantidad,
    int total,
  ) {
    if (total == 0) {
      return 0;
    }

    return (cantidad / total) * 100;
  }

  // ============================================================
  // POBLACIÓN TOTAL
  // ============================================================

  Future<int> poblacionTotal() async {
    final personas =
        await _obtenerPersonas();

    return personas.length;
  }

  // ============================================================
  // CONVERTIR FECHA
  // ============================================================

  DateTime? _convertirFecha(dynamic valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }

    return null;
  }

  // ============================================================
  // CALCULAR EDAD
  // ============================================================

  int _calcularEdad(
    DateTime fechaNacimiento,
  ) {
    final hoy = DateTime.now();

    int edad =
        hoy.year - fechaNacimiento.year;

    if (hoy.month < fechaNacimiento.month ||
        (hoy.month ==
                fechaNacimiento.month &&
            hoy.day <
                fechaNacimiento.day)) {
      edad--;
    }

    return edad;
  }

  // ============================================================
  // DISTRIBUCIÓN POR EDADES
  // ============================================================

  Future<Map<String, int>>
      distribucionEdades() async {
    final personas =
        await _obtenerPersonas();

    int ninos = 0;
    int adolescentes = 0;
    int adultos = 0;
    int adultosMayores = 0;

    for (final persona in personas) {
      final fecha =
          _convertirFecha(
        persona['fechaNacimiento'],
      );

      if (fecha == null) {
        continue;
      }

      final edad =
          _calcularEdad(fecha);

      if (edad < 12) {
        ninos++;
      } else if (edad < 18) {
        adolescentes++;
      } else if (edad < 60) {
        adultos++;
      } else {
        adultosMayores++;
      }
    }

    return {
      'ninos': ninos,
      'adolescentes': adolescentes,
      'adultos': adultos,
      'adultosMayores':
          adultosMayores,
    };
  }

Future<Map<String, int>> distribucionSexo() async {
  final personas = await _obtenerPersonas();

  int masculino = 0;
  int femenino = 0;

  for (final persona in personas) {
    final sexo = persona['sexo']
        ?.toString()
        .trim()
        .toLowerCase();

    if (sexo == 'masculino' || sexo == 'm') {
      masculino++;
    } else if (sexo == 'femenino' || sexo == 'f') {
      femenino++;
    }
  }

  return {
    'masculino': masculino,
    'femenino': femenino,
  };
}

  // ============================================================
  // PATOLOGÍAS
  // ============================================================

  Future<int> cantidadPatologia(
    String patologia,
  ) async {
    final personas =
        await _obtenerPersonas();

    return personas.where((persona) {
      final patologias =
          List<String>.from(
        persona['patologias'] ?? [],
      );

      return patologias.contains(
        patologia,
      );
    }).length;
  }

  // ============================================================
  // FACTORES DE RIESGO
  // ============================================================

  Future<int> cantidadFactorRiesgo(
    String factor,
  ) async {
    final personas =
        await _obtenerPersonas();

    return personas.where((persona) {
      final factores =
          List<String>.from(
        persona['factoresRiesgo'] ?? [],
      );

      return factores.contains(
        factor,
      );
    }).length;
  }

  // ============================================================
  // GRUPO DISPENSARIAL
  // ============================================================

  Future<int>
      cantidadGrupoDispensarial(
    int grupo,
  ) async {
    final personas =
        await _obtenerPersonas();

    return personas.where((persona) {
      return persona[
              'grupoDispensarial'] ==
          grupo;
    }).length;
  }

  // ============================================================
  // VACUNACIÓN INFANTIL
  // ============================================================

  Future<Map<String, int>>
      estadisticasVacunacion() async {
    final personas =
        await _obtenerPersonas();

    int completa = 0;
    int incompleta = 0;
    int noVacunado = 0;
    int noVerificado = 0;

    for (final persona in personas) {
      final fecha =
          _convertirFecha(
        persona['fechaNacimiento'],
      );

      if (fecha == null) {
        continue;
      }

      final edad =
          _calcularEdad(fecha);

      // Solo menores de 12 años.
      if (edad >= 12) {
        continue;
      }

      switch (
          persona['estadoVacunacion']) {
        case 'completa':
          completa++;
          break;

        case 'incompleta':
          incompleta++;
          break;

        case 'no_vacunado':
          noVacunado++;
          break;

        default:
          noVerificado++;
      }
    }

    return {
      'completa': completa,
      'incompleta': incompleta,
      'no_vacunado': noVacunado,
      'no_verificado':
          noVerificado,
    };
  }

Future<int> totalNinos() async {
  final personas = await _obtenerPersonas();

  int total = 0;

  for (final persona in personas) {
    final fecha = _convertirFecha(
      persona['fechaNacimiento'],
    );

    if (fecha == null) {
      continue;
    }

    final edad = _calcularEdad(fecha);

    if (edad < 12) {
      total++;
    }
  }

  return total;
}


Future<int> totalMujeres() async {
  final personas = await _obtenerPersonas();

  int total = 0;

  for (final persona in personas) {
    final sexo = persona['sexo']
        ?.toString()
        .trim()
        .toLowerCase();

    if (sexo == 'femenino' ||
        sexo == 'f') {
      total++;
    }
  }

  return total;
}

  // ============================================================
  // EMBARAZO
  // ============================================================

 Future<Map<String, int>>
    estadisticasEmbarazo() async {
  final personas = await _obtenerPersonas();

  int embarazadas = 0;
  int embarazoOptimo = 0;
  int embarazoRiesgoEdad = 0;

  for (final persona in personas) {
    final embarazada = persona['embarazada'] == true;

if (!embarazada) {
  continue;
}

    final fechaNacimiento =
        _convertirFecha(
      persona['fechaNacimiento'],
    );

    if (fechaNacimiento == null) {
      continue;
    }

    final edad =
        _calcularEdad(fechaNacimiento);

    embarazadas++;

    // Clasificación estadística por edad materna.
    //
    // Menor de 20 años:
    // embarazo adolescente → riesgo por edad.
    //
    // 20 a 34 años:
    // rango de referencia para este indicador.
    //
    // 35 años o más:
    // riesgo asociado a edad materna avanzada.

    if (edad >= 20 && edad <= 34) {
      embarazoOptimo++;
    } else {
      embarazoRiesgoEdad++;
    }
  }

  return {
    'embarazadas': embarazadas,
    'optimo': embarazoOptimo,
    'riesgo': embarazoRiesgoEdad,
  };
}

    // ============================================================
  // ESTADÍSTICAS DE PATOLOGÍAS
  // ============================================================

  Future<Map<String, int>>
      estadisticasPatologias() async {
    final personas =
        await _obtenerPersonas();

    final resultado = {
      'hipertension': 0,
      'diabetes': 0,
      'asma': 0,
      'epilepsia': 0,
      'cardiopatias': 0,
      'discapacidad': 0,
      'otras': 0,
    };

    for (final persona in personas) {
      final patologias =
          List<String>.from(
        persona['patologias'] ?? [],
      );

      for (final patologia in resultado.keys) {
        if (patologias.contains(patologia)) {
          resultado[patologia] =
              resultado[patologia]! + 1;
        }
      }
    }

    return resultado;
  }

  // ============================================================
  // ESTADÍSTICAS DE FACTORES DE RIESGO
  // ============================================================

  Future<Map<String, int>>
      estadisticasFactoresRiesgo() async {
    final personas =
        await _obtenerPersonas();

    final resultado = {
      'tabaquismo': 0,
      'alcoholismo': 0,
      'drogas': 0,
      'sedentarismo': 0,
      'obesidad': 0,
      'otros': 0,
    };

    for (final persona in personas) {
      final factores =
          List<String>.from(
        persona['factoresRiesgo'] ?? [],
      );

      for (final factor in resultado.keys) {
        if (factores.contains(factor)) {
          resultado[factor] =
              resultado[factor]! + 1;
        }
      }
    }

    return resultado;
  }

  // ============================================================
  // ESTADÍSTICAS DE GRUPOS DISPENSARIALES
  // ============================================================

  Future<Map<String, int>>
      estadisticasGruposDispensariales() async {
    final personas =
        await _obtenerPersonas();

    final resultado = {
      'grupo1': 0,
      'grupo2': 0,
      'grupo3': 0,
      'grupo4': 0,
    };

    for (final persona in personas) {
      final grupo =
          persona['grupoDispensarial'];

      switch (grupo) {
        case 1:
          resultado['grupo1'] =
              resultado['grupo1']! + 1;
          break;

        case 2:
          resultado['grupo2'] =
              resultado['grupo2']! + 1;
          break;

        case 3:
          resultado['grupo3'] =
              resultado['grupo3']! + 1;
          break;

        case 4:
          resultado['grupo4'] =
              resultado['grupo4']! + 1;
          break;
      }
    }

    return resultado;
  }

  // ============================================================
  // ESTADÍSTICAS DE VIVIENDAS
  // ============================================================

  Future<int> totalViviendas() async {
    final snapshot =
        await _db.collection('viviendas').get();

    return snapshot.docs.length;
  }

  // ============================================================
  // ESTADÍSTICAS DE FAMILIAS
  // ============================================================

  Future<int> totalFamilias() async {
    final snapshot =
        await _db.collection('familias').get();

    return snapshot.docs.length;
  }

  // ============================================================
  // VIVIENDAS SEGÚN CANTIDAD DE FAMILIAS
  // ============================================================

  Future<Map<String, int>>
      distribucionFamiliasPorVivienda() async {
    final viviendasSnapshot =
        await _db.collection('viviendas').get();

    final familiasSnapshot =
        await _db.collection('familias').get();

    final familiasPorVivienda =
        <String, int>{};

    for (final familia
        in familiasSnapshot.docs) {
      final viviendaId =
          familia.data()['viviendaId'];

      if (viviendaId == null) {
        continue;
      }

      familiasPorVivienda[viviendaId] =
          (familiasPorVivienda[viviendaId] ??
                  0) +
              1;
    }

    int unaFamilia = 0;
    int variasFamilias = 0;
    int sinFamilia = 0;

    for (final vivienda
        in viviendasSnapshot.docs) {
      final cantidad =
          familiasPorVivienda[
                  vivienda.id] ??
              0;

      if (cantidad == 0) {
        sinFamilia++;
      } else if (cantidad == 1) {
        unaFamilia++;
      } else {
        variasFamilias++;
      }
    }

    return {
      'sinFamilia': sinFamilia,
      'unaFamilia': unaFamilia,
      'variasFamilias': variasFamilias,
    };
  }

// ============================================================
// DISTRIBUCIÓN POR ESCOLARIDAD
// ============================================================

Future<Map<String, int>> distribucionEscolaridad() async {
  final personas = await _obtenerPersonas();

  final resultado = {
    'ninguna': 0,
    'primaria': 0,
    'Bachiller': 0,
    'tecnico': 0,
    'universitaria': 0,
    'otra': 0,
  };

  for (final persona in personas) {
    final escolaridad = persona['escolaridad']
        ?.toString()
        .trim()
        .toLowerCase();

    if (resultado.containsKey(escolaridad)) {
      resultado[escolaridad!] =
          resultado[escolaridad]! + 1;
    }
  }

  return resultado;
}

// ============================================================
// DISTRIBUCIÓN POR EDAD Y SEXO
// ============================================================

Future<List<Map<String, dynamic>>>
    distribucionEdadSexo() async {
  final personas = await _obtenerPersonas();

  final grupos = [
    {
      'clave': 'menor1',
      'grupo': '< 1 año',
      'min': 0,
      'max': 0,
    },
    {
      'clave': '1_4',
      'grupo': '1-4 años',
      'min': 1,
      'max': 4,
    },
    {
      'clave': '5_9',
      'grupo': '5-9 años',
      'min': 5,
      'max': 9,
    },
    {
      'clave': '10_14',
      'grupo': '10-14 años',
      'min': 10,
      'max': 14,
    },
    {
      'clave': '15_19',
      'grupo': '15-19 años',
      'min': 15,
      'max': 19,
    },
    {
      'clave': '20_24',
      'grupo': '20-24 años',
      'min': 20,
      'max': 24,
    },
    {
      'clave': '25_29',
      'grupo': '25-29 años',
      'min': 25,
      'max': 29,
    },
    {
      'clave': '30_34',
      'grupo': '30-34 años',
      'min': 30,
      'max': 34,
    },
    {
      'clave': '35_39',
      'grupo': '35-39 años',
      'min': 35,
      'max': 39,
    },
    {
      'clave': '40_44',
      'grupo': '40-44 años',
      'min': 40,
      'max': 44,
    },
    {
      'clave': '45_49',
      'grupo': '45-49 años',
      'min': 45,
      'max': 49,
    },
    {
      'clave': '50_54',
      'grupo': '50-54 años',
      'min': 50,
      'max': 54,
    },
    {
      'clave': '55_59',
      'grupo': '55-59 años',
      'min': 55,
      'max': 59,
    },
    {
      'clave': '60_64',
      'grupo': '60-64 años',
      'min': 60,
      'max': 64,
    },
    {
      'clave': '65_69',
      'grupo': '65-69 años',
      'min': 65,
      'max': 69,
    },
    {
      'clave': '70_74',
      'grupo': '70-74 años',
      'min': 70,
      'max': 74,
    },
    {
      'clave': '75_79',
      'grupo': '75-79 años',
      'min': 75,
      'max': 79,
    },
    {
      'clave': '80_mas',
      'grupo': '> 80 años',
      'min': 80,
      'max': 200,
    },
  ];

  final resultado = <Map<String, dynamic>>[];

  for (final grupo in grupos) {
    int masculino = 0;
    int femenino = 0;

    for (final persona in personas) {
      final fecha =
          _convertirFecha(
        persona['fechaNacimiento'],
      );

      if (fecha == null) {
        continue;
      }

      final edad = _calcularEdad(fecha);

      final min = grupo['min'] as int;
      final max = grupo['max'] as int;

      if (edad < min || edad > max) {
        continue;
      }

      final sexo = persona['sexo']
          ?.toString()
          .trim()
          .toLowerCase();

      if (sexo == 'masculino' || sexo == 'm') {
        masculino++;
      } else if (
          sexo == 'femenino' || sexo == 'f') {
        femenino++;
      }
    }

    final total = masculino + femenino;

    resultado.add({
      'clave': grupo['clave'],
      'grupo': grupo['grupo'],
      'masculino': masculino,
      'femenino': femenino,
      'total': total,
    });
  }

  return resultado;
}
// ============================================================
// TOTAL DE PERSONAS CON EDAD Y SEXO VÁLIDOS
// ============================================================

Future<int> totalPersonasEdadSexo() async {
  final personas = await _obtenerPersonas();

  int total = 0;

  for (final persona in personas) {
    final fecha =
        _convertirFecha(
      persona['fechaNacimiento'],
    );

    if (fecha == null) {
      continue;
    }

    final sexo = persona['sexo']
        ?.toString()
        .trim()
        .toLowerCase();

    if (sexo == 'masculino' ||
        sexo == 'm' ||
        sexo == 'femenino' ||
        sexo == 'f') {
      total++;
    }
  }

  return total;
}


}