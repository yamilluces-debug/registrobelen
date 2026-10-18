import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/familia.dart';
import '../models/persona.dart';
import '../models/vivienda.dart';

class PdfService {
  // ============================================================
  // FICHA DE UNA FAMILIA
  // ============================================================

  Future<Uint8List> generarFichaFamilia({
    required Familia familia,
    required Vivienda vivienda,
    required List<Persona> personas,
  }) async {
    final pdf = pw.Document();

    final personasOrdenadas =
        _ordenarPersonas(personas);

    final grupos = <List<Persona>>[];

    for (
      int i = 0;
      i < personasOrdenadas.length;
      i += 10
    ) {
      final fin =
          (i + 10 < personasOrdenadas.length)
              ? i + 10
              : personasOrdenadas.length;

      grupos.add(
        personasOrdenadas.sublist(i, fin),
      );
    }

    if (grupos.isEmpty) {
      grupos.add([]);
    }

    for (
      int pagina = 0;
      pagina < grupos.length;
      pagina++
    ) {
      pdf.addPage(
        _crearPagina(
          familia: familia,
          vivienda: vivienda,
          personas: grupos[pagina],
          numeroPagina: pagina + 1,
          esPrimeraPagina: pagina == 0,
        ),
      );
    }

    final bytes = await pdf.save();

    return Uint8List.fromList(bytes);
  }

  // ============================================================
  // ORDENAR PERSONAS
  // ============================================================

  List<Persona> _ordenarPersonas(
    List<Persona> personas,
  ) {
    final resultado = [...personas];

    resultado.sort(
      (a, b) {
        // EL JEFE SIEMPRE VA PRIMERO
        if (a.esJefeFamilia &&
            !b.esJefeFamilia) {
          return -1;
        }

        if (!a.esJefeFamilia &&
            b.esJefeFamilia) {
          return 1;
        }

        // Los demás se ordenan
        // alfabéticamente por nombre completo.
        return a.nombreApellido
            .toLowerCase()
            .compareTo(
              b.nombreApellido.toLowerCase(),
            );
      },
    );

    return resultado;
  }

  // ============================================================
  // PÁGINA PRINCIPAL
  // ============================================================

  pw.Page _crearPagina({
    required Familia familia,
    required Vivienda vivienda,
    required List<Persona> personas,
    required int numeroPagina,
    required bool esPrimeraPagina,
  }) {
    return pw.Page(
      pageFormat:
          PdfPageFormat.a4.landscape,
      margin:
          const pw.EdgeInsets.fromLTRB(
        28,
        24,
        28,
        24,
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.stretch,
          children: [
            if (esPrimeraPagina) ...[
              _encabezadoInstitucional(),

              pw.SizedBox(height: 18),

              _datosCabecera(
                familia,
                vivienda,
                personas,
              ),

              pw.SizedBox(height: 16),

              pw.Center(
                child: pw.Text(
                  'HISTORIA DE SALUD FAMILIAR',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),
            ],

            if (!esPrimeraPagina)
              pw.Container(
                margin:
                    const pw.EdgeInsets.only(
                  bottom: 10,
                ),
                child: pw.Text(
                  'HISTORIA DE SALUD FAMILIAR - CONTINUACIÓN',
                  textAlign:
                      pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
              ),

            _tablaHistoria(
              personas,
              numeroPagina,
            ),

            if (esPrimeraPagina) ...[
              pw.SizedBox(height: 14),

              _bloquesVivienda(
                vivienda,
                personas,
              ),
            ],
          ],
        );
      },
    );
  }

  // ============================================================
  // ENCABEZADO
  // ============================================================

 pw.Widget _encabezadoInstitucional() {
  return pw.Column(
    children: [
      pw.Text(
        'CONSULTORIO POPULAR TIPO II. VILLA BELÉN',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),

      pw.SizedBox(height: 3),

      pw.Text(
      
        'ASIC 19 DE ABRIL',

        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    ],
  );
}

  // ============================================================
  // DATOS DE CABECERA
  // ============================================================

  pw.Widget _datosCabecera(
    Familia familia,
    Vivienda vivienda,
    List<Persona> personas,
  ) {
    final jefe = personas.where(
      (persona) =>
          persona.id ==
          familia.jefeFamiliaId,
    );

    final nombreFamilia =
        jefe.isNotEmpty
            ? jefe.first.apellidos
            : 'Sin jefe registrado';

    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: _datoCabecera(
                'Familia',
                nombreFamilia,
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: _datoCabecera(
                'Estado',
                'Bolívar',
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: _datoCabecera(
                'Municipio',
                'Caroní',
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: _datoCabecera(
                'Parroquia',
                'Pozo Verde',
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        pw.Row(
          children: [
            pw.Expanded(
              child: _datoCabecera(
                'Dirección de la Vivienda',
                vivienda.direccion,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _datoCabecera(
    String etiqueta,
    String valor,
  ) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$etiqueta: ',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: valor,
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLA PRINCIPAL
  // ============================================================

  pw.Widget _tablaHistoria(
    List<Persona> personas,
    int numeroPagina,
  ) {
    final filas =
        <pw.TableRow>[];

    filas.add(
      pw.TableRow(
        children: [
          _encabezadoTabla('N°'),
          _encabezadoTabla(
            'NOMBRE Y APELLIDO',
          ),
          _encabezadoTabla(
            'FECHA N.',
          ),
          _encabezadoTabla(
            'EDAD',
          ),
          _encabezadoTabla(
            'SEXO',
          ),
          _encabezadoTabla(
            'CÉDULA',
          ),
          _encabezadoTabla(
            'ESCOLARIDAD',
          ),
          _encabezadoTabla(
            'PROFESIÓN',
          ),
          _encabezadoTabla(
            'OCUPACIÓN',
          ),
          _encabezadoTabla(
            'PATOLOGÍA',
          ),
          _encabezadoTabla(
            'GRUPO D.',
          ),
        ],
      ),
    );

    for (int i = 0; i < 10; i++) {
      final persona =
          i < personas.length
              ? personas[i]
              : null;

      filas.add(
        pw.TableRow(
          children: [
            _celdaTabla(
              persona == null
                  ? ''
                  : '${i + 1}',
            ),
            _celdaTabla(
              persona?.nombreApellido ?? '',
            ),
            _celdaTabla(
              persona == null
                  ? ''
                  : _formatearFecha(
                      persona
                          .fechaNacimiento,
                    ),
            ),
            _celdaTabla(
              persona == null
                  ? ''
                  : _calcularEdad(
                      persona
                          .fechaNacimiento,
                    ).toString(),
            ),
            _celdaTabla(
              persona?.sexo ?? '',
            ),
            _celdaTabla(
              persona?.cedula ?? '',
            ),
            _celdaTabla(
              persona?.escolaridad ?? '',
            ),
            _celdaTabla(
              persona?.profesion ?? '',
            ),
            _celdaTabla(
              persona?.ocupacion ?? '',
            ),
            _celdaTabla(
              persona == null
                  ? ''
                  : persona.patologias.join(
                      ', ',
                    ),
            ),
            _celdaTabla(
              persona == null
                  ? ''
                  : persona
                      .grupoDispensarial
                      .toString(),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey700,
        width: 0.6,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(23),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(1.05),
        3: pw.FixedColumnWidth(35),
        4: pw.FixedColumnWidth(38),
        5: pw.FlexColumnWidth(1.15),
        6: pw.FlexColumnWidth(1.4),
        7: pw.FlexColumnWidth(1.25),
        8: pw.FlexColumnWidth(1.35),
        9: pw.FlexColumnWidth(1.65),
        10: pw.FixedColumnWidth(48),
      },
      children: filas,
    );
  }

  pw.Widget _encabezadoTabla(
    String texto,
  ) {
    return pw.Container(
      alignment:
          pw.Alignment.center,
      padding:
          const pw.EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 5,
      ),
      child: pw.Text(
        texto,
        textAlign:
            pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6.7,
          fontWeight:
              pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _celdaTabla(
    String texto,
  ) {
    return pw.Container(
      height: 20,
      alignment:
          pw.Alignment.centerLeft,
      padding:
          const pw.EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 2,
      ),
      child: pw.Text(
        texto,
        maxLines: 2,
        overflow:
            pw.TextOverflow.clip,
        style: const pw.TextStyle(
          fontSize: 6.5,
        ),
      ),
    );
  }

  // ============================================================
  // BLOQUES INFERIORES
  // ============================================================

  pw.Widget _bloquesVivienda(
    Vivienda vivienda,
    List<Persona> personas,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey700,
        width: 0.6,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            _tituloBloque(
              'Servicios Básicos',
            ),
            _tituloBloque(
              'Condiciones de la\nVivienda',
            ),
            _tituloBloque(
              'Higiene del Hogar',
            ),
            _tituloBloque(
              'Animales (cuales y\ncantidad)',
            ),
            _tituloBloque(
              'Factores de Riesgo',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _contenidoBloque(
              _serviciosTexto(vivienda),
            ),
            _contenidoBloque(
              _condicionesTexto(vivienda),
            ),
            _contenidoBloque(
              vivienda.higiene.isEmpty
                  ? ''
                  : vivienda.higiene,
            ),
            _contenidoBloque(
              _animalesTexto(
                vivienda.animales,
              ),
            ),
            _contenidoBloque(
              _factoresRiesgoTexto(
                personas,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tituloBloque(
    String texto,
  ) {
    return pw.Container(
      height: 34,
      alignment:
          pw.Alignment.topLeft,
      padding:
          const pw.EdgeInsets.all(5),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 7.8,
          fontWeight:
              pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _contenidoBloque(
    String texto,
  ) {
    return pw.Container(
      height: 82,
      alignment:
          pw.Alignment.topLeft,
      padding:
          const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(
          fontSize: 7.5,
        ),
      ),
    );
  }

  // ============================================================
  // DATOS DE VIVIENDA
  // ============================================================

  String _serviciosTexto(
    Vivienda vivienda,
  ) {
    return [
      'Luz: ${vivienda.tieneLuz ? 'Sí' : 'No'}',
      'Agua: ${vivienda.tieneAgua ? 'Sí' : 'No'}',
      'Gas / Leña: ${vivienda.gasLena}',
      'Baño sanitario: '
          '${vivienda.tieneBanoSanitario ? 'Sí' : 'No'}',
    ].join('\n');
  }

  String _condicionesTexto(
    Vivienda vivienda,
  ) {
    return [
      'Material: ${vivienda.material}',
      'Techo: ${vivienda.techo}',
      'Piso: ${vivienda.piso}',
    ].join('\n');
  }

  String _animalesTexto(
    Map<String, int> animales,
  ) {
    if (animales.isEmpty) {
      return '';
    }

    return animales.entries
        .map(
          (entry) =>
              '${entry.key}: ${entry.value}',
        )
        .join('\n');
  }

  String _factoresRiesgoTexto(
    List<Persona> personas,
  ) {
    final factores =
        <String>{};

    for (final persona in personas) {
      factores.addAll(
        persona.factoresRiesgo,
      );
    }

    if (factores.isEmpty) {
      return '';
    }

    return factores.join('\n');
  }

  // ============================================================
  // EXPORTACIÓN GENERAL
  // ============================================================

  Future<Uint8List> generarCensoGeneral({
    required List<Vivienda> viviendas,
    required Map<String, List<Familia>>
        familiasPorVivienda,
    required Map<String, List<Persona>>
        personasPorFamilia,
  }) async {
    final pdf = pw.Document();

    bool tieneContenido = false;

    for (final vivienda in viviendas) {
      final familias =
          familiasPorVivienda[
                  vivienda.id] ??
              [];

      for (final familia in familias) {
        tieneContenido = true;

        final personas =
            personasPorFamilia[
                    familia.id] ??
                [];

        final personasOrdenadas =
            _ordenarPersonas(personas);

        final grupos =
            <List<Persona>>[];

        for (
          int i = 0;
          i < personasOrdenadas.length;
          i += 10
        ) {
          final fin =
              (i + 10 <
                      personasOrdenadas.length)
                  ? i + 10
                  : personasOrdenadas.length;

          grupos.add(
            personasOrdenadas.sublist(
              i,
              fin,
            ),
          );
        }

        if (grupos.isEmpty) {
          grupos.add([]);
        }

        for (
          int pagina = 0;
          pagina < grupos.length;
          pagina++
        ) {
          pdf.addPage(
            _crearPagina(
              familia: familia,
              vivienda: vivienda,
              personas: grupos[pagina],
              numeroPagina:
                  pagina + 1,
              esPrimeraPagina:
                  pagina == 0,
            ),
          );
        }
      }
    }

    if (!tieneContenido) {
      pdf.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Center(
              child: pw.Text(
                'No hay familias registradas.',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
    }

    final bytes =
        await pdf.save();

    return Uint8List.fromList(
      bytes,
    );
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  String _formatearFecha(
    DateTime? fecha,
  ) {
    if (fecha == null) {
      return '';
    }

    final dia =
        fecha.day
            .toString()
            .padLeft(2, '0');

    final mes =
        fecha.month
            .toString()
            .padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

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
        (hoy.month ==
                fecha.month &&
            hoy.day < fecha.day)) {
      edad--;
    }

    return edad;
  }
}