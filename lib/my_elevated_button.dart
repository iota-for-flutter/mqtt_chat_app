import 'package:flutter/material.dart';

class MyElevatedButton extends StatelessWidget {
  String label;
  Function onPressed;

  MyElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 224, 202),
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),
        ),
        onPressed: () => onPressed(),
        child: const Text('Save', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
