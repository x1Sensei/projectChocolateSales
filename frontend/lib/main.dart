import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.brown, 
      brightness: Brightness.light,
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final String serverIP = '192.168.10.29'; 
  
  int _selectedIndex = 0;
  bool isLoading = false;

  // --- DATOS DEL CSV (Mapeados para la UI) ---
  
  // Lista de Vendedores (Tal cual aparecen en el CSV)
  final List<String> salesPersons = [
    "Jehu Rudeforth",
    "Van Tuxwell",
    "Gigi Bohling",
    "Jan Morforth",
    "Oby Sorrel",
    "Gunar Cockshoot",
    "Brien Boise",
    "Husein Augar",
    "Mallorie Waber" 
  ];

  // Mapa de Países (Español -> CSV Original)
  final Map<String, String> countries = {
    "Reino Unido": "UK",
    "India": "India",
    "Australia": "Australia",
    "Nueva Zelanda": "New Zealand",
    "Canadá": "Canada",
    "USA": "USA"
  };

  // Mapa de Productos (Español/Nombre Bonito -> CSV Original)
  final Map<String, String> products = {
    "Choco Menta (Mint Chip)": "Mint Chip Choco",
    "Barra Oscura 85%": "85% Dark Bars",
    "Cubos Mantequilla Maní": "Peanut Butter Cubes",
    "Suave y Salado": "Smooth Sliky Salty",
    "Oscuro y Puro 99%": "99% Dark & Pure",
    "After Nines": "After Nines",
    "Bocados 50% Oscuro": "50% Dark Bites",
    "Chocolate Blanco": "White Choc",
    "Almendras": "Almond Choco",
    "Picante Especial": "Spicy Special Slims"
  };

  String? selectedCountry;
  String? selectedProduct;
  String? selectedPerson;
  final TextEditingController boxesController = TextEditingController();
  
  double? result;
  List history = [];

  // --- FUNCIONES ---

  Future<void> makePrediction() async {
    if (selectedPerson == null || selectedCountry == null || selectedProduct == null || boxesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor llena todos los campos")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://$serverIP:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "sales_person": selectedPerson,
          "country": countries[selectedCountry],
          "product": products[selectedProduct], 
          "boxes": boxesController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = double.parse(data['score'].toString());
        });
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('http://$serverIP:5000/history'));
      if (response.statusCode == 200) {
        setState(() => history = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error historial: $e");
    }
  }

  // --- INTERFAZ GRÁFICA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍫 Predicción Ventas Chocolates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.brown,
      ),
      body: _selectedIndex == 0 ? buildPredictTab() : buildHistoryTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 1) fetchHistory();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Predecir'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }

  Widget buildPredictTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Datos de la Venta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Vendedor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    value: selectedPerson,
                    items: salesPersons.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedPerson = v),
                  ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'País de Destino', border: OutlineInputBorder(), prefixIcon: Icon(Icons.public)),
                    value: selectedCountry,
                    items: countries.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedCountry = v),
                  ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.cookie)),
                    value: selectedProduct,
                    items: products.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedProduct = v),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: boxesController,
                    decoration: const InputDecoration(labelText: 'Cajas Enviadas', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                      onPressed: isLoading ? null : makePrediction,
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('CALCULAR VENTA ESTIMADA', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (result != null)
            Card(
              color: Colors.green.shade50,
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('PREDICCIÓN DE INGRESO:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    FittedBox(
                      child: Text(
                        '\$${result!.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                      )
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget buildHistoryTab() {
    if (history.isEmpty) {
      return const Center(child: Text("No hay predicciones recientes"));
    }
    return ListView.builder(
      itemCount: history.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (c, i) {
        final item = history[i];
        final datos = item['datos_entrada'] ?? {}; 
        
        // CORRECCIÓN AQUÍ: Convertimos a double y cortamos a 2 decimales
        final double venta = double.parse(item['venta_predicha'].toString());
        final String ventaFormateada = venta.toStringAsFixed(2); 

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.brown, 
              child: Icon(Icons.attach_money, color: Colors.white)
            ),
            // Aquí usamos la variable ya formateada
            title: Text('\$$ventaFormateada', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${datos['sales_person']} - ${datos['country']}\n${item['fecha']}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}