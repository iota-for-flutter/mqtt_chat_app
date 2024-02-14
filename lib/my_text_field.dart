import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String title;
  final controller;

  const MyTextField({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    const labelColor = Colors.black;
    const fillColor = Colors.white;
    const focusColor = Colors.white; //Color.fromARGB(255, 0, 200, 200);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: labelColor, // Change your color here!
            ),
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: fillColor,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: focusColor,
                ),
              ),
              fillColor: fillColor,
              filled: true,
              //labelText: label,
              hintText: title,
              labelStyle: const TextStyle(color: labelColor),
            ),
          ),
        ),
      ],
    );
  }
}
