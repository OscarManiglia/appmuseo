import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CustomNavbar extends StatefulWidget {
  const CustomNavbar({super.key});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.ticketOutline),
          label: 'Biglietti',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.creditCard),
          label: 'Pagamenti',
        ),
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.cog),
          label: 'Impostazioni',
        ),
      ],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}