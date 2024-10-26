import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomTextField extends StatelessWidget {
  final Widget? icon;
  final String? label, hint, helperText, errorText;
  final bool required;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText, readOnly;
  final Function()? toggleObscureText;
  final Function(String)? onChanged;
  final EdgeInsets? padding;

  const CustomTextField({
    super.key,
    this.icon,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.required = false,
    this.obscureText = false,
    this.readOnly = false,
    this.toggleObscureText,
    required this.controller,
    this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              readOnly: readOnly,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                icon: icon,
                label: label == null
                    ? null
                    : Text('${label!}${required ? " *" : ""}'),
                hintText: hint,
                helperText: helperText,
                errorText: errorText,
              ),
            ),
          ),
          if (toggleObscureText != null)
            SizedBox.square(
              dimension: 50,
              child: Center(
                child: IconButton(
                  icon: FaIcon(
                    obscureText
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash,
                  ),
                  onPressed: toggleObscureText!,
                ),
              ),
            )
        ],
      ),
    );
  }
}
