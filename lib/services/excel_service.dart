import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/familia.dart';
import '../models/persona.dart';
import '../models/vivienda.dart';
import 'firebase_service.dart';
import 'estadisticas_service.dart';

class ExcelService {
  final FirebaseService _firebaseService =
      FirebaseService();

  final EstadisticasService _estadisticasService =
      EstadisticasService();

  // ============================================================
  // EXPORTAR CENSO GENERAL
  // ============================================================

  Future<Uint8List> exportarCensoGeneral() async {
    final viviendas =
        await _firebaseService.obtenerViviendas();

    final familias =
        await _firebaseService.obtenerFamilias();

    final personas =
        await _firebaseService.obtenerPersonas();

    // ==========================================================
    // ESTADÍSTICAS
    // ==========================================================

    final resultados =
        await Future.wait([
      _estadisticasService.poblacionTotal(),
      _estadisticasService.distribucionSexo(),
      _estadisticasService.distribucionEdades(),
      _estadisticasService.distribucionEscolaridad(),
      _estadisticasService.distribucionEdadSexo(),
      _estadisticasService.totalPersonasEdadSexo(),
      _estadisticasService.estadisticasVacunacion(),
      _estadisticasService.estadisticasEmbarazo(),
      _estadisticasService.estadisticasPatologias(),
      _estadisticasService.estadisticasFactoresRiesgo(),
      _estadisticasService.estadisticasGruposDispensariales(),
      _estadisticasService.totalViviendas(),
      _estadisticasService.totalFamilias(),
      _estadisticasService
          .distribucionFamiliasPorVivienda(),
    ]);

    return generarExcelCenso(
      viviendas: viviendas,
      familias: familias,
      personas: personas,
      poblacion: resultados[0] as int,
      sexo: resultados[1] as Map<String, int>,
      edades: resultados[2] as Map<String, int>,
      escolaridad:
          resultados[3] as Map<String, int>,
      edadSexo:
          (resultados[4] as List)
              .cast<Map<String, dynamic>>(),
      totalEdadSexo:
          resultados[5] as int,
      vacunacion:
          resultados[6] as Map<String, int>,
      embarazo:
          resultados[7] as Map<String, int>,
      patologias:
          resultados[8] as Map<String, int>,
      factoresRiesgo:
          resultados[9] as Map<String, int>,
      gruposDispensariales:
          resultados[10] as Map<String, int>,
      totalViviendas:
          resultados[11] as int,
      totalFamilias:
          resultados[12] as int,
      distribucionFamilias:
          resultados[13] as Map<String, int>,
    );
  }

  // ============================================================
  // EXPORTAR FAMILIA
  // ============================================================

  Future<Uint8List> exportarFamilia({
    required Familia familia,
    required Vivienda vivienda,
  }) async {
    final personas =
        await _firebaseService.obtenerPersonasDeFamilia(
      familia.id,
    );

    return generarExcelFamilia(
      familia: familia,
      vivienda: vivienda,
      personas: personas,
    );
  }

  // ============================================================
  // GENERAR EXCEL DE UNA FAMILIA
  // ============================================================

  Future<Uint8List> generarExcelFamilia({
    required Familia familia,
    required Vivienda vivienda,
    required List<Persona> personas,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Familia'];

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('O1'),
    );

    sheet
        .cell(CellIndex.indexByString('A1'))
        .value = TextCellValue(
      'FICHA FAMILIAR - ${familia.codigo}',
    );

    sheet
        .cell(CellIndex.indexByString('A1'))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign:
          HorizontalAlign.Center,
    );

    int fila = 3;

    fila = _crearBloqueVivienda(
      sheet,
      vivienda,
      fila,
    );

    fila += 2;

    fila = _crearBloqueFamilia(
      sheet,
      familia,
      personas,
      fila,
    );

    _ajustarColumnas(sheet);

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception(
        'No se pudo generar el archivo Excel.',
      );
    }

    return Uint8List.fromList(bytes);
  }

  // ============================================================
  // GENERAR EXCEL DEL CENSO GENERAL
  // ============================================================

  Future<Uint8List> generarExcelCenso({
    required List<Vivienda> viviendas,
    required List<Familia> familias,
    required List<Persona> personas,

    required int poblacion,
    required Map<String, int> sexo,
    required Map<String, int> edades,
    required Map<String, int> escolaridad,
    required List<Map<String, dynamic>> edadSexo,
    required int totalEdadSexo,
    required Map<String, int> vacunacion,
    required Map<String, int> embarazo,
    required Map<String, int> patologias,
    required Map<String, int> factoresRiesgo,
    required Map<String, int> gruposDispensariales,
    required int totalViviendas,
    required int totalFamilias,
    required Map<String, int>
        distribucionFamilias,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Censo'];

    // ==========================================================
    // TÍTULO
    // ==========================================================

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('O1'),
    );

    sheet
        .cell(
          CellIndex.indexByString('A1'),
        )
        .value = TextCellValue(
      'REGISTRO DEL CENSO - COMUNIDAD BELÉN',
    );

    sheet
        .cell(
          CellIndex.indexByString('A1'),
        )
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign:
          HorizontalAlign.Center,
    );

    int fila = 3;

    // ==========================================================
    // VIVIENDAS Y FAMILIAS
    // ==========================================================

    for (final vivienda in viviendas) {
      final familiasVivienda = familias
          .where(
            (familia) =>
                familia.viviendaId ==
                vivienda.id,
          )
          .toList();

      fila = _crearBloqueVivienda(
        sheet,
        vivienda,
        fila,
      );

      fila++;

      if (familiasVivienda.isEmpty) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: fila,
              ),
            )
            .value = TextCellValue(
          'Sin familias registradas',
        );

        fila += 2;
        continue;
      }

      for (final familia
          in familiasVivienda) {
        final integrantes = personas
            .where(
              (persona) =>
                  persona.familiaId ==
                  familia.id,
            )
            .toList();

        fila = _crearBloqueFamilia(
          sheet,
          familia,
          integrantes,
          fila,
        );

        fila += 2;
      }
    }

    // ==========================================================
    // ESTADÍSTICAS
    // ==========================================================

    fila += 2;

    fila = _crearBloqueEstadisticas(
      sheet,
      fila,
      poblacion,
      sexo,
      edades,
      escolaridad,
      edadSexo,
      totalEdadSexo,
      vacunacion,
      embarazo,
      patologias,
      factoresRiesgo,
      gruposDispensariales,
      totalViviendas,
      totalFamilias,
      distribucionFamilias,
    );

    _ajustarColumnas(sheet);

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception(
        'No se pudo generar el archivo Excel.',
      );
    }

    return Uint8List.fromList(bytes);
  }

  // ============================================================
  // BLOQUE GENERAL DE ESTADÍSTICAS
  // ============================================================

  int _crearBloqueEstadisticas(
    Sheet sheet,
    int fila,
    int poblacion,
    Map<String, int> sexo,
    Map<String, int> edades,
    Map<String, int> escolaridad,
    List<Map<String, dynamic>> edadSexo,
    int totalEdadSexo,
    Map<String, int> vacunacion,
    Map<String, int> embarazo,
    Map<String, int> patologias,
    Map<String, int> factoresRiesgo,
    Map<String, int> gruposDispensariales,
    int totalViviendas,
    int totalFamilias,
    Map<String, int> distribucionFamilias,
  ) {
    // ==========================================================
    // TÍTULO
    // ==========================================================

    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: fila,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 14,
        rowIndex: fila,
      ),
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      'ESTADÍSTICAS GENERALES',
    );

    _estiloTituloFila(sheet, fila);

    fila += 2;

    // ==========================================================
    // RESUMEN COMUNITARIO
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'RESUMEN COMUNITARIO',
    );

    final resumen = [
      ['Población total', poblacion],
      ['Viviendas censadas', totalViviendas],
      ['Familias registradas', totalFamilias],
      [
        'Viviendas con una familia',
        distribucionFamilias['unaFamilia'] ?? 0,
      ],
      [
        'Viviendas con varias familias',
        distribucionFamilias['variasFamilias'] ?? 0,
      ],
      [
        'Viviendas sin familia',
        distribucionFamilias['sinFamilia'] ?? 0,
      ],
    ];

    for (final dato in resumen) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: fila,
            ),
          )
          .value = TextCellValue(
        dato[0].toString(),
      );

      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: fila,
            ),
          )
          .value = IntCellValue(
        dato[1] as int,
      );

      fila++;
    }

    fila += 2;

    // ==========================================================
    // SEXO
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'DISTRIBUCIÓN POR SEXO',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Sexo', 'Cantidad', '%'],
    );

    final masculino =
        sexo['masculino'] ?? 0;

    final femenino =
        sexo['femenino'] ?? 0;

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Masculino',
      masculino,
      poblacion,
    );

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Femenino',
      femenino,
      poblacion,
    );

    fila += 2;

    // ==========================================================
    // EDAD
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'DISTRIBUCIÓN POR EDAD',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Grupo etario', 'Cantidad', '%'],
    );

    final gruposEdad = {
      'ninos': 'Niños',
      'adolescentes': 'Adolescentes',
      'adultos': 'Adultos',
      'adultosMayores': 'Adultos mayores',
    };

    for (final entrada
        in gruposEdad.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        edades[entrada.key] ?? 0,
        poblacion,
      );
    }

    fila += 2;

    // ==========================================================
    // EDAD Y SEXO
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'DISTRIBUCIÓN DE LA POBLACIÓN POR EDAD Y SEXO',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      [
        'Grupo etario',
        'Masculino',
        '%',
        'Femenino',
        '%',
        'Total',
        '%',
      ],
    );

    int totalMasculino = 0;
    int totalFemenino = 0;

    for (final grupo in edadSexo) {
      final masculinoGrupo =
          grupo['masculino'] as int;

      final femeninoGrupo =
          grupo['femenino'] as int;

      final totalGrupo =
          grupo['total'] as int;

      totalMasculino += masculinoGrupo;
      totalFemenino += femeninoGrupo;

      final datos = [
        grupo['grupo'].toString(),
        masculinoGrupo.toString(),
        '${EstadisticasService.calcularPorcentaje(
          masculinoGrupo,
          totalEdadSexo,
        ).toStringAsFixed(2)}%',
        femeninoGrupo.toString(),
        '${EstadisticasService.calcularPorcentaje(
          femeninoGrupo,
          totalEdadSexo,
        ).toStringAsFixed(2)}%',
        totalGrupo.toString(),
        '${EstadisticasService.calcularPorcentaje(
          totalGrupo,
          totalEdadSexo,
        ).toStringAsFixed(2)}%',
      ];

      for (int i = 0;
          i < datos.length;
          i++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: fila,
              ),
            )
            .value = TextCellValue(
          datos[i],
        );
      }

      fila++;
    }

    final totalEdadSexoFila = [
      'TOTAL',
      totalMasculino.toString(),
      '${EstadisticasService.calcularPorcentaje(
        totalMasculino,
        totalEdadSexo,
      ).toStringAsFixed(2)}%',
      totalFemenino.toString(),
      '${EstadisticasService.calcularPorcentaje(
        totalFemenino,
        totalEdadSexo,
      ).toStringAsFixed(2)}%',
      totalEdadSexo.toString(),
      '100.00%',
    ];

    for (int i = 0;
        i < totalEdadSexoFila.length;
        i++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: fila,
            ),
          )
          .value = TextCellValue(
        totalEdadSexoFila[i],
      );
    }

    _estiloEncabezados(
      sheet,
      fila,
      totalEdadSexoFila.length,
    );

    fila += 2;

    // ==========================================================
    // ESCOLARIDAD
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'DISTRIBUCIÓN POR ESCOLARIDAD',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Escolaridad', 'Cantidad', '%'],
    );

    final escolaridades = {
      'ninguna': 'Ninguna',
      'primaria': 'Primaria',
      'Bachiller': 'Bachiller',
      'tecnico': 'Técnico',
      'universitaria': 'Universitaria',
      'otra': 'Otra',
    };

    for (final entrada
        in escolaridades.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        escolaridad[entrada.key] ?? 0,
        poblacion,
      );
    }

    fila += 2;

    // ==========================================================
    // VACUNACIÓN
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'VACUNACIÓN INFANTIL',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Estado', 'Cantidad', '%'],
    );

    final estadosVacunacion = {
      'completa': 'Esquema completo',
      'incompleta': 'Esquema incompleto',
      'no_vacunado': 'No vacunado',
      'no_verificado': 'No verificado',
    };

    final totalNinos =
        vacunacion.values.fold<int>(
      0,
      (suma, valor) => suma + valor,
    );

    for (final entrada
        in estadosVacunacion.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        vacunacion[entrada.key] ?? 0,
        totalNinos,
      );
    }

    fila += 2;

    // ==========================================================
    // EMBARAZO
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'EMBARAZO',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Indicador', 'Cantidad', '%'],
    );

    final embarazadas =
        embarazo['embarazadas'] ?? 0;

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Mujeres',
      sexo['femenino'] ?? 0,
      poblacion,
    );

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Embarazadas',
      embarazadas,
      sexo['femenino'] ?? 0,
    );

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Óptimo por edad',
      embarazo['optimo'] ?? 0,
      embarazadas,
    );

    fila = _crearFilaPorcentaje(
      sheet,
      fila,
      'Riesgo por edad',
      embarazo['riesgo'] ?? 0,
      embarazadas,
    );

    fila += 2;

    // ==========================================================
    // PATOLOGÍAS
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'PATOLOGÍAS',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Patología', 'Cantidad', '%'],
    );

    final nombresPatologias = {
      'hipertension': 'Hipertensión',
      'diabetes': 'Diabetes',
      'asma': 'Asma',
      'epilepsia': 'Epilepsia',
      'cardiopatias': 'Cardiopatías',
      'discapacidad': 'Discapacidad',
      'otras': 'Otras',
    };

    for (final entrada
        in nombresPatologias.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        patologias[entrada.key] ?? 0,
        poblacion,
      );
    }

    fila += 2;

    // ==========================================================
    // FACTORES DE RIESGO
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'FACTORES DE RIESGO',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Factor', 'Cantidad', '%'],
    );

    final nombresFactores = {
      'tabaquismo': 'Tabaquismo',
      'alcoholismo': 'Alcoholismo',
      'drogas': 'Drogas',
      'sedentarismo': 'Sedentarismo',
      'obesidad': 'Obesidad',
      'otros': 'Otros',
    };

    for (final entrada
        in nombresFactores.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        factoresRiesgo[entrada.key] ?? 0,
        poblacion,
      );
    }

    fila += 2;

    // ==========================================================
    // GRUPOS DISPENSARIALES
    // ==========================================================

    fila = _crearTituloEstadistica(
      sheet,
      fila,
      'GRUPOS DISPENSARIALES',
    );

    fila = _crearEncabezados(
      sheet,
      fila,
      ['Grupo', 'Cantidad', '%'],
    );

    final grupos = {
      'grupo1': 'Grupo I',
      'grupo2': 'Grupo II',
      'grupo3': 'Grupo III',
      'grupo4': 'Grupo IV',
    };

    for (final entrada
        in grupos.entries) {
      fila = _crearFilaPorcentaje(
        sheet,
        fila,
        entrada.value,
        gruposDispensariales[
                entrada.key] ??
            0,
        poblacion,
      );
    }

    return fila + 1;
  }

  // ============================================================
  // TÍTULO DE ESTADÍSTICA
  // ============================================================

  int _crearTituloEstadistica(
    Sheet sheet,
    int fila,
    String titulo,
  ) {
    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: fila,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 6,
        rowIndex: fila,
      ),
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      titulo,
    );

    _estiloTituloFila(sheet, fila);

    return fila + 1;
  }

  // ============================================================
  // ENCABEZADOS
  // ============================================================

  int _crearEncabezados(
    Sheet sheet,
    int fila,
    List<String> encabezados,
  ) {
    for (int i = 0;
        i < encabezados.length;
        i++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: fila,
            ),
          )
          .value = TextCellValue(
        encabezados[i],
      );
    }

    _estiloEncabezados(
      sheet,
      fila,
      encabezados.length,
    );

    return fila + 1;
  }

  // ============================================================
  // FILA CON PORCENTAJE
  // ============================================================

  int _crearFilaPorcentaje(
    Sheet sheet,
    int fila,
    String titulo,
    int cantidad,
    int total,
  ) {
    final porcentaje =
        EstadisticasService.calcularPorcentaje(
      cantidad,
      total,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      titulo,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 1,
            rowIndex: fila,
          ),
        )
        .value = IntCellValue(
      cantidad,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 2,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      '${porcentaje.toStringAsFixed(2)}%',
    );

    return fila + 1;
  }

  // ============================================================
  // BLOQUE VIVIENDA
  // ============================================================

  int _crearBloqueVivienda(
    Sheet sheet,
    Vivienda vivienda,
    int fila,
  ) {
    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: fila,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 14,
        rowIndex: fila,
      ),
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      'VIVIENDA ${vivienda.codigo}',
    );

    _estiloTituloFila(sheet, fila);

    fila++;

    _escribirDato(
      sheet,
      fila,
      0,
      'Dirección',
      vivienda.direccion,
    );

    _escribirDato(
      sheet,
      fila,
      4,
      'Luz',
      vivienda.tieneLuz ? 'Sí' : 'No',
    );

    _escribirDato(
      sheet,
      fila,
      7,
      'Agua',
      vivienda.tieneAgua ? 'Sí' : 'No',
    );

    _escribirDato(
      sheet,
      fila,
      10,
      'Baño',
      vivienda.tieneBanoSanitario
          ? 'Sí'
          : 'No',
    );

    fila++;

    _escribirDato(
      sheet,
      fila,
      0,
      'Gas / leña',
      vivienda.gasLena,
    );

    _escribirDato(
      sheet,
      fila,
      4,
      'Material',
      vivienda.material,
    );

    _escribirDato(
      sheet,
      fila,
      7,
      'Techo',
      vivienda.techo,
    );

    _escribirDato(
      sheet,
      fila,
      10,
      'Piso',
      vivienda.piso,
    );

    fila++;

    _escribirDato(
      sheet,
      fila,
      0,
      'Higiene',
      vivienda.higiene,
    );

    _escribirDato(
      sheet,
      fila,
      4,
      'Animales',
      _animalesTexto(
        vivienda.animales,
      ),
    );

    return fila + 1;
  }

  // ============================================================
  // BLOQUE FAMILIA
  // ============================================================

  int _crearBloqueFamilia(
    Sheet sheet,
    Familia familia,
    List<Persona> integrantes,
    int fila,
  ) {
    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: fila,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 14,
        rowIndex: fila,
      ),
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      'FAMILIA ${familia.codigo}',
    );

    _estiloTituloFila(sheet, fila);

    fila++;

    final encabezados = [
      'Nombre y apellido',
      'Cédula',
      'Fecha nacimiento',
      'Edad',
      'Sexo',
      'Escolaridad',
      'Profesión',
      'Ocupación',
      'Patologías',
      'Factores de riesgo',
      'Grupo D',
      'Embarazada',
      'Semanas',
      'Vacunación',
      'Jefe',
    ];

    for (int i = 0;
        i < encabezados.length;
        i++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: fila,
            ),
          )
          .value = TextCellValue(
        encabezados[i],
      );
    }

    _estiloEncabezados(
      sheet,
      fila,
      encabezados.length,
    );

    fila++;

    final integrantesOrdenados =
        [...integrantes];

    integrantesOrdenados.sort(
      (a, b) {
        if (a.esJefeFamilia &&
            !b.esJefeFamilia) {
          return -1;
        }

        if (!a.esJefeFamilia &&
            b.esJefeFamilia) {
          return 1;
        }

        return a.nombreApellido
            .toLowerCase()
            .compareTo(
              b.nombreApellido
                  .toLowerCase(),
            );
      },
    );

    for (final persona
        in integrantesOrdenados) {
      final datos = [
        persona.nombreApellido,
        persona.cedula,
        _formatearFecha(
          persona.fechaNacimiento,
        ),
        _calcularEdad(
          persona.fechaNacimiento,
        ).toString(),
        persona.sexo,
        persona.escolaridad,
        persona.profesion,
        persona.ocupacion,
        persona.patologias.join('; '),
        persona.factoresRiesgo.join('; '),
        persona.grupoDispensarial
            .toString(),
        persona.embarazada ? 'Sí' : 'No',
        persona.semanasGestacion
                ?.toString() ??
            '',
        persona.estadoVacunacion ??
            '',
        persona.esJefeFamilia
            ? 'Sí'
            : 'No',
      ];

      for (int i = 0;
          i < datos.length;
          i++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: fila,
              ),
            )
            .value = TextCellValue(
          datos[i],
        );
      }

      fila++;
    }

    return fila;
  }

  // ============================================================
  // ESCRIBIR DATO
  // ============================================================

  void _escribirDato(
    Sheet sheet,
    int fila,
    int columna,
    String etiqueta,
    String valor,
  ) {
    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: columna,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      '$etiqueta:',
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: columna + 1,
            rowIndex: fila,
          ),
        )
        .value = TextCellValue(
      valor,
    );
  }

  // ============================================================
  // ESTILO TÍTULO
  // ============================================================

  void _estiloTituloFila(
    Sheet sheet,
    int fila,
  ) {
    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: fila,
          ),
        )
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 13,
      horizontalAlign:
          HorizontalAlign.Center,
    );
  }

  // ============================================================
  // ESTILO ENCABEZADOS
  // ============================================================

  void _estiloEncabezados(
    Sheet sheet,
    int fila,
    int cantidad,
  ) {
    for (int i = 0;
        i < cantidad;
        i++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: fila,
            ),
          )
          .cellStyle = CellStyle(
        bold: true,
        horizontalAlign:
            HorizontalAlign.Center,
      );
    }
  }

  // ============================================================
  // AJUSTAR COLUMNAS
  // ============================================================

  void _ajustarColumnas(
    Sheet sheet,
  ) {
    for (int i = 0; i < 15; i++) {
      sheet.setColumnWidth(i, 18);
    }

    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(8, 30);
    sheet.setColumnWidth(9, 30);
  }

  // ============================================================
  // ANIMALES
  // ============================================================

  String _animalesTexto(
    Map<String, int> animales,
  ) {
    if (animales.isEmpty) {
      return 'Ninguno';
    }

    return animales.entries
        .map(
          (entry) =>
              '${entry.key}: ${entry.value}',
        )
        .join('; ');
  }

  // ============================================================
  // FECHA
  // ============================================================

  String _formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final dia =
        fecha.day.toString().padLeft(
              2,
              '0',
            );

    final mes =
        fecha.month.toString().padLeft(
              2,
              '0',
            );

    return '$dia/$mes/${fecha.year}';
  }

  // ============================================================
  // EDAD
  // ============================================================

  int _calcularEdad(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return 0;
    }

    final hoy = DateTime.now();

    int edad =
        hoy.year - fecha.year;

    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month &&
            hoy.day < fecha.day)) {
      edad--;
    }

    return edad;
  }
}