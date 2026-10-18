import 'package:flutter/material.dart';

import '../../models/familia.dart';
import '../../models/persona.dart';
import '../../services/firebase_service.dart';

class NuevaPersonaScreen extends StatefulWidget {
  final Familia familia;
  final bool esJefeFamilia;
  final Persona? persona;

  const NuevaPersonaScreen({
    super.key,
    required this.familia,
    this.esJefeFamilia = false,
    this.persona,
  });

  bool get esEdicion => persona != null;

  @override
  State<NuevaPersonaScreen> createState() =>
      _NuevaPersonaScreenState();
}

class _NuevaPersonaScreenState
    extends State<NuevaPersonaScreen> {
  final FirebaseService _firebaseService =
      FirebaseService();

  final _formKey = GlobalKey<FormState>();

 final _primerNombreController =
    TextEditingController();

final _segundoNombreController =
    TextEditingController();

final _primerApellidoController =
    TextEditingController();

final _segundoApellidoController =
    TextEditingController();

  final _cedulaController = TextEditingController();
  final _profesionController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _otraPatologiaController =
      TextEditingController();
  final _otroFactorRiesgoController =
      TextEditingController();

  DateTime? _fechaNacimiento;

  String _sexo = '';

  String _escolaridad = '';

  int _grupoDispensarial = 0;

  final Set<String> _patologiasSeleccionadas = {};

  final Set<String> _factoresRiesgoSeleccionados = {};

  bool _embarazada = false;

  int? _semanasGestacion;

  String? _estadoVacunacion;

  bool _guardando = false;

  @override
  void dispose() {
    _primerNombreController.dispose();
_segundoNombreController.dispose();
_primerApellidoController.dispose();
_segundoApellidoController.dispose();
    _cedulaController.dispose();
    _profesionController.dispose();
    _ocupacionController.dispose();
    _otraPatologiaController.dispose();
    _otroFactorRiesgoController.dispose();

    super.dispose();
  }

  int? get _edad {
    if (_fechaNacimiento == null) {
      return null;
    }

    final hoy = DateTime.now();

    int edad =
        hoy.year - _fechaNacimiento!.year;

    if (hoy.month < _fechaNacimiento!.month ||
        (hoy.month ==
                _fechaNacimiento!.month &&
            hoy.day < _fechaNacimiento!.day)) {
      edad--;
    }

    return edad;
  }

  bool get _esMujer =>
      _sexo.toLowerCase() == 'femenino';

  bool get _esNino {
    final edad = _edad;

    if (edad == null) {
      return false;
    }

    return edad < 12;
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaNacimiento = fecha;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      _mostrarError(
        'Seleccione la fecha de nacimiento.',
      );
      return;
    }

    if (_sexo.isEmpty) {
      _mostrarError('Seleccione el sexo.');
      return;
    }

    if (_grupoDispensarial == 0) {
      _mostrarError(
        'Seleccione el grupo dispensarial.',
      );
      return;
    }

    if (_embarazada &&
        _semanasGestacion == null) {
      _mostrarError(
        'Ingrese las semanas de gestación.',
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final patologias =
          _patologiasSeleccionadas.toList();

      if (_otraPatologiaController.text
          .trim()
          .isNotEmpty) {
        patologias.add(
          'otra: ${_otraPatologiaController.text.trim()}',
        );
      }

      final factoresRiesgo =
          _factoresRiesgoSeleccionados.toList();

      if (_otroFactorRiesgoController.text
          .trim()
          .isNotEmpty) {
        factoresRiesgo.add(
          'otro: ${_otroFactorRiesgoController.text.trim()}',
        );
      }

      final persona = Persona(
  id: widget.persona?.id ?? '',
  comunidadId:
      widget.familia.comunidadId,
  viviendaId:
      widget.familia.viviendaId,
  familiaId:
      widget.familia.id,
 primerNombre:
    _primerNombreController.text.trim(),

segundoNombre:
    _segundoNombreController.text.trim(),

primerApellido:
    _primerApellidoController.text.trim(),

segundoApellido:
    _segundoApellidoController.text.trim(),

  fechaNacimiento:
      _fechaNacimiento,
  sexo:
      _sexo,
  cedula:
      _cedulaController.text.trim(),
  escolaridad:
      _escolaridad,
  profesion:
      _profesionController.text.trim(),
  ocupacion:
      _ocupacionController.text.trim(),
  patologias:
      patologias,
  factoresRiesgo:
      factoresRiesgo,
  grupoDispensarial:
      _grupoDispensarial,
  embarazada:
      _embarazada,
  semanasGestacion:
      _embarazada
          ? _semanasGestacion
          : null,
  estadoVacunacion:
      _esNino
          ? _estadoVacunacion
          : null,
  esJefeFamilia:
      widget.persona?.esJefeFamilia ??
      widget.esJefeFamilia,
);

     String personaId;

if (widget.esEdicion) {
  await _firebaseService.actualizarPersona(
    persona.id,
    persona,
  );

  personaId = persona.id;
} else {
  personaId =
      await _firebaseService.crearPersona(
    persona,
  );
}

      if (!mounted) return;

      Navigator.pop(context, personaId);
    } catch (e) {
      if (!mounted) return;

      _mostrarError(
        'Error al guardar la persona: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
  widget.esEdicion
      ? 'Editar persona'
      : widget.esJefeFamilia
          ? 'Jefe de familia'
          : 'Agregar integrante',
),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seccion(
              'Datos personales',
              Icons.person,
            ),

           TextFormField(
  controller: _primerNombreController,
  textCapitalization:
      TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Primer nombre',
    prefixIcon: Icon(Icons.person),
  ),
  validator: (value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingrese el primer nombre';
    }

    return null;
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: _segundoNombreController,
  textCapitalization:
      TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Segundo nombre',
    prefixIcon: Icon(Icons.person_outline),
  ),
),

const SizedBox(height: 12),

TextFormField(
  controller: _primerApellidoController,
  textCapitalization:
      TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Primer apellido',
    prefixIcon: Icon(Icons.badge),
  ),
  validator: (value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Ingrese el primer apellido';
    }

    return null;
  },
),

const SizedBox(height: 12),

TextFormField(
  controller: _segundoApellidoController,
  textCapitalization:
      TextCapitalization.words,
  decoration: const InputDecoration(
    labelText: 'Segundo apellido',
    prefixIcon: Icon(Icons.badge_outlined),
  ),
),

            const SizedBox(height: 12),

            InkWell(
              onTap:
                  _seleccionarFechaNacimiento,
              child: InputDecorator(
                decoration:
                    const InputDecoration(
                  labelText:
                      'Fecha de nacimiento',
                  border:
                      OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.calendar_month),
                ),
                child: Text(
                  _fechaNacimiento == null
                      ? 'Seleccione una fecha'
                      : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/'
                          '${_fechaNacimiento!.month.toString().padLeft(2, '0')}/'
                          '${_fechaNacimiento!.year}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            InputDecorator(
              decoration:
                  const InputDecoration(
                labelText: 'Edad',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.cake),
              ),
              child: Text(
                _edad == null
                    ? 'Se calculará automáticamente'
                    : '${_edad!} años',
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue:
                  _sexo.isEmpty ? null : _sexo,
              decoration:
                  const InputDecoration(
                labelText: 'Sexo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'masculino',
                  child:
                      Text('Masculino'),
                ),
                DropdownMenuItem(
                  value: 'femenino',
                  child:
                      Text('Femenino'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _sexo = value ?? '';

                  if (_sexo !=
                      'femenino') {
                    _embarazada = false;
                    _semanasGestacion =
                        null;
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _cedulaController,
              decoration:
                  const InputDecoration(
                labelText: 'Cédula',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.badge),
              ),
              keyboardType:
                  TextInputType.number,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue:
                  _escolaridad.isEmpty
                      ? null
                      : _escolaridad,
              decoration:
                  const InputDecoration(
                labelText: 'Escolaridad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ninguna',
                  child:
                      Text('Ninguna'),
                ),
                DropdownMenuItem(
                  value: 'primaria',
                  child:
                      Text('Primaria'),
                ),
                DropdownMenuItem(
                  value: 'Bachiller',
                  child:
                      Text('Bachiller'),
                ),
                DropdownMenuItem(
                  value: 'tecnico',
                  child:
                      Text('Técnico'),
                ),
                DropdownMenuItem(
                  value: 'universitaria',
                  child:
                      Text('Universitaria'),
                ),
                DropdownMenuItem(
                  value: 'otra',
                  child:
                      Text('Otra'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _escolaridad =
                      value ?? '';
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  _profesionController,
              decoration:
                  const InputDecoration(
                labelText: 'Profesión',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  _ocupacionController,
              decoration:
                  const InputDecoration(
                labelText: 'Ocupación',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            _seccion(
              'Patologías',
              Icons.medical_services,
            ),

            _checkPatologia(
              'hipertension',
              'Hipertensión',
            ),
            _checkPatologia(
              'diabetes',
              'Diabetes',
            ),
            _checkPatologia(
              'asma',
              'Asma',
            ),
            _checkPatologia(
              'epilepsia',
              'Epilepsia',
            ),
            _checkPatologia(
              'cardiopatias',
              'Cardiopatías',
            ),
            _checkPatologia(
              'discapacidad',
              'Discapacidad',
            ),
            _checkPatologia(
              'otras',
              'Otras',
            ),

            if (_patologiasSeleccionadas
                .contains('otras'))
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                ),
                child: TextField(
                  controller:
                      _otraPatologiaController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Especifique otra patología',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            _seccion(
              'Factores de riesgo',
              Icons.warning_amber,
            ),

            _checkFactor(
              'tabaquismo',
              'Tabaquismo',
            ),
            _checkFactor(
              'alcoholismo',
              'Alcoholismo',
            ),
            _checkFactor(
              'drogas',
              'Drogas',
            ),
            _checkFactor(
              'sedentarismo',
              'Sedentarismo',
            ),
            _checkFactor(
              'obesidad',
              'Obesidad',
            ),
            _checkFactor(
              'otros',
              'Otros',
            ),

            if (_factoresRiesgoSeleccionados
                .contains('otros'))
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                ),
                child: TextField(
                  controller:
                      _otroFactorRiesgoController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Especifique otro factor',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            _seccion(
              'Grupo dispensarial',
              Icons.health_and_safety,
            ),

           DropdownButtonFormField<int>(
  initialValue: _grupoDispensarial == 0
      ? null
      : _grupoDispensarial,
  decoration: const InputDecoration(
    labelText: 'Grupo dispensarial',
    border: OutlineInputBorder(),
    prefixIcon: Icon(
      Icons.health_and_safety,
    ),
  ),
  items: const [
    DropdownMenuItem<int>(
      value: 1,
      child: Text(
        'Grupo I — Aparentemente sano',
      ),
    ),
    DropdownMenuItem<int>(
      value: 2,
      child: Text(
        'Grupo II — Con riesgo',
      ),
    ),
    DropdownMenuItem<int>(
      value: 3,
      child: Text(
        'Grupo III — Enfermo',
      ),
    ),
    DropdownMenuItem<int>(
      value: 4,
      child: Text(
        'Grupo IV — Discapacidad',
      ),
    ),
  ],
  onChanged: (value) {
    if (value == null) return;

    setState(() {
      _grupoDispensarial = value;
    });
  },
  validator: (value) {
    if (value == null) {
      return 'Seleccione el grupo dispensarial';
    }

    return null;
  },
),

            if (_esMujer) ...[
              const SizedBox(height: 24),

              _seccion(
                'Embarazo',
                Icons.pregnant_woman,
              ),

              SwitchListTile(
                title: const Text(
                  '¿Está embarazada?',
                ),
                value: _embarazada,
                onChanged: (value) {
                  setState(() {
                    _embarazada = value;

                    if (!value) {
                      _semanasGestacion =
                          null;
                    }
                  });
                },
              ),

              if (_embarazada)
                DropdownButtonFormField<int>(
                  initialValue:
                      _semanasGestacion,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Semanas de gestación',
                    border:
                        OutlineInputBorder(),
                  ),
                  items: List.generate(
                    41,
                    (index) =>
                        DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        '$index semanas',
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _semanasGestacion =
                          value;
                    });
                  },
                ),
            ],

            if (_esNino) ...[
              const SizedBox(height: 24),

              _seccion(
                'Vacunación',
                Icons.vaccines,
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    _estadoVacunacion,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Estado de vacunación',
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'completa',
                    child: Text(
                      'Esquema completo',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'incompleta',
                    child: Text(
                      'Esquema incompleto',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'no_vacunado',
                    child: Text(
                      'No vacunado',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'no_verificado',
                    child: Text(
                      'No verificado',
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _estadoVacunacion =
                        value;
                  });
                },
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _guardando
                        ? null
                        : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Guardar persona',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(
    String titulo,
    IconData icono,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
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
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkPatologia(
    String valor,
    String titulo,
  ) {
    return CheckboxListTile(
      title: Text(titulo),
      value: _patologiasSeleccionadas
          .contains(valor),
      onChanged: (seleccionado) {
        setState(() {
          if (seleccionado == true) {
            _patologiasSeleccionadas
                .add(valor);
          } else {
            _patologiasSeleccionadas
                .remove(valor);
          }
        });
      },
      controlAffinity:
          ListTileControlAffinity.leading,
    );
  }

  Widget _checkFactor(
    String valor,
    String titulo,
  ) {
    return CheckboxListTile(
      title: Text(titulo),
      value: _factoresRiesgoSeleccionados
          .contains(valor),
      onChanged: (seleccionado) {
        setState(() {
          if (seleccionado == true) {
            _factoresRiesgoSeleccionados
                .add(valor);
          } else {
            _factoresRiesgoSeleccionados
                .remove(valor);
          }
        });
      },
      controlAffinity:
          ListTileControlAffinity.leading,
    );
  }

@override
void initState() {
  super.initState();

  if (widget.persona != null) {
    _cargarDatosPersona(widget.persona!);
  }
}
  void _cargarDatosPersona(Persona persona) {
 _primerNombreController.text =
    persona.primerNombre;

_segundoNombreController.text =
    persona.segundoNombre;

_primerApellidoController.text =
    persona.primerApellido;

_segundoApellidoController.text =
    persona.segundoApellido;

  _cedulaController.text =
      persona.cedula;

  _profesionController.text =
      persona.profesion;

  _ocupacionController.text =
      persona.ocupacion;

  _fechaNacimiento =
      persona.fechaNacimiento;

  _sexo = persona.sexo;

  _escolaridad =
      persona.escolaridad;

  _grupoDispensarial =
      persona.grupoDispensarial;

  _patologiasSeleccionadas
    ..clear()
    ..addAll(persona.patologias);

  _factoresRiesgoSeleccionados
    ..clear()
    ..addAll(persona.factoresRiesgo);

  _embarazada =
      persona.embarazada;

  _semanasGestacion =
      persona.semanasGestacion;

  _estadoVacunacion =
      persona.estadoVacunacion;
}


}