import 'package:flutter/material.dart';
import 'package:keyvalut/views/Tabs/second_tab.dart';
import 'package:keyvalut/views/Tabs/third_tab.dart';

import 'first_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _CurrentPageIndex = 0;

  Future<void> _NavigateBottomBar(int index) async {
    setState(() {
      _CurrentPageIndex = index;
    });
  }
final List<Widget> _Pages =[
  FirstTab(),
  SecondTab(),
  ThirdTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Pages[_CurrentPageIndex],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _CurrentPageIndex,
      onTap: _NavigateBottomBar,
      selectedItemColor: Colors.amber,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.key), label: 'Passwords'),
        BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Authenticator'),
        BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Api keys')
    ],
    ),
    );

  }
}