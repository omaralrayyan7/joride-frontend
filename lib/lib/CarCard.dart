import 'package:flutter/material.dart';

import 'CarDetailsScreen.dart';

class CarCard extends StatelessWidget {
  final String name;
  final double price;

  const CarCard({
    super.key,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text("\$$price / hour"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarDetailsScreen(
              car: {
                "name": name,
                "price": price,
              },
            ),
          ),
        );
      },
    );
  }
}