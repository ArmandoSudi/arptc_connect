import 'package:flutter/material.dart';

import 'add_bureau_screen.dart';

class BureauxScreen extends StatelessWidget {

  BureauxScreen({Key? key}) : super(key: key);

  final bureaux = [
    "Bureau Webmaster",
    "Bureau Téléphonie et Messagerie",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Bureaux"),
        ),
        body: SafeArea(
            child: ListView.builder(
              itemCount: bureaux.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(bureaux[index]),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: (){
                    // Navigator
                    //     .of(context)
                    //     .push(MaterialPageRoute(builder: context) => DirectionsScreen());
                  },
                );
              },
            )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddBureauScreen())),
          child: const Icon(Icons.add),
        )
    );
  }
}
