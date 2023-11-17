import 'package:arptc_connect/modules/courrier/screens/add_courrier_screen.dart';
import 'package:flutter/material.dart';

import 'courrier_base_screen.dart';

class CourrierMainScreen extends StatefulWidget {
  const CourrierMainScreen({super.key});

  @override
  State<CourrierMainScreen> createState() => _CourrierMainScreenState();
}

class _CourrierMainScreenState extends State<CourrierMainScreen> {

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    CourrierBaseScreen(),
    Text(
      'Business Page',
      style: optionStyle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xF6F9FC),
      // backgroundColor: Colors.red,
      appBar: AppBar(
          title: Text("Gestion des courriers"),
        centerTitle: false,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Courriers'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Business'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (contxt) => AddCourrierScreen()));
        },

      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}