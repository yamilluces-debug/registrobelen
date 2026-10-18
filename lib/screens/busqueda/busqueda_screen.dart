import 'package:flutter/material.dart';

import '../../models/familia.dart';
import '../../models/persona.dart';
import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';

import '../familia/detalle_familia_screen.dart';
import '../vivienda/detalle_vivienda_screen.dart';


class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() =>
      _BusquedaScreenState();
}

class _BusquedaScreenState
    extends State<BusquedaScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();

  final TextEditingController _buscadorController =
      TextEditingController();

  List<Vivienda> _viviendas = [];
  List<Familia> _familias = [];
  List<Persona> _personas = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _buscadorController.addListener(_actualizarBusqueda);
  }

  @override
  void dispose() {
    _buscadorController
        .removeListener(_actualizarBusqueda);
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final viviendas =
          await _firebaseService.obtenerViviendas();

      final familias =
          await _firebaseService.obtenerFamilias();

      final personas =
          await _firebaseService.obtenerPersonas();

      if (!mounted) return;

      setState(() {
        _viviendas = viviendas;
        _familias = familias;
        _personas = personas;
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
            'Error al cargar los datos: $e',
          ),
        ),
      );
    }
  }

  void _actualizarBusqueda() {
    if (!mounted) return;

    setState(() {});
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .trim();
  }

  List<Vivienda> get _viviendasEncontradas {
    final texto =
        _normalizar(_buscadorController.text);

    if (texto.isEmpty) {
      return [];
    }

    return _viviendas.where((vivienda) {
      return _normalizar(vivienda.codigo)
              .contains(texto) ||
          _normalizar(vivienda.direccion)
              .contains(texto);
    }).toList();
  }

  List<Familia> get _familiasEncontradas {
    final texto =
        _normalizar(_buscadorController.text);

    if (texto.isEmpty) {
      return [];
    }

    return _familias.where((familia) {
      final jefe = _obtenerJefe(familia);

      final nombreJefe =
          jefe?.nombreApellido ?? '';

      return _normalizar(familia.codigo)
              .contains(texto) ||
          _normalizar(nombreJefe)
              .contains(texto);
    }).toList();
  }

  List<Persona> get _personasEncontradas {
    final texto =
        _normalizar(_buscadorController.text);

    if (texto.isEmpty) {
      return [];
    }

    return _personas.where((persona) {
      return _normalizar(
                persona.nombreApellido,
              ).contains(texto) ||
          _normalizar(
                persona.cedula,
              ).contains(texto);
    }).toList();
  }

  Persona? _obtenerJefe(
    Familia familia,
  ) {
    try {
      return _personas.firstWhere(
        (persona) =>
            persona.id ==
            familia.jefeFamiliaId,
      );
    } catch (_) {
      return null;
    }
  }

  Vivienda? _obtenerVivienda(
    Familia familia,
  ) {
    try {
      return _viviendas.firstWhere(
        (vivienda) =>
            vivienda.id ==
            familia.viviendaId,
      );
    } catch (_) {
      return null;
    }
  }

  Familia? _obtenerFamiliaDePersona(
    Persona persona,
  ) {
    try {
      return _familias.firstWhere(
        (familia) =>
            familia.id ==
            persona.familiaId,
      );
    } catch (_) {
      return null;
    }
  }

  int get _totalResultados {
    return _viviendasEncontradas.length +
        _familiasEncontradas.length +
        _personasEncontradas.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller:
                        _buscadorController,
                    autofocus: true,
                    textInputAction:
                        TextInputAction.search,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Buscar en el censo',
                      hintText:
                          'Nombre, cédula, familia, calle...',
                      prefixIcon:
                          const Icon(Icons.search),
                      suffixIcon:
                          _buscadorController
                                  .text
                                  .isEmpty
                              ? null
                              : IconButton(
                                  tooltip:
                                      'Limpiar',
                                  icon: const Icon(
                                    Icons.clear,
                                  ),
                                  onPressed: () {
                                    _buscadorController
                                        .clear();
                                  },
                                ),
                    ),
                  ),
                ),

                Expanded(
                  child: _buscadorController
                          .text
                          .trim()
                          .isEmpty
                      ? _estadoInicial()
                      : _resultados(),
                ),
              ],
            ),
    );
  }

  Widget _estadoInicial() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.search,
              size: 70,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Buscar en el censo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Puedes buscar por nombre, cédula, '
              'familia, código de vivienda '
              'o dirección.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultados() {
    if (_totalResultados == 0) {
      return _sinResultados();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        30,
      ),
      children: [
        Text(
          '$_totalResultados resultados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
        ),

        const SizedBox(height: 12),

        if (_viviendasEncontradas.isNotEmpty)
          _seccionResultados(
            titulo: 'Viviendas',
            icono: Icons.home,
            cantidad:
                _viviendasEncontradas.length,
            contenido:
                _viviendasEncontradas
                    .map(
                      _tarjetaVivienda,
                    )
                    .toList(),
          ),

        if (_familiasEncontradas.isNotEmpty)
          _seccionResultados(
            titulo: 'Familias',
            icono: Icons.family_restroom,
            cantidad:
                _familiasEncontradas.length,
            contenido:
                _familiasEncontradas
                    .map(
                      _tarjetaFamilia,
                    )
                    .toList(),
          ),

        if (_personasEncontradas.isNotEmpty)
          _seccionResultados(
            titulo: 'Personas',
            icono: Icons.person,
            cantidad:
                _personasEncontradas.length,
            contenido:
                _personasEncontradas
                    .map(
                      _tarjetaPersona,
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _seccionResultados({
    required String titulo,
    required IconData icono,
    required int cantidad,
    required List<Widget> contenido,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                cantidad.toString(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ...contenido,

        const SizedBox(height: 14),
      ],
    );
  }

  Widget _tarjetaVivienda(
    Vivienda vivienda,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(
            Icons.home,
          ),
        ),
        title: Text(
          vivienda.codigo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          vivienda.direccion.isEmpty
              ? 'Sin dirección registrada'
              : vivienda.direccion,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalleViviendaScreen(
                vivienda: vivienda,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaFamilia(
    Familia familia,
  ) {
    final vivienda =
        _obtenerVivienda(familia);

    final jefe =
        _obtenerJefe(familia);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(
            Icons.family_restroom,
          ),
        ),
        title: Text(
          jefe?.nombreApellido ??
              familia.codigo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${familia.codigo}'
          '${vivienda == null ? '' : ' • ${vivienda.direccion}'}',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalleFamiliaScreen(
                familia: familia,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaPersona(
    Persona persona,
  ) {
    final familia =
        _obtenerFamiliaDePersona(persona);

    final vivienda = familia == null
        ? null
        : _obtenerVivienda(familia);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(
            Icons.person,
          ),
        ),
        title: Text(
          persona.nombreApellido,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _subtituloPersona(
            persona,
            familia,
            vivienda,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () async {
          if (familia == null) {
            return;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalleFamiliaScreen(
                familia: familia,
              ),
            ),
          );
        },
      ),
    );
  }

  String _subtituloPersona(
    Persona persona,
    Familia? familia,
    Vivienda? vivienda,
  ) {
    final partes = <String>[];

    if (persona.cedula.isNotEmpty) {
      partes.add(
        'C.I. ${persona.cedula}',
      );
    }

    if (familia != null) {
      partes.add(
        familia.codigo,
      );
    }

    if (vivienda != null &&
        vivienda.direccion.isNotEmpty) {
      partes.add(
        vivienda.direccion,
      );
    }

    if (partes.isEmpty) {
      return 'Persona registrada';
    }

    return partes.join(' • ');
  }

  Widget _sinResultados() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Prueba con otro nombre, cédula, '
              'familia, calle o código de vivienda.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}