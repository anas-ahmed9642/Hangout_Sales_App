import 'package:flutter/material.dart';

import 'theme.dart';

class HangoutSalesManagerApp extends StatelessWidget {
  const HangoutSalesManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangout Sales Manager',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const Scaffold(
        body: Center(
          child: Text('Hangout Sales Manager'),
        ),
      ),
    );
  }
}