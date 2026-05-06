// import 'package:arptc_connect/modules/usermanagement/presentation/controllers/async_users.dart';
// import 'package:arptc_connect/widgets/app_search_bar.dart';
// import 'package:arptc_connect/widgets/content_view.dart';
// import 'package:arptc_connect/widgets/empty_state_view.dart';
// import 'package:arptc_connect/widgets/error_state_view.dart';
// import 'package:arptc_connect/widgets/loading_state_view.dart';
// import 'package:arptc_connect/widgets/page_header.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
//
// class UserListScreen extends ConsumerStatefulWidget {
//   const UserListScreen({super.key});
//
//   @override
//   ConsumerState<UserListScreen> createState() => _UserListScreenState();
// }
//
// class _UserListScreenState extends ConsumerState<UserListScreen> {
//   late final TextEditingController _searchController;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController = TextEditingController();
//     ref.read(userSearchQueryProvider.notifier).state = '';
//   }
//
//   @override
//   void dispose() {
//     ref.read(userSearchQueryProvider.notifier).state = '';
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final usersAsync = ref.watch(filteredUserManagementUsersProvider);
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       body: ContentView(
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back_ios),
//                   onPressed: () => context.pop(),
//                 ),
//                 const PageHeader(
//                   title: 'User Management',
//                   description: 'List and search users by name',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             AppSearchBar(
//               controller: _searchController,
//               hintText: 'Search by name',
//               onChanged: (value) {
//                 ref.read(userSearchQueryProvider.notifier).state = value;
//               },
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: usersAsync.when(
//                 data: (users) {
//                   if (users.isEmpty) {
//                     return EmptyStateView(
//                       icon: Icons.person_search_outlined,
//                       title: 'No users found',
//                       description: _searchController.text.isEmpty
//                           ? 'No user is available yet.'
//                           : 'Try another name in the search bar.',
//                     );
//                   }
//
//                   return ListView.separated(
//                     itemCount: users.length,
//                     itemBuilder: (context, index) {
//                       final user = users[index];
//
//                       return ListTile(
//                         leading: CircleAvatar(
//                           child: Text(
//                             _initialsFor(user.firstName, user.name),
//                           ),
//                         ),
//                         title: Text(
//                           user.displayName,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         subtitle: user.email == null || user.email!.isEmpty
//                             ? null
//                             : Text(user.email!),
//                         onTap: () =>
//                             context.push('/service/usermanagement/${user.id}'),
//                       );
//                     },
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                   );
//                 },
//                 error: (error, _) {
//                   return ErrorStateView(
//                     title: 'Unable to load users',
//                     description: error.toString(),
//                     onRetry: () => ref.invalidate(userManagementUsersProvider),
//                   );
//                 },
//                 loading: () => const LoadingStateView(
//                   message: 'Loading users...',
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _initialsFor(String firstName, String name) {
//     final first =
//         firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : '';
//     final second = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
//     final initials = '$first$second';
//     if (initials.isNotEmpty) {
//       return initials;
//     }
//     return '?';
//   }
// }
