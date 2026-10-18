import 'package:flutter/material.dart';
import '../familia/nueva_familia_screen.dart';
import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';

class NuevaViviendaScreen extends StatefulWidget {
  final Vivienda? vivienda;

  const NuevaViviendaScreen({
    super.key,
    this.vivienda,
  });

  bool get esEdicion => vivienda != null;

  @override
  State<NuevaViviendaScreen> createState() =>
      _NuevaViviendaScreenState();
}

class _NuevaViviendaScreenState
    extends State<NuevaViviendaScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final _formKey = GlobalKey<FormState>();

  final _direccionController = TextEditingController();
  final _higieneController = TextEditingController();

  bool _tieneLuz = false;
  bool _tieneAgua = false;
  bool _tieneBanoSanitario = false;

  String _gasLena = 'Ninguno';

  String _material = '';
  String _techo = '';
  String _piso = '';

  final Map<String, int> _animales = {};

  String _codigo = '';
  bool _cargando = true;
  bool _guardando = false;

@override
void initState() {
  super.initState();

  if (widget.vivienda != null) {
    _cargarDatosVivienda(widget.vivienda!);
  } else {
    _generarCodigo();
  }
}


  @override
  void dispose() {
    _direccionController.dispose();
    _higieneController.dispose();
    super.dispose();
  }

  Future<void> _generarCodigo() async {
    try {
      final codigo =
          await _firebaseService.generarCodigoVivienda();

      if (!mounted) return;

      setState(() {
        _codigo = codigo;
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
            'No se pudo generar el código: $e',
          ),
        ),
      );
    }
  }

void _cargarDatosVivienda(Vivienda vivienda) {
  _direccionController.text = vivienda.direccion;

  _higieneController.text = vivienda.higiene;

  _tieneLuz = vivienda.tieneLuz;
  _tieneAgua = vivienda.tieneAgua;
  _tieneBanoSanitario = vivienda.tieneBanoSanitario;

  _gasLena = vivienda.gasLena;

  _material = vivienda.material;
  _techo = vivienda.techo;
  _piso = vivienda.piso;

  _codigo = vivienda.codigo;

  _animales
    ..clear()
    ..addAll(vivienda.animales);

  _cargando = false;
}

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _guardando = true;
  });

  try {
    final vivienda = Vivienda(
      id: widget.vivienda?.id ?? '',
      comunidadId:
          widget.vivienda?.comunidadId ??
              'comunidad_prueba',
      codigo: _codigo,
      direccion:
          _direccionController.text.trim(),
      tieneLuz: _tieneLuz,
      tieneAgua: _tieneAgua,
      gasLena: _gasLena,
      tieneBanoSanitario:
          _tieneBanoSanitario,
      material: _material,
      techo: _techo,
      piso: _piso,
      higiene:
          _higieneController.text.trim(),
      animales:
          Map<String, int>.from(_animales),
      fechaRegistro:
          widget.vivienda?.fechaRegistro,
    );

    String viviendaId;

    if (widget.esEdicion) {
      await _firebaseService.actualizarVivienda(
        vivienda.id,
        vivienda,
      );

      viviendaId = vivienda.id;
    } else {
      viviendaId =
          await _firebaseService.crearVivienda(
        vivienda,
      );
    }

    if (!mounted) return;

    // ========================================================
    // EDICIÓN
    // ========================================================

    if (widget.esEdicion) {
      Navigator.pop(
        context,
        viviendaId,
      );

      return;
    }

    // ========================================================
    // NUEVA VIVIENDA
    // ========================================================

    final viviendaGuardada = Vivienda(
      id: viviendaId,
      comunidadId: vivienda.comunidadId,
      codigo: vivienda.codigo,
      direccion: vivienda.direccion,
      tieneLuz: vivienda.tieneLuz,
      tieneAgua: vivienda.tieneAgua,
      gasLena: vivienda.gasLena,
      tieneBanoSanitario:
          vivienda.tieneBanoSanitario,
      material: vivienda.material,
      techo: vivienda.techo,
      piso: vivienda.piso,
      higiene: vivienda.higiene,
      animales:
          Map<String, int>.from(
        vivienda.animales,
      ),
      fechaRegistro:
          vivienda.fechaRegistro,
    );

    final familiaCreada =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NuevaFamiliaScreen(
          vivienda: viviendaGuardada,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      familiaCreada ?? viviendaId,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Error al guardar la vivienda: $e',
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

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
  widget.esEdicion
      ? 'Editar vivienda'
      : 'Nueva vivienda',
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
        ? 'Editar vivienda'
        : 'Nueva vivienda',
  ),
),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tituloSeccion(
              'Identificación',
              Icons.home,
            ),

            _campoCodigo(),

            const SizedBox(height: 12),

            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Ingrese la dirección';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            _tituloSeccion(
              'Servicios básicos',
              Icons.water_drop,
            ),

            SwitchListTile(
              title: const Text('Electricidad'),
              value: _tieneLuz,
              onChanged: (value) {
                setState(() {
                  _tieneLuz = value;
                });
              },
            ),

            SwitchListTile(
              title: const Text('Agua'),
              value: _tieneAgua,
              onChanged: (value) {
                setState(() {
                  _tieneAgua = value;
                });
              },
            ),

            DropdownButtonFormField<String>(
  initialValue: _gasLena,
              decoration: const InputDecoration(
                labelText: 'Gas / Leña',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Ninguno',
                  child: Text('Ninguno'),
                ),
                DropdownMenuItem(
                  value: 'Gas',
                  child: Text('Gas'),
                ),
                DropdownMenuItem(
                  value: 'Leña',
                  child: Text('Leña'),
                ),
                DropdownMenuItem(
                  value: 'Ambos',
                  child: Text('Ambos'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _gasLena = value;
                });
              },
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Baño sanitario'),
              value: _tieneBanoSanitario,
              onChanged: (value) {
                setState(() {
                  _tieneBanoSanitario = value;
                });
              },
            ),

            const SizedBox(height: 24),

            _tituloSeccion(
              'Condiciones de la vivienda',
              Icons.house,
            ),

            DropdownButtonFormField<String>(
              initialValue: _material.isEmpty ? null : _material,
              decoration: const InputDecoration(
                labelText: 'Material de la vivienda',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Bloque',
                  child: Text('Bloque'),
                ),
                DropdownMenuItem(
                  value: 'Ladrillo',
                  child: Text('Ladrillo'),
                ),
                DropdownMenuItem(
                  value: 'Madera',
                  child: Text('Madera'),
                ),
                DropdownMenuItem(
                  value: 'Bahareque',
                  child: Text('Bahareque'),
                ),
                DropdownMenuItem(
                  value: 'Otro',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _material = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione el material';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _techo.isEmpty ? null : _techo,
              decoration: const InputDecoration(
                labelText: 'Techo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Zinc',
                  child: Text('Zinc'),
                ),
                DropdownMenuItem(
                  value: 'Tejas',
                  child: Text('Tejas'),
                ),
                DropdownMenuItem(
                  value: 'Concreto',
                  child: Text('Concreto'),
                ),
                DropdownMenuItem(
                  value: 'Otro',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _techo = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione el techo';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _piso.isEmpty ? null : _piso,
              decoration: const InputDecoration(
                labelText: 'Piso',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Cemento',
                  child: Text('Cemento'),
                ),
                DropdownMenuItem(
                  value: 'Cerámica',
                  child: Text('Cerámica'),
                ),
                DropdownMenuItem(
                  value: 'Tierra',
                  child: Text('Tierra'),
                ),
                DropdownMenuItem(
                  value: 'Otro',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _piso = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleccione el piso';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            _tituloSeccion(
              'Higiene del hogar',
              Icons.cleaning_services,
            ),

            TextFormField(
              controller: _higieneController,
              decoration: const InputDecoration(
                labelText: 'Condiciones de higiene',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            _tituloSeccion(
              'Animales',
              Icons.pets,
            ),

            _animalSelector('Perros'),
            _animalSelector('Gatos'),
            _animalSelector('Aves'),
            _animalSelector('Cerdos'),
            _animalSelector('Ganado'),
            _animalSelector('Otros'),

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Guardar vivienda',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(
    String titulo,
    IconData icono,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
        ],
      ),
    );
  }

  Widget _campoCodigo() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Código de vivienda',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.tag),
      ),
      child: Text(
        _codigo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _animalSelector(String animal) {
    final cantidad = _animales[animal] ?? 0;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.pets),
        title: Text(animal),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: cantidad > 0
                  ? () {
                      setState(() {
                        if (cantidad == 1) {
                          _animales.remove(animal);
                        } else {
                          _animales[animal] =
                              cantidad - 1;
                        }
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 30,
              child: Text(
                '$cantidad',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _animales[animal] =
                      cantidad + 1;
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}