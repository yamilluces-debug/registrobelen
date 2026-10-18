import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'detalle_vivienda_screen.dart';
import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';
import '../../services/excel_service.dart';
import 'nueva_vivienda_screen.dart';
import '../../services/pdf_service.dart';
import '../../models/familia.dart';
import '../../models/persona.dart';

class ViviendasScreen extends StatefulWidget {
  const ViviendasScreen({super.key});

  @override
  State<ViviendasScreen> createState() => _ViviendasScreenState();
}

class _ViviendasScreenState extends State<ViviendasScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<Vivienda> _viviendas = [];
  bool _cargando = true;
  bool _exportando = false;

  // Guarda el ID de la vivienda que se está eliminando.
  // Sirve para mostrar un indicador solamente en esa vivienda.
  String? _eliminandoViviendaId;

  @override
  void initState() {
    super.initState();
    _cargarViviendas();
  }

  // ============================================================
  // CARGAR VIVIENDAS
  // ============================================================

  Future<void> _cargarViviendas() async {
    try {
      final viviendas =
          await _firebaseService.obtenerViviendas();

      if (!mounted) return;

      setState(() {
        _viviendas = viviendas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar viviendas: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ELIMINAR VIVIENDA
  // ============================================================

  Future<void> _confirmarEliminarVivienda(
    Vivienda vivienda,
  ) async {
    // Evitar que se puedan iniciar dos eliminaciones al mismo tiempo.
    if (_eliminandoViviendaId != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eliminar vivienda',
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás segura de que deseas eliminar la vivienda '
            '${vivienda.codigo}?\n\n'
            'Esta acción también eliminará todas las familias '
            'y personas registradas dentro de esta vivienda.\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _eliminarVivienda(vivienda);
  }

  Future<void> _eliminarVivienda(
    Vivienda vivienda,
  ) async {
    if (!mounted) return;

    setState(() {
      _eliminandoViviendaId = vivienda.id;
    });

    try {
      await _firebaseService.eliminarVivienda(
        vivienda.id,
      );

      if (!mounted) return;

      setState(() {
        _viviendas.removeWhere(
          (item) => item.id == vivienda.id,
        );
        _eliminandoViviendaId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La vivienda ${vivienda.codigo} fue eliminada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eliminandoViviendaId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la vivienda: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EXPORTAR EXCEL
  // ============================================================

  Future<void> _exportarCenso() async {
    if (_exportando) return;

    setState(() {
      _exportando = true;
    });

    try {
      final excelService = ExcelService();

      final bytes =
          await excelService.exportarCensoGeneral();

      final directorio =
          await getTemporaryDirectory();

      final archivo = File(
        '${directorio.path}/Censo_Belen.xlsx',
      );

      await archivo.writeAsBytes(bytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(archivo.path),
          ],
          subject: 'Censo Comunidad Belén',
          text:
              'Registro del censo de la Comunidad Belén.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo exportar el censo: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exportando = false;
        });
      }
    }
  }

  // ============================================================
  // EXPORTAR PDF GENERAL
  // ============================================================

  Future<void> _exportarPdfGeneral() async {
    try {
      if (_viviendas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay viviendas registradas para exportar.',
            ),
          ),
        );
        return;
      }

      final familiasPorVivienda =
          <String, List<Familia>>{};

      final personasPorFamilia =
          <String, List<Persona>>{};

      for (final vivienda in _viviendas) {
        final familias =
            await _firebaseService.obtenerFamiliasDeVivienda(
          vivienda.id,
        );

        familiasPorVivienda[vivienda.id] = familias;

        for (final familia in familias) {
          final personas =
              await _firebaseService.obtenerPersonasDeFamilia(
            familia.id,
          );

          personasPorFamilia[familia.id] = personas;
        }
      }

      if (!mounted) return;

      final pdfService = PdfService();

      final bytes =
          await pdfService.generarCensoGeneral(
        viviendas: _viviendas,
        familiasPorVivienda:
            familiasPorVivienda,
        personasPorFamilia:
            personasPorFamilia,
      );

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'Censo_General_Belen.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          subject: 'Censo general Comunidad Belén',
          text:
              'Censo general de la Comunidad Belén.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo generar el PDF general: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viviendas'),
        actions: [
          // ------------------------------------------------------
          // EXPORTAR EXCEL
          // ------------------------------------------------------
          IconButton(
            tooltip: 'Exportar censo',
            onPressed:
                _exportando ? null : _exportarCenso,
            icon: _exportando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.file_download,
                  ),
          ),

          // ------------------------------------------------------
          // EXPORTAR PDF
          // ------------------------------------------------------
          IconButton(
            tooltip: 'Exportar PDF general',
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            onPressed: _exportarPdfGeneral,
          ),
        ],
      ),

      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _viviendas.isEmpty
              ? const Center(
                  child: Text(
                    'No hay viviendas registradas',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarViviendas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viviendas.length,
                    itemBuilder: (context, index) {
                      final vivienda =
                          _viviendas[index];

                      final eliminando =
                          _eliminandoViviendaId ==
                              vivienda.id;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.home,
                            ),
                          ),

                          title: Text(
                            vivienda.codigo,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            vivienda.direccion.isEmpty
                                ? 'Sin dirección registrada'
                                : vivienda.direccion,
                          ),

                          trailing: eliminando
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    // ------------------------------------------------
                                    // BOTÓN ELIMINAR
                                    // ------------------------------------------------
                                    IconButton(
                                      tooltip:
                                          'Eliminar vivienda',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _confirmarEliminarVivienda(
                                          vivienda,
                                        );
                                      },
                                    ),

                                    const Icon(
                                      Icons.chevron_right,
                                    ),
                                  ],
                                ),

                          onTap: eliminando
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleViviendaScreen(
                                        vivienda:
                                            vivienda,
                                      ),
                                    ),
                                  );

                                  if (mounted) {
                                    _cargarViviendas();
                                  }
                                },
                        ),
                      );
                    },
                  ),
                ),

      // ----------------------------------------------------------
      // NUEVA VIVIENDA
      // ----------------------------------------------------------
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final resultado =
              await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const NuevaViviendaScreen(),
            ),
          );

          if (resultado != null) {
            _cargarViviendas();
          }
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Nueva vivienda',
        ),
      ),
    );
  }
}