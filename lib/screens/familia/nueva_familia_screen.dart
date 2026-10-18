import 'package:flutter/material.dart';

import '../../models/familia.dart';
import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';
import '../persona/nueva_persona_screen.dart';

class NuevaFamiliaScreen extends StatefulWidget {
  final Vivienda vivienda;
  final Familia? familia;

  const NuevaFamiliaScreen({
    super.key,
    required this.vivienda,
    this.familia,
  });

  bool get esEdicion => familia != null;

  @override
  State<NuevaFamiliaScreen> createState() =>
      _NuevaFamiliaScreenState();
}

class _NuevaFamiliaScreenState
    extends State<NuevaFamiliaScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();

  String _codigoFamilia = '';
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    if (widget.esEdicion) {
      _cargarFamilia();
    } else {
      _generarCodigo();
    }
  }

  // ============================================================
  // CARGAR FAMILIA
  // ============================================================

  void _cargarFamilia() {
    final familia = widget.familia!;

    setState(() {
      _codigoFamilia = familia.codigo;
      _cargando = false;
    });
  }

  // ============================================================
  // GENERAR CÓDIGO DE FAMILIA
  // ============================================================

  Future<void> _generarCodigo() async {
    try {
      final codigo =
          await _firebaseService.generarCodigoFamilia(
        widget.vivienda.id,
      );

      if (!mounted) return;

      setState(() {
        _codigoFamilia = codigo;
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
            'Error al generar el código: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // GUARDAR FAMILIA
  // ============================================================

  Future<void> _guardarFamilia() async {
    if (_guardando) return;

    setState(() {
      _guardando = true;
    });

    try {
      // ========================================================
      // EDICIÓN DE FAMILIA
      // ========================================================

      if (widget.esEdicion) {
        final familiaActual =
            widget.familia!;

        // Una familia existente no puede guardarse
        // sin jefe de familia.
        if (familiaActual.jefeFamiliaId.isEmpty) {
          if (!mounted) return;

          setState(() {
            _guardando = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta familia no tiene jefe de familia asignado.',
              ),
            ),
          );

          return;
        }

        final familiaActualizada =
            Familia(
          id: familiaActual.id,
          comunidadId:
              familiaActual.comunidadId,
          viviendaId:
              familiaActual.viviendaId,
          codigo:
              familiaActual.codigo,
          jefeFamiliaId:
              familiaActual.jefeFamiliaId,
          fechaRegistro:
              familiaActual.fechaRegistro,
        );

        await _firebaseService.actualizarFamilia(
          familiaActualizada.id,
          familiaActualizada,
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          familiaActualizada.id,
        );

        return;
      }

      // ========================================================
      // NUEVA FAMILIA
      // ========================================================
      //
      // IMPORTANTE:
      //
      // NO creamos todavía la familia en Firebase.
      //
      // Primero registramos al jefe.
      //
      // Si el usuario cancela, no queda ninguna familia
      // incompleta en Firebase.
      // ========================================================

      final familiaTemporal =
          Familia(
        id: '',
        comunidadId:
            widget.vivienda.comunidadId,
        viviendaId:
            widget.vivienda.id,
        codigo:
            _codigoFamilia,
        jefeFamiliaId: '',
      );

      final jefeId =
          await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NuevaPersonaScreen(
            familia:
                familiaTemporal,
            esJefeFamilia: true,
          ),
        ),
      );

      if (!mounted) return;

      // ========================================================
      // SI NO SE REGISTRÓ EL JEFE
      // ========================================================

      if (jefeId == null ||
          jefeId.isEmpty) {
        setState(() {
          _guardando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La familia no fue creada porque debes registrar un jefe de familia.',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // CREAR LA FAMILIA CON EL JEFE
      // ========================================================

      final familia =
          Familia(
        id: '',
        comunidadId:
            widget.vivienda.comunidadId,
        viviendaId:
            widget.vivienda.id,
        codigo:
            _codigoFamilia,
        jefeFamiliaId:
            jefeId,
      );

      final familiaId =
          await _firebaseService.crearFamilia(
        familia,
      );

      // ========================================================
      // ACTUALIZAR LA PERSONA JEFE
      // ========================================================
      //
      // Ahora que ya tenemos el ID real de la familia,
      // actualizamos la persona para que pertenezca a ella.
      // ========================================================

      await _firebaseService
          .actualizarFamiliaDePersona(
        jefeId,
        familiaId,
        esJefeFamilia: true,
      );

      if (!mounted) return;

      // ========================================================
      // FINALIZAR
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Familia creada correctamente con su jefe de familia.',
          ),
        ),
      );

      Navigator.pop(
        context,
        familiaId,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar la familia: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.esEdicion
                ? 'Editar familia'
                : 'Nueva familia',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esEdicion
              ? 'Editar familia'
              : 'Nueva familia',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ======================================================
          // INFORMACIÓN DE LA VIVIENDA
          // ======================================================

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.home,
                    size: 50,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.vivienda.codigo,
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.vivienda.direccion,
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // TÍTULO
          // ======================================================

          Text(
            widget.esEdicion
                ? 'Editar familia'
                : 'Nueva familia',
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // CÓDIGO
          // ======================================================

          InputDecorator(
            decoration:
                const InputDecoration(
              labelText:
                  'Código de familia',
              border:
                  OutlineInputBorder(),
              prefixIcon:
                  Icon(
                Icons.family_restroom,
              ),
            ),
            child: Text(
              _codigoFamilia,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Esta familia se registrará dentro de la vivienda seleccionada.',
            style:
                TextStyle(
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // INFORMACIÓN SOBRE JEFE
          // ======================================================

          if (!widget.esEdicion)
            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para crear una familia es obligatorio registrar primero al jefe de familia.',
                      style:
                          TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!widget.esEdicion)
            const SizedBox(height: 12),

          if (!widget.esEdicion)
            const Text(
              'Si cancelas el registro del jefe, la familia no será creada.',
              style:
                  TextStyle(
                fontSize: 15,
                fontStyle:
                    FontStyle.italic,
              ),
            ),

          const SizedBox(height: 32),

          // ======================================================
          // BOTÓN
          // ======================================================

          SizedBox(
            height: 52,
            child:
                ElevatedButton.icon(
              onPressed: _guardando
                  ? null
                  : _guardarFamilia,

              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      widget.esEdicion
                          ? Icons.save
                          : Icons.person_add,
                    ),

              label: Text(
                _guardando
                    ? 'Guardando...'
                    : widget.esEdicion
                        ? 'Guardar cambios'
                        : 'Registrar jefe de familia',
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}