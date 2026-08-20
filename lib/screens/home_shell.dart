import 'package:flutter/material.dart';

import '../theme/liquid.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'channels_screen.dart';
import 'models_screen.dart';
import 'key_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    KeyScreen(),
    UsersScreen(),
    ChannelsScreen(),
    ModelsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          GlassNavItem('总览', Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          GlassNavItem('密钥', Icons.vpn_key_outlined, activeIcon: Icons.vpn_key_rounded),
          GlassNavItem('用户', Icons.people_outline_rounded, activeIcon: Icons.people_rounded),
          GlassNavItem('渠道', Icons.router_outlined, activeIcon: Icons.router_rounded),
          GlassNavItem('日志', Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
          GlassNavItem('设置', Icons.settings_outlined, activeIcon: Icons.settings_rounded),
        ],
      ),
    );
  }
}
