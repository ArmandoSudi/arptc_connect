import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/content_view.dart';
import '../../../widgets/page_header.dart';

class MainServiceScreen extends StatelessWidget {
  MainServiceScreen({super.key});

  final services = [
    {"Social" : const Center(child: Text("Social"))},
    {"Inventory" : const Center(child: Text("Inventory"))},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ContentView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PageHeader(
                      title: 'Applications métiers',
                      description: '',
                    ),
                  ],
                ),
                const Gap(16),
                Expanded(
                  child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 5 / 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20),
                      itemCount: services.length,
                      itemBuilder: (BuildContext ctx, index) {
                        final service = services[index];
                        return InkWell(
                          child: Card(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  // color: Colors.tealAccent[100],
                                  borderRadius: BorderRadius.circular(15)),
                              child: Text(service.keys.first, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                            ),
                          ),
                          onTap: () {
                            context.go('/service/social');
                          },
                        );
                      }),
                ),
                // Column(
                //   children: [
                //     Card(
                //       clipBehavior: Clip.antiAlias,
                //       child: Padding(
                //         padding: const EdgeInsets.all(16.0),
                //         child: Row(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               const Icon(Icons.family_restroom, size: 50),
                //               Text(
                //                 "Social",
                //                 style: TextStyle(
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: 14,
                //                   color: Colors.grey[600],
                //                 ),
                //               ),
                //               const SizedBox(height: 10),
                //             ]),
                //       ),
                //     ),
                //   ],
                // ),
                const Gap(16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                  label: const Text("Retour"),
                )
              ]
          ),
        ));
  }
}
