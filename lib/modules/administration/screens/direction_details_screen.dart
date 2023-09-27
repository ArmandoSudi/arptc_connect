import 'dart:developer';

import 'package:flutter/material.dart';

class DirectionDetailsScreen extends StatefulWidget {
  const DirectionDetailsScreen({Key? key}) : super(key: key);

  @override
  State<DirectionDetailsScreen> createState() => _DirectionDetailsScreenState();
}

class _DirectionDetailsScreenState extends State<DirectionDetailsScreen> {
  bool isServiceExpanded = false;
  bool isAgentExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text("Directions"),
          actions: [
            const IconButton(onPressed: null, icon: Icon(Icons.edit))
          ],
        ),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Direction des systèmes d'information",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Services",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.keyboard_arrow_down_rounded),
                                    onPressed: () {
                                      setState(() {
                                        isServiceExpanded = !isServiceExpanded;
                                      });
                                    },
                                  )
                                ],
                              ),
                              SizedBox(height: 20),
                              isServiceExpanded
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: 3,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text("Service $index"),
                                        );
                                      })
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Agents",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                    onPressed: () {
                                      setState(() {
                                        isAgentExpanded = !isAgentExpanded;
                                      });
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              isAgentExpanded
                                  ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text("Agent $index"),
                                    );
                                  })
                                  : Container(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 10,
                left: 10,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.red),
                  onPressed: () {
                    log("direction_details_screen:: delete");
                  },
                  child: const Text("delete"),
                ),
              )
            ],
          ),
        ));
  }
}
