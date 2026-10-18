import 'package:flutter/material.dart';
import '../busqueda/busqueda_screen.dart';
import '../estadisticas/dashboard_screen.dart';
import '../vivienda/viviendas_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() =>
      _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _indice = 0;

  final List<Widget> _pantallas = const [
    _InicioContenido(),
    ViviendasScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (index) {
          setState(() {
            _indice = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city),
            label: 'Viviendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}

class _InicioContenido extends StatelessWidget {
  const _InicioContenido();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Registro Belén'),
  actions: [
    IconButton(
      tooltip: 'Buscar',
      icon: const Icon(Icons.search),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const BusquedaScreen(),
          ),
        );
      },
    ),
  ],
),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.health_and_safety,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Registro Belén',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sistema de registro y censo comunitario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 35),
              _boton(
                context,
                icono: Icons.location_city,
                titulo: 'Viviendas',
                subtitulo:
                    'Registrar y consultar viviendas',
                destino: const ViviendasScreen(),
              ),
              const SizedBox(height: 14),
              _boton(
                context,
                icono: Icons.bar_chart,
                titulo: 'Estadísticas',
                subtitulo:
                    'Consultar estadísticas del censo',
                destino:
                    const DashboardScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boton(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: Icon(icono),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(subtitulo),
        trailing:
            const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destino,
            ),
          );
        },
      ),
    );
  }
}