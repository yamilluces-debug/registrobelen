import 'package:flutter/material.dart';

import '../familia/detalle_familia_screen.dart';
import '../../models/familia.dart';
import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';
import '../familia/nueva_familia_screen.dart';
import 'nueva_vivienda_screen.dart';

class DetalleViviendaScreen extends StatefulWidget {
  final Vivienda vivienda;

  const DetalleViviendaScreen({
    super.key,
    required this.vivienda,
  });

  @override
  State<DetalleViviendaScreen> createState() =>
      _DetalleViviendaScreenState();
}

class _DetalleViviendaScreenState
    extends State<DetalleViviendaScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();

  List<Familia> _familias = [];
  bool _cargandoFamilias = true;

  // ID de la familia que se está eliminando.
  String? _eliminandoFamiliaId;

  @override
  void initState() {
    super.initState();
    _cargarFamilias();
  }

  // ============================================================
  // CARGAR FAMILIAS
  // ============================================================

  Future<void> _cargarFamilias() async {
    try {
      final familias =
          await _firebaseService.obtenerFamiliasDeVivienda(
        widget.vivienda.id,
      );

      if (!mounted) return;

      setState(() {
        _familias = familias;
        _cargandoFamilias = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoFamilias = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar las familias: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EDITAR VIVIENDA
  // ============================================================

  Future<void> _editarVivienda() async {
    final resultado =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NuevaViviendaScreen(
          vivienda: widget.vivienda,
        ),
      ),
    );

    if (resultado == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      resultado,
    );
  }

  // ============================================================
  // AGREGAR FAMILIA
  // ============================================================

  Future<void> _agregarFamilia() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaFamiliaScreen(
          vivienda: widget.vivienda,
        ),
      ),
    );

    if (resultado != null) {
      await _cargarFamilias();
    }
  }

  // ============================================================
  // CONFIRMAR ELIMINACIÓN DE FAMILIA
  // ============================================================

  Future<void> _confirmarEliminarFamilia(
    Familia familia,
  ) async {
    // Evitar iniciar otra eliminación mientras hay una en curso.
    if (_eliminandoFamiliaId != null) {
      return;
    }

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
                  'Eliminar familia',
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás segura de que deseas eliminar '
            'la familia ${familia.codigo}?\n\n'
            'Esta acción también eliminará todas '
            'las personas registradas dentro de esta familia.\n\n'
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
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await _eliminarFamilia(familia);
  }

  // ============================================================
  // ELIMINAR FAMILIA
  // ============================================================

  Future<void> _eliminarFamilia(
    Familia familia,
  ) async {
    if (!mounted) return;

    setState(() {
      _eliminandoFamiliaId = familia.id;
    });

    try {
      await _firebaseService.eliminarFamilia(
        familia.id,
      );

      if (!mounted) return;

      setState(() {
        _familias.removeWhere(
          (item) => item.id == familia.id,
        );

        _eliminandoFamiliaId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La familia ${familia.codigo} fue eliminada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eliminandoFamiliaId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la familia: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final vivienda = widget.vivienda;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vivienda.codigo,
        ),
        actions: [
          IconButton(
            tooltip: 'Editar vivienda',
            icon: const Icon(
              Icons.edit,
            ),
            onPressed: _editarVivienda,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _cargarFamilias,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // IDENTIFICACIÓN DE LA VIVIENDA
            // ==================================================

            _tarjetaIdentificacion(
              vivienda,
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SERVICIOS BÁSICOS
            // ==================================================

            _seccionVivienda(
              titulo: 'Servicios básicos',
              icono: Icons.water_drop,
              contenido: [
                _dato(
                  'Electricidad',
                  vivienda.tieneLuz
                      ? 'Sí'
                      : 'No',
                ),
                _dato(
                  'Agua',
                  vivienda.tieneAgua
                      ? 'Sí'
                      : 'No',
                ),
                _dato(
                  'Gas / Leña',
                  vivienda.gasLena,
                ),
                _dato(
                  'Baño sanitario',
                  vivienda.tieneBanoSanitario
                      ? 'Sí'
                      : 'No',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CONDICIONES DE LA VIVIENDA
            // ==================================================

            _seccionVivienda(
              titulo:
                  'Condiciones de la vivienda',
              icono: Icons.house,
              contenido: [
                _dato(
                  'Material',
                  vivienda.material,
                ),
                _dato(
                  'Techo',
                  vivienda.techo,
                ),
                _dato(
                  'Piso',
                  vivienda.piso,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // HIGIENE
            // ==================================================

            _seccionVivienda(
              titulo: 'Higiene del hogar',
              icono:
                  Icons.cleaning_services,
              contenido: [
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    vivienda.higiene.isEmpty
                        ? 'Sin información registrada'
                        : vivienda.higiene,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // ANIMALES
            // ==================================================

            _seccionAnimales(
              vivienda,
            ),

            const SizedBox(height: 24),

            // ==================================================
            // TÍTULO FAMILIAS
            // ==================================================

            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Familias',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_familias.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // LISTA DE FAMILIAS
            // ==================================================

            if (_cargandoFamilias)
              const Padding(
                padding:
                    EdgeInsets.all(30),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_familias.isEmpty)
              _sinFamilias()
            else
              ..._familias.map(
                _tarjetaFamilia,
              ),

            const SizedBox(height: 16),

            // ==================================================
            // AGREGAR FAMILIA
            // ==================================================

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _agregarFamilia,
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Agregar familia',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA IDENTIFICACIÓN
  // ============================================================

  Widget _tarjetaIdentificacion(
    Vivienda vivienda,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(
                    Icons.home,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        vivienda.codigo,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vivienda.direccion,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECCIÓN DE VIVIENDA
  // ============================================================

  Widget _seccionVivienda({
    required String titulo,
    required IconData icono,
    required List<Widget> contenido,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icono,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...contenido,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATO
  // ============================================================

  Widget _dato(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              titulo,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor.isEmpty
                  ? 'No registrado'
                  : valor,
              textAlign:
                  TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMALES
  // ============================================================

  Widget _seccionAnimales(
    Vivienda vivienda,
  ) {
    final animales =
        vivienda.animales.entries
            .where(
              (elemento) =>
                  elemento.value > 0,
            )
            .toList();

    return _seccionVivienda(
      titulo: 'Animales',
      icono: Icons.pets,
      contenido: [
        if (animales.isEmpty)
          const Text(
            'No se registraron animales',
          )
        else
          ...animales.map(
            (animal) => _dato(
              animal.key,
              animal.value.toString(),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SIN FAMILIAS
  // ============================================================

  Widget _sinFamilias() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.family_restroom,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta vivienda todavía no tiene familias registradas.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA DE FAMILIA
  // ============================================================

  Widget _tarjetaFamilia(
    Familia familia,
  ) {
    final eliminando =
        _eliminandoFamiliaId ==
            familia.id;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(
            Icons.family_restroom,
          ),
        ),

        title: Text(
          familia.codigo,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Text(
          familia.jefeFamiliaId.isEmpty
              ? '⚠️ Sin jefe registrado'
              : '👑 Jefe de familia registrado',
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
                  // --------------------------------------------
                  // EDITAR / ENTRAR A LA FAMILIA
                  // --------------------------------------------
                  IconButton(
                    tooltip:
                        'Ver familia',
                    icon: const Icon(
                      Icons.chevron_right,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetalleFamiliaScreen(
                            familia:
                                familia,
                          ),
                        ),
                      );

                      if (mounted) {
                        await _cargarFamilias();
                      }
                    },
                  ),

                  // --------------------------------------------
                  // ELIMINAR FAMILIA
                  // --------------------------------------------
                  IconButton(
                    tooltip:
                        'Eliminar familia',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      _confirmarEliminarFamilia(
                        familia,
                      );
                    },
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
                        DetalleFamiliaScreen(
                      familia: familia,
                    ),
                  ),
                );

                if (mounted) {
                  await _cargarFamilias();
                }
              },
      ),
    );
  }
}