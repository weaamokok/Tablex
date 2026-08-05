import 'package:flutter/material.dart';

import 'package:tablex_example/features/import_export/import_export_screen.dart';
import 'package:tablex_example/features/infinite_scroll/infinite_scroll_screen.dart';
import 'package:tablex_example/features/lazy_paged/lazy_paged_grid_screen.dart';
import 'package:tablex_example/features/select_picker/select_picker_screen.dart';
import 'package:tablex_example/features/static/static_table_screen.dart';

void main() {
  runApp(const TablexExampleApp());
}

class TablexExampleApp extends StatelessWidget {
  const TablexExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablex Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _ExampleHome(),
    );
  }
}

class _ExampleHome extends StatefulWidget {
  const _ExampleHome();

  @override
  State<_ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<_ExampleHome> {
  int _tabIndex = 0;

  static const _tabs = [
    (icon: Icons.table_rows_outlined, label: 'Static'),
    (icon: Icons.cloud_outlined, label: 'Paged'),
    (icon: Icons.all_inclusive_outlined, label: 'Infinite'),
    (icon: Icons.checklist_outlined, label: 'Select'),
    (icon: Icons.import_export_outlined, label: 'I/O'),
  ];

  static const _screens = [
    StaticGridScreen(),
    LazyPagedGridScreen(),
    InfiniteScrollScreen(),
    SelectPickerScreen(),
    ImportExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablex Demo'),
        centerTitle: false,
        elevation: 0,
      ),
      body: _screens[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
