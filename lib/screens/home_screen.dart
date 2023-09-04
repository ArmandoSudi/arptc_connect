import 'package:flutter/material.dart';

import '../widgets/custom_nav_bar.dart';

enum _SelectedTab { dahsboard, home, account }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late TabController tabController;

  var _selectedTab = _SelectedTab.home;
  int curTabIndex = 0;

  List<Map<String, Widget>> pages = [
    {'widget': const Center(child: Text("Dahsboard"))},
    {'widget': const Center(child: Text("Home"))},
    {'widget': const Center(child: Text("Account"))},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar :AppBar(
            // elevation: 0,
            backgroundColor: Colors.white,
            title: Image.asset(
              'assets/icons/app_logo.png',
              height: 45,
            ),
          automaticallyImplyLeading: false,
        ),
        body: pages[curTabIndex]['widget']!,
        bottomNavigationBar: CustomNavBar(
          null,
              (index) {
            setState(() {
              curTabIndex = index;
            });
          },
          curTabIndex,
        ),
    );
  }
}
