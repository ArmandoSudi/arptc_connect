import 'dart:developer';

import 'package:arptc_connect/modules/administration/presentation/controllers/async_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';

class UsersSreen extends ConsumerStatefulWidget {
  const UsersSreen({super.key});

  @override
  ConsumerState createState() => _UsersSreenState();
}

class _UsersSreenState extends ConsumerState<UsersSreen> {
  @override
  Widget build(BuildContext context) {

    final asyncUsers = ref.watch(asyncUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: ContentView(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const PageHeader(
                    title: "Utilisateurs",
                    description: 'Gestion des utilisateurs'),
                Expanded(
                  child: Container(),
                ),
                const Gap(16),
                FilledButton.icon(
                  onPressed: () {
                    context.go("/administration/agents/add");
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Nouveau"),
                )
              ],
            ),

            // LIST OF TICKETS
            asyncUsers.when(
              data: (data) {
                return Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.circle,
                          color: Colors.grey
                        ),
                        title: Text(
                          data[index].name,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          data[index].firstName,
                          style: theme.textTheme.labelMedium,
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                  ),
                );
              },
              error: (error, stackTrace) {
                log("Error loading users error:: $error");
                log("Error loading users stackTrace:: $stackTrace");
                return const Text("An error occured when loading the users");
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
