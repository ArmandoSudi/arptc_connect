import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/dependant.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  final db = FirebaseFirestore.instance;

  CollectionReference dependants =
  FirebaseFirestore.instance.collection('/agents/PyKV8iGiDzcTdQSaRzWD/dependants');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // CircleAvatar(
                //   maxRadius: 50,
                //   backgroundImage:
                //   AssetImage("assets/images/cosplay_vj.jpg"),
                // )
                const SizedBox(height: 20, width: double.infinity),
                Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey[300]),
                    child: Icon(Icons.person, size: 70)),

                const SizedBox(height: 20),

                Text("John Doe", style: Theme.of(context).textTheme.titleLarge),
                Text("john.doe@arptc.gouv.cd",
                    style: Theme.of(context).textTheme.titleMedium),
                Text("08888888888888",
                    style: Theme.of(context).textTheme.titleMedium),

                const SizedBox(height: 20),

                const Row(
                  children: [
                    Text("Administration",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Direction",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text("Direction des systèmes d'information",
                            style: TextStyle(fontSize: 14)),
                        SizedBox(height: 10),
                        Text("Service",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                            "Service de devéloppement des applications et gestion de la base des données",
                            style: TextStyle(fontSize: 14)),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Row(
                  children: [
                    Text("Social",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dependants",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot>(
                            stream: dependants.snapshots(),
                            builder: (context, snapshot) {

                              if (snapshot.hasError) {
                                return const Text("something wen wrong");
                              }

                              if (snapshot.data == null || snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (!snapshot.hasData) {
                                return const Text("There is no dependant yet");
                              }
                              // print("Directions size : ${snapshot.data!.length}");
                              return _buildDependantList(context, snapshot.data?.docs ?? []);
                            }

                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text("Version : 0.0.1")
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDependantList( BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      shrinkWrap: true,
      children: snapshot.map((data) => _buildDepandant(context, data)).toList(),
    );
  }

  Widget _buildDepandant(BuildContext context, DocumentSnapshot data) {
    final dependant = Dependant.fromSnapshot(data);
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text("${dependant.name}"),
      subtitle: Text("${dependant.relationship}"),
      onTap: () {
        debugPrint("Doc ID: ${dependant.reference.id}");
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => DirectionDetailsScreen(),
        //   ),
        // );
      },
    );
  }
}
