import 'package:flutter/material.dart';

import '../../models/vivienda.dart';
import '../../services/firebase_service.dart';

class PruebaFirestoreScreen extends StatefulWidget {
  const PruebaFirestoreScreen({super.key});

  @override
  State<PruebaFirestoreScreen> createState() =>
      _PruebaFirestoreScreenState();
}

class _PruebaFirestoreScreenState
    extends State<PruebaFirestoreScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _cargando = false;
  String _mensaje = '';

  Future<void> _crearViviendaPrueba() async {
    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final vivienda = Vivienda(
        id: '',
        comunidadId: 'comunidad_prueba',
        codigo: 'CASA-001',
        direccion: 'Dirección de prueba',
        tieneLuz: true,
        tieneAgua: true,
        gasLena: 'Gas',
        tieneBanoSanitario: true,
        material: 'Bloque',
        techo: 'Zinc',
        piso: 'Cemento',
        higiene: 'Buena',
        animales: {},
      );

      final id = await _firebaseService.crearVivienda(vivienda);

      setState(() {
        _mensaje = 'Vivienda creada correctamente.\nID: $id';
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error: $e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Firestore'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Registro Belén',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed:
                    _cargando ? null : _crearViviendaPrueba,
                child: _cargando
                    ? const CircularProgressIndicator()
                    : const Text('Crear CASA-001'),
              ),
              const SizedBox(height: 20),
              Text(
                _mensaje,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}