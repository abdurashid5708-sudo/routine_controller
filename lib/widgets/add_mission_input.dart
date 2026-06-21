import 'package:flutter/material.dart';

class AddMissionInput extends StatelessWidget {
  final TextEditingController controller;

  final VoidCallback onAdd;
  final Function(String) onSubmitted;

  const AddMissionInput({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: onSubmitted,

            style: const TextStyle(color: Colors.white),

            decoration: InputDecoration(
              hintText: "Enter new mission",

              hintStyle: const TextStyle(color: Colors.grey),

              filled: true,
              fillColor: const Color(0xFF1E1E1E),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),

                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          height: 55,

          child: ElevatedButton(
            onPressed: onAdd,

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
