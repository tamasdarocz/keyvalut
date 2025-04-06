import 'package:flutter/material.dart';
import 'package:keyvalut/Tabs/first_tab.dart';
import 'package:keyvalut/Tabs/second_tab.dart';
import 'package:keyvalut/Tabs/third_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _CurrentPageIndex = 0;

  void _NavigateBottomBar(int index) {
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