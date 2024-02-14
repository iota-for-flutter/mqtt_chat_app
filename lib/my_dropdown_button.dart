import 'package:flutter/material.dart';

class MyDropdownButton extends StatelessWidget {
  String title = '';
  List<String> items = [];
  String currentValue = '';
  final Function onChanged;

  MyDropdownButton({
    super.key,
    required this.title,
    required this.items,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: const BoxDecoration(
            color: Colors.white, //<-- SEE HERE
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
          child: DropdownButton<String>(
            value: currentValue,
            onChanged: (String? newValue) {
              onChanged(newValue);
            },
            underline: Container(),
            items: items.map<DropdownMenuItem<String>>((String value) {
              // Todo: adjust DropdownButton regarding labels
              String label = "Shimmer TESTNET";
              if (value != "https://api.testnet.shimmer.network") {
                label = "Shimmer NETWORK";
              }
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  label,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
