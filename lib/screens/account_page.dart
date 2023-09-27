import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dependants",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ListView.builder(
                            shrinkWrap: true,
                            itemCount: 2,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  "Dependant ${index + 1}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  "enfant",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }),
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
}
