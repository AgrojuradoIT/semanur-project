import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class SemanurAutocomplete<T extends Object> extends StatelessWidget {
  final List<T> options;
  final String Function(T) displayStringForOption;
  final void Function(T) onSelected;
  final T? initialValue;
  final String hint;
  final bool Function(T, String) filterFn;
  final String? Function(T?)? validator;
  final void Function(String)? onChanged;

  const SemanurAutocomplete({
    super.key,
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    this.initialValue,
    required this.hint,
    required this.filterFn,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      initialValue: TextEditingValue(
        text: initialValue != null ? displayStringForOption(initialValue!) : '',
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        if (text.isEmpty || (initialValue != null && text == displayStringForOption(initialValue!))) {
          return options;
        }
        return options.where((option) =>
            filterFn(option, text.toLowerCase()));
      },
      displayStringForOption: displayStringForOption,
      onSelected: (option) {
        onSelected(option);
        FocusManager.instance.primaryFocus?.unfocus();
      },
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onTap: () {
            // Trigger options view legally by updating selection to force notification
            final text = controller.text;
            controller.value = TextEditingValue(
              text: text,
              selection: TextSelection.fromPosition(
                TextPosition(offset: text.length),
              ),
            );
          },
          style: const TextStyle(color: Colors.white, fontSize: 13),
          validator: (value) {
            if (validator != null) {
              return validator!(initialValue); // or however it validates
            }
            return null;
          },
          onChanged: (value) {
            if (onChanged != null) {
              onChanged!(value);
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF121212),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryYellow),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryYellow),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: const Color(0xFF1E1E1E), // surfaceDark
            child: Container(
              width: MediaQuery.of(context).size.width - 64, // Margin 16+16+32
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final T option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      displayStringForOption(option),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
