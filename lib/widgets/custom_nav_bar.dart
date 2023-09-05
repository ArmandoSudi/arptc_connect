import 'package:flutter/material.dart';

class CustomNavBar extends StatefulWidget {
  final int curTabIndex;
  final Function(int) onTap;
  const CustomNavBar(Key? key, this.onTap, this.curTabIndex) : super(key: key);

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (tabIndex){
        widget.onTap(tabIndex);
      },
      // selectedItemColor: Colors.orange,
      // unselectedItemColor: Colors.pinkAccent,
      currentIndex: widget.curTabIndex,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Account',
        ),
      ],
    );
  }
}
