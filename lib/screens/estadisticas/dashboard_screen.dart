import 'package:flutter/material.dart';

import '../../services/estadisticas_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final EstadisticasService _service =
      EstadisticasService();

  bool _cargando = true;

  int _poblacion = 0;

Map<String, int> _sexo = {};

Map<String, int> _escolaridad = {};

List<Map<String, dynamic>> _edadSexo = [];

int _totalEdadSexo = 0;

int _totalNinos = 0;

int _totalMujeres = 0;

int _totalViviendas = 0;

int _totalFamilias = 0;

Map<String, int> _distribucionFamilias =
    {};

  Map<String, int> _edades = {};

  Map<String, int> _vacunacion = {};

  Map<String, int> _embarazo = {};

  Map<String, int> _patologias = {};

  Map<String, int> _factoresRiesgo = {};

  Map<String, int> _gruposDispensariales = {};

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    try {
final resultados =
    await Future.wait([
  _service.poblacionTotal(),
  _service.distribucionSexo(),
  _service.distribucionEdades(),
  _service.distribucionEscolaridad(),
  _service.distribucionEdadSexo(),
  _service.totalPersonasEdadSexo(),
  _service.estadisticasVacunacion(),
  _service.estadisticasEmbarazo(),
  _service.estadisticasPatologias(),
  _service.estadisticasFactoresRiesgo(),
  _service.estadisticasGruposDispensariales(),
  _service.totalViviendas(),
  _service.totalFamilias(),
  _service.distribucionFamiliasPorVivienda(),
  _service.totalNinos(),
  _service.totalMujeres(),
]);

      if (!mounted) return;

     setState(() {
  _poblacion =
      resultados[0] as int;

  _sexo =
      resultados[1] as Map<String, int>;

  _edades =
      resultados[2] as Map<String, int>;

  _escolaridad =
      resultados[3] as Map<String, int>;

  _edadSexo =
      (resultados[4] as List)
          .cast<Map<String, dynamic>>();

  _totalEdadSexo =
      resultados[5] as int;

  _vacunacion =
      resultados[6] as Map<String, int>;

  _embarazo =
      resultados[7] as Map<String, int>;

  _patologias =
      resultados[8] as Map<String, int>;

  _factoresRiesgo =
      resultados[9] as Map<String, int>;

  _gruposDispensariales =
      resultados[10] as Map<String, int>;

  _totalViviendas =
      resultados[11] as int;

  _totalFamilias =
      resultados[12] as int;

  _distribucionFamilias =
      resultados[13] as Map<String, int>;

  _totalNinos =
      resultados[14] as int;

  _totalMujeres =
      resultados[15] as int;

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
            'Error al cargar estadísticas: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            _tarjetaPoblacion(),

const SizedBox(height: 16),

_tarjetaComunidad(),

            const SizedBox(height: 16),

           _tarjetaEdades(),

const SizedBox(height: 16),

_tarjetaEdadSexo(),

const SizedBox(height: 16),

_tarjetaEscolaridad(),

const SizedBox(height: 16),

            _tarjetaVacunacion(),

            const SizedBox(height: 16),

            _tarjetaEmbarazo(),

           const SizedBox(height: 16),

_tarjetaPatologias(),

const SizedBox(height: 16),

_tarjetaSexo(),

const SizedBox(height: 16),

_tarjetaFactoresRiesgo(),

const SizedBox(height: 16),

_tarjetaGruposDispensariales(),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaPoblacion() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.groups,
              size: 45,
            ),
            const SizedBox(height: 10),
            const Text(
              'Población total',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$_poblacion',
              style: const TextStyle(
                fontSize: 36,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _tarjetaSexo() {
  final femenino = _sexo['femenino'] ?? 0;
  final masculino = _sexo['masculino'] ?? 0;

  return _tarjetaSeccion(
    'Distribución por sexo',
    Icons.people,
    [
      _filaEstadistica(
        'Femenino',
        femenino,
        _poblacion,
      ),
      _filaEstadistica(
        'Masculino',
        masculino,
        _poblacion,
      ),
    ],
  );
}

Widget _tarjetaComunidad() {
  final total =
      _totalViviendas;

  return _tarjetaSeccion(
    'Resumen comunitario',
    Icons.location_city,
    [
      _filaEstadistica(
        'Viviendas censadas',
        _totalViviendas,
        total,
      ),
      Padding(
  padding:
      const EdgeInsets.symmetric(
    vertical: 8,
  ),
  child: Row(
    children: [
      const Expanded(
        child: Text(
          'Familias registradas',
        ),
      ),
      Text(
        '$_totalFamilias',
        style: const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
    ],
  ),
),

      _filaEstadistica(
        'Viviendas con una familia',
        _distribucionFamilias[
                'unaFamilia'] ??
            0,
        total,
      ),
      _filaEstadistica(
        'Viviendas con varias familias',
        _distribucionFamilias[
                'variasFamilias'] ??
            0,
        total,
      ),
      _filaEstadistica(
        'Viviendas sin familia',
        _distribucionFamilias[
                'sinFamilia'] ??
            0,
        total,
      ),
    ],
  );
}

  Widget _tarjetaEdades() {
    final total =
        _edades.values.fold(
      0,
      (a, b) => a + b,
    );

    return _tarjetaSeccion(
      'Distribución por edad',
      Icons.people,
      [
        _filaEstadistica(
          'Niños',
          _edades['ninos'] ?? 0,
          total,
        ),
        _filaEstadistica(
          'Adolescentes',
          _edades['adolescentes'] ?? 0,
          total,
        ),
        _filaEstadistica(
          'Adultos',
          _edades['adultos'] ?? 0,
          total,
        ),
        _filaEstadistica(
          'Adultos mayores',
          _edades['adultosMayores'] ?? 0,
          total,
        ),
      ],
    );
  }

Widget _tarjetaEscolaridad() {
  return _tarjetaSeccion(
    'Distribución por escolaridad',
    Icons.school,
    [
      _filaEstadistica(
        'Ninguna',
        _escolaridad['ninguna'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Primaria',
        _escolaridad['primaria'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Bachiller',
        _escolaridad['Bachiller'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Técnico',
        _escolaridad['tecnico'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Universitaria',
        _escolaridad['universitaria'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Otra',
        _escolaridad['otra'] ?? 0,
        _poblacion,
      ),
    ],
  );
}

Widget _tarjetaEdadSexo() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Distribución de la población por edad y sexo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(),

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 45,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 55,
              columns: const [
                DataColumn(
                  label: Text('Grupo etario'),
                ),
                DataColumn(
                  label: Text('Masc.'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('%'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Fem.'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('%'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Total'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('%'),
                  numeric: true,
                ),
              ],
              rows: [
                ..._edadSexo.map(
                  (fila) {
                    final masculino =
                        fila['masculino']
                            as int;

                    final femenino =
                        fila['femenino']
                            as int;

                    final total =
                        fila['total'] as int;

                    final porcentajeMasculino =
                        EstadisticasService
                            .calcularPorcentaje(
                      masculino,
                      _totalEdadSexo,
                    );

                    final porcentajeFemenino =
                        EstadisticasService
                            .calcularPorcentaje(
                      femenino,
                      _totalEdadSexo,
                    );

                    final porcentajeTotal =
                        EstadisticasService
                            .calcularPorcentaje(
                      total,
                      _totalEdadSexo,
                    );

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            fila['grupo']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Text(
                            '$masculino',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${porcentajeMasculino.toStringAsFixed(2)}%',
                          ),
                        ),
                        DataCell(
                          Text(
                            '$femenino',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${porcentajeFemenino.toStringAsFixed(2)}%',
                          ),
                        ),
                        DataCell(
                          Text(
                            '$total',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${porcentajeTotal.toStringAsFixed(2)}%',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                DataRow(
                  cells: [
                    const DataCell(
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_edadSexo.fold<int>(
                          0,
                          (suma, fila) =>
                              suma +
                              (fila['masculino']
                                  as int),
                        )}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${EstadisticasService.calcularPorcentaje(
                          _edadSexo.fold<int>(
                            0,
                            (suma, fila) =>
                                suma +
                                (fila['masculino']
                                    as int),
                          ),
                          _totalEdadSexo,
                        ).toStringAsFixed(2)}%',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_edadSexo.fold<int>(
                          0,
                          (suma, fila) =>
                              suma +
                              (fila['femenino']
                                  as int),
                        )}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${EstadisticasService.calcularPorcentaje(
                          _edadSexo.fold<int>(
                            0,
                            (suma, fila) =>
                                suma +
                                (fila['femenino']
                                    as int),
                          ),
                          _totalEdadSexo,
                        ).toStringAsFixed(2)}%',
                      ),
                    ),
                    DataCell(
                      Text(
                        '$_totalEdadSexo',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    const DataCell(
                      Text(
                        '100.00%',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _tarjetaVacunacion() {
  final total = _totalNinos;

  return _tarjetaSeccion(
    'Vacunación infantil',
    Icons.vaccines,
    [
      _filaEstadistica(
        'Esquema completo',
        _vacunacion['completa'] ?? 0,
        total,
      ),

      _filaEstadistica(
        'Esquema incompleto',
        _vacunacion['incompleta'] ?? 0,
        total,
      ),

      _filaEstadistica(
        'No vacunado',
        _vacunacion['no_vacunado'] ?? 0,
        total,
      ),

      _filaEstadistica(
        'No verificado',
        _vacunacion['no_verificado'] ?? 0,
        total,
      ),
    ],
  );
}

 Widget _tarjetaEmbarazo() {
  final embarazadas =
      _embarazo['embarazadas'] ?? 0;

  final mujeres = _totalMujeres;

  return _tarjetaSeccion(
    'Embarazo',
    Icons.pregnant_woman,
    [
      _filaEstadistica(
        'Mujeres',
        mujeres,
        _poblacion,
      ),

      _filaEstadistica(
        'Embarazadas',
        embarazadas,
        mujeres,
      ),

      _filaEstadistica(
        'Óptimo por edad',
        _embarazo['optimo'] ?? 0,
        embarazadas,
      ),

      _filaEstadistica(
        'Riesgo por edad',
        _embarazo['riesgo'] ?? 0,
        embarazadas,
      ),
    ],
  );
}

  Widget _tarjetaSeccion(
    String titulo,
    IconData icono,
    List<Widget> filas,
  ) {
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
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),
                const SizedBox(width: 8),
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
            ),
            const Divider(),
            ...filas,
          ],
        ),
      ),
    );
  }

Widget _tarjetaPatologias() {
  return _tarjetaSeccion(
    'Patologías',
    Icons.medical_services,
    [
      _filaEstadistica(
        'Hipertensión',
        _patologias['hipertension'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Diabetes',
        _patologias['diabetes'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Asma',
        _patologias['asma'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Epilepsia',
        _patologias['epilepsia'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Cardiopatías',
        _patologias['cardiopatias'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Discapacidad',
        _patologias['discapacidad'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Otras',
        _patologias['otras'] ?? 0,
        _poblacion,
      ),
    ],
  );
}

Widget _tarjetaFactoresRiesgo() {
  return _tarjetaSeccion(
    'Factores de riesgo',
    Icons.warning_amber,
    [
      _filaEstadistica(
        'Tabaquismo',
        _factoresRiesgo['tabaquismo'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Alcoholismo',
        _factoresRiesgo['alcoholismo'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Drogas',
        _factoresRiesgo['drogas'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Sedentarismo',
        _factoresRiesgo['sedentarismo'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Obesidad',
        _factoresRiesgo['obesidad'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Otros',
        _factoresRiesgo['otros'] ?? 0,
        _poblacion,
      ),
    ],
  );
}

Widget _tarjetaGruposDispensariales() {
  return _tarjetaSeccion(
    'Grupos dispensariales',
    Icons.health_and_safety,
    [
      _filaEstadistica(
        'Grupo I',
        _gruposDispensariales['grupo1'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Grupo II',
        _gruposDispensariales['grupo2'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Grupo III',
        _gruposDispensariales['grupo3'] ?? 0,
        _poblacion,
      ),
      _filaEstadistica(
        'Grupo IV',
        _gruposDispensariales['grupo4'] ?? 0,
        _poblacion,
      ),
    ],
  );
}


  Widget _filaEstadistica(
    String titulo,
    int cantidad,
    int total,
  ) {
    final porcentaje =
        EstadisticasService
            .calcularPorcentaje(
      cantidad,
      total,
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                ),
              ),
              Text(
                '$cantidad',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${porcentaje.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: porcentaje / 100,
          ),
        ],
      ),
    );
  }
}