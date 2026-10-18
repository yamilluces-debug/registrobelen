import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/familia.dart';
import '../../models/persona.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import '../persona/nueva_persona_screen.dart';

class DetalleFamiliaScreen extends StatefulWidget {
  final Familia familia;

  const DetalleFamiliaScreen({
    super.key,
    required this.familia,
  });

  @override
  State<DetalleFamiliaScreen> createState() =>
      _DetalleFamiliaScreenState();
}

class _DetalleFamiliaScreenState
    extends State<DetalleFamiliaScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();

  List<Persona> _personas = [];

  Persona? _jefeFamilia;

  bool _cargando = true;

  // ID del jefe actual.
  //
  // Lo mantenemos separado de widget.familia porque
  // widget.familia contiene el valor con el que se abrió
  // esta pantalla y no se actualiza automáticamente.
  String _jefeFamiliaId = '';

  // ============================================================
  // CARGA FAMILIAR
  // ============================================================

  List<Persona> get _cargaFamiliar {
    return _personas
        .where(
          (persona) =>
              persona.id != _jefeFamiliaId,
        )
        .toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _jefeFamiliaId =
        widget.familia.jefeFamiliaId;

    _cargarFamilia();
  }

  // ============================================================
  // CARGAR FAMILIA
  // ============================================================

  Future<void> _cargarFamilia() async {
    try {
      final personas =
          await _firebaseService
              .obtenerPersonasDeFamilia(
        widget.familia.id,
      );

      Persona? jefe;

      // Buscar el jefe utilizando el ID actual.
      if (_jefeFamiliaId.isNotEmpty) {
        jefe = await _firebaseService
            .obtenerPersonaPorId(
          _jefeFamiliaId,
        );
      }

      // Si por alguna razón no encontramos el jefe
      // mediante el ID, intentamos localizarlo por
      // esJefeFamilia dentro de las personas.
      jefe ??= personas
          .where(
            (persona) =>
                persona.esJefeFamilia,
          )
          .firstOrNull;

      if (jefe != null) {
        _jefeFamiliaId = jefe.id;
      }

      if (!mounted) return;

      setState(() {
        _personas = personas;
        _jefeFamilia = jefe;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar la familia: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EXPORTAR PDF
  // ============================================================

  Future<void> _exportarPdfFamilia() async {
    try {
      final vivienda =
          await _firebaseService
              .obtenerViviendaPorId(
        widget.familia.viviendaId,
      );

      if (!mounted) return;

      if (vivienda == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró la vivienda asociada.',
            ),
          ),
        );

        return;
      }

      final personas =
          await _firebaseService
              .obtenerPersonasDeFamilia(
        widget.familia.id,
      );

      if (!mounted) return;

      final pdfService =
          PdfService();

      final bytes =
          await pdfService.generarFichaFamilia(
        familia: widget.familia,
        vivienda: vivienda,
        personas: personas,
      );

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name:
                  'Familia_${widget.familia.codigo}.pdf',
              mimeType:
                  'application/pdf',
            ),
          ],
          subject:
              'Ficha familiar ${widget.familia.codigo}',
          text:
              'Ficha familiar de la Comunidad Belén.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo generar el PDF: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EXPORTAR EXCEL
  // ============================================================

  Future<void> _exportarFamilia() async {
    try {
      final vivienda =
          await _firebaseService
              .obtenerViviendaPorId(
        widget.familia.viviendaId,
      );

      if (!mounted) return;

      if (vivienda == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró la vivienda asociada.',
            ),
          ),
        );

        return;
      }

      final excelService =
          ExcelService();

      final bytes =
          await excelService.exportarFamilia(
        familia: widget.familia,
        vivienda: vivienda,
      );

      if (!mounted) return;

      final directorio =
          await getTemporaryDirectory();

      final archivo = File(
        '${directorio.path}/Familia_${widget.familia.codigo}.xlsx',
      );

      await archivo.writeAsBytes(bytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(archivo.path),
          ],
          subject:
              'Ficha familiar ${widget.familia.codigo}',
          text:
              'Ficha familiar de la Comunidad Belén.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo exportar la familia: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CAMBIAR JEFE DE FAMILIA
  // ============================================================

  Future<void> _cambiarJefeFamilia() async {
    // Todos los integrantes excepto el jefe actual
    // pueden convertirse en el nuevo jefe.
    final candidatos = _personas
        .where(
          (persona) =>
              persona.id !=
              _jefeFamiliaId,
        )
        .toList();

    if (candidatos.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'No hay candidatos',
            ),
            content: const Text(
              'Para cambiar el jefe debe existir '
              'al menos otro integrante en la familia.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child:
                    const Text('Entendido'),
              ),
            ],
          );
        },
      );

      return;
    }

    // ==========================================================
    // SELECCIONAR NUEVO JEFE
    // ==========================================================

    final Persona? nuevoJefe =
        await showDialog<Persona>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Seleccionar nuevo jefe',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  candidatos.length,
              itemBuilder:
                  (context, index) {
                final persona =
                    candidatos[index];

                return ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                  title: Text(
                    persona.nombreApellido,
                  ),
                  subtitle: Text(
                    _descripcionPersona(
                      persona,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      persona,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (nuevoJefe == null) {
      return;
    }

    // ==========================================================
    // CONFIRMAR
    // ==========================================================

if (!mounted) return;

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Confirmar cambio de jefe',
          ),
          content: Text(
            '¿Deseas asignar a '
            '${nuevoJefe.nombreApellido} '
            'como nuevo jefe de familia?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmar != true) {
      return;
    }

    // ==========================================================
    // GUARDAR CAMBIO
    // ==========================================================

    try {
      await _firebaseService
          .asignarJefeFamilia(
        widget.familia.id,
        nuevoJefe.id,
      );

      // Actualizar inmediatamente el estado local.
      setState(() {
        _jefeFamiliaId =
            nuevoJefe.id;
        _jefeFamilia =
            nuevoJefe;
      });

      // Volver a cargar todos los datos
      // para mantener la pantalla sincronizada.
      await _cargarFamilia();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${nuevoJefe.nombreApellido} ahora es el jefe de familia.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cambiar el jefe: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // AGREGAR INTEGRANTE
  // ============================================================

  Future<void> _agregarIntegrante() async {
    final personaId =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NuevaPersonaScreen(
          familia:
              widget.familia,
          esJefeFamilia: false,
        ),
      ),
    );

    if (!mounted) return;

    if (personaId != null) {
      await _cargarFamilia();
    }
  }

  // ============================================================
  // EDITAR PERSONA
  // ============================================================

  Future<void> _editarPersona(
    Persona persona,
  ) async {
    final resultado =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NuevaPersonaScreen(
          familia:
              widget.familia,
          esJefeFamilia:
              persona.id ==
                  _jefeFamiliaId,
          persona: persona,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado != null) {
      await _cargarFamilia();
    }
  }

  // ============================================================
  // ELIMINAR PERSONA
  // ============================================================

  Future<void> _confirmarEliminarPersona(
    Persona persona,
  ) async {
    final esJefe =
        persona.id == _jefeFamiliaId;

    // ----------------------------------------------------------
    // NO PERMITIR ELIMINAR AL JEFE
    // ----------------------------------------------------------

    if (esJefe) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'No se puede eliminar',
            ),
            content: const Text(
              'Esta persona es el jefe de familia. '
              'Debes asignar primero a otra persona '
              'como jefe de familia antes de eliminarla.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child:
                    const Text('Entendido'),
              ),
            ],
          );
        },
      );

      return;
    }

    // ----------------------------------------------------------
    // CONFIRMAR ELIMINACIÓN
    // ----------------------------------------------------------

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar integrante',
          ),
          content: Text(
            '¿Estás segura de que deseas eliminar '
            'a ${persona.nombreApellido}?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancelar'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmar != true) {
      return;
    }

    try {
      await _firebaseService
          .eliminarPersona(
        persona.id,
      );

      await _cargarFamilia();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Integrante eliminado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el integrante: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DESCRIPCIÓN DE PERSONA
  // ============================================================

  String _descripcionPersona(
    Persona persona,
  ) {
    final edad = _calcularEdad(
      persona.fechaNacimiento,
    );

    final partes = <String>[];

    partes.add(
      '$edad años',
    );

    partes.add(
      persona.sexo,
    );

    if (persona.patologias.isNotEmpty) {
      partes.add(
        '${persona.patologias.length} patología(s)',
      );
    }

    return partes.join(' • ');
  }

  // ============================================================
  // CALCULAR EDAD
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.familia.codigo,
        ),
        actions: [
          // ------------------------------------------------------
          // EXCEL
          // ------------------------------------------------------

          IconButton(
            tooltip:
                'Exportar Excel',
            icon: const Icon(
              Icons.table_view,
            ),
            onPressed:
                _exportarFamilia,
          ),

          // ------------------------------------------------------
          // PDF
          // ------------------------------------------------------

          IconButton(
            tooltip:
                'Exportar PDF',
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            onPressed:
                _exportarPdfFamilia,
          ),
        ],
      ),

      body: _cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _cargarFamilia,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  // ==================================================
                  // CABECERA
                  // ==================================================

                  _cabeceraFamilia(),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // JEFE
                  // ==================================================

                  _seccionTitulo(
                    'Jefe de familia',
                    Icons.person,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _jefeFamilia == null
                      ? _sinJefe()
                      : _tarjetaJefe(
                          _jefeFamilia!,
                        ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // CARGA FAMILIAR
                  // ==================================================

                  Row(
                    children: [
                      Icon(
                        Icons.groups,
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primary,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Expanded(
                        child: Text(
                          'Carga familiar',
                          style:
                              TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_cargaFamiliar.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (_cargaFamiliar
                      .isEmpty)
                    _sinIntegrantes()
                  else
                    ..._cargaFamiliar.map(
                      _tarjetaPersona,
                    ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // AGREGAR INTEGRANTE
                  // ==================================================

                  SizedBox(
                    height: 52,
                    child:
                        ElevatedButton
                            .icon(
                      onPressed:
                          _agregarIntegrante,
                      icon:
                          const Icon(
                        Icons.person_add,
                      ),
                      label:
                          const Text(
                        'Agregar integrante',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // CABECERA FAMILIA
  // ============================================================

  Widget _cabeceraFamilia() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(
                Icons.family_restroom,
                size: 34,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              widget.familia.codigo,
              style:
                  const TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Ficha familiar',
              style:
                  TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TÍTULO DE SECCIÓN
  // ============================================================

  Widget _seccionTitulo(
    String titulo,
    IconData icono,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          titulo,
          style:
              const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TARJETA JEFE
  // ============================================================

  Widget _tarjetaJefe(
    Persona persona,
  ) {
    return Card(
      child: ListTile(
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.person,
          ),
        ),

        title: Text(
          persona.nombreApellido,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Text(
          _descripcionPersona(
            persona,
          ),
        ),

        trailing: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Chip(
              avatar: Icon(
                Icons.star,
                size: 16,
              ),
              label:
                  Text('JEFE'),
            ),

            IconButton(
              tooltip:
                  'Cambiar jefe',
              icon: const Icon(
                Icons.swap_horiz,
              ),
              onPressed:
                  _cambiarJefeFamilia,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA PERSONA
  // ============================================================

  Widget _tarjetaPersona(
    Persona persona,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.person,
          ),
        ),

        title: Text(
          persona.nombreApellido,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle: Text(
          _descripcionPersona(
            persona,
          ),
        ),

        trailing:
            PopupMenuButton<String>(
          onSelected:
              (opcion) async {
            if (opcion ==
                'editar') {
              await _editarPersona(
                persona,
              );
            }

            if (opcion ==
                'eliminar') {
              await _confirmarEliminarPersona(
                persona,
              );
            }
          },
          itemBuilder:
              (context) => [
            const PopupMenuItem<
                String>(
              value: 'editar',
              child: ListTile(
                leading:
                    Icon(
                  Icons.edit,
                ),
                title:
                    Text('Editar'),
              ),
            ),
            const PopupMenuItem<
                String>(
              value: 'eliminar',
              child: ListTile(
                leading:
                    Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title:
                    Text(
                  'Eliminar',
                ),
              ),
            ),
          ],
        ),

        onTap: () async {
          await _editarPersona(
            persona,
          );
        },
      ),
    );
  }

  // ============================================================
  // SIN JEFE
  // ============================================================

  Widget _sinJefe() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.person_off,
              size: 40,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'No se ha registrado el jefe de familia.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 12,
            ),

            if (_personas.isNotEmpty)
              OutlinedButton.icon(
                onPressed:
                    _cambiarJefeFamilia,
                icon: const Icon(
                  Icons.person_add_alt_1,
                ),
                label: const Text(
                  'Asignar jefe',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIN INTEGRANTES
  // ============================================================

  Widget _sinIntegrantes() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.groups,
              size: 40,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'No hay integrantes adicionales registrados.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}