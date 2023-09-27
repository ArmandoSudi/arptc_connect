import 'package:flutter/material.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({Key? key}) : super(key: key);

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {

  final agents = [
    "Agent 1",
    "Agent 2",
    "Agent 3",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Agents"),
        ),
        body: SafeArea(
            child: ListView.builder(
              itemCount: agents.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(agents[index]),
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
          onPressed: () {},
          child: const Icon(Icons.add),
        )
    );
  }
}
