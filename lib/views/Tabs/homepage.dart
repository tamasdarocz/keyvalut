import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'first_tab.dart';
import 'second_tab.dart';
import 'third_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;
  final List<Widget> _pages = const [
    FirstTab(),
    SecondTab(),
    ThirdTab(),
  ];

  final List<String> _tabTitles = const [
    'Passwords',
    'Authenticator',
    'API Keys'
  ];

  void _navigateBottomBar(int index) => setState(() => _currentPageIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _currentPageIndex == 0
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_tabTitles[_currentPageIndex]),
            IconButton(
              icon: Icon(
                Provider.of<ThemeProvider>(context).isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ],
        )
            : Text(_tabTitles[_currentPageIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _pages[_currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: _navigateBottomBar,
        selectedItemColor: Colors.amber,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.key), label: 'Passwords'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Authenticator'),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'API Keys'),
        ],
      ),
    );
  }
}