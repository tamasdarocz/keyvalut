import 'package:flutter/material.dart';
import 'first_tab.dart';
import 'second_tab.dart';
import 'third_tab.dart';

class BottomTabbarNav extends StatefulWidget {
  const BottomTabbarNav({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BottomTabbarNavState();
  }
}

class _BottomTabbarNavState extends State<BottomTabbarNav>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _TabbarPages = <Widget>[FirstTab(), SecondTab(), ThirdTab()];

  static const _Tabs = <Tab>[
    Tab(icon: Icon(Icons.key)),
    Tab(icon: Icon(Icons.shield)),
    Tab(icon: Icon(Icons.code)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(controller: _tabController, children: _TabbarPages),

      bottomNavigationBar: Material(
        color: Colors.amber,
        child: TabBar(tabs: _Tabs, controller: _tabController),
      ),
    );
  }
}
