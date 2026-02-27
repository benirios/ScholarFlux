import 'package:flutter/material.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Item Detail: $itemId — TODO')),
    );
  }
}
