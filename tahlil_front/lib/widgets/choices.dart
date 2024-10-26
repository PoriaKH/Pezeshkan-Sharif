import 'package:flutter/material.dart';
import 'package:tahlil_front/widgets/text_field.dart';

class ChoicesWidget<T> extends StatefulWidget {
  final String title;
  final List<T> availableValues;
  final Map<T, String> labels;
  final List<T> selectedValues;
  final void Function(List<dynamic> newSelectedValues) onChange;

  const ChoicesWidget({
    super.key,
    required this.title,
    required this.availableValues,
    required this.labels,
    required this.selectedValues,
    required this.onChange,
  });

  @override
  State<ChoicesWidget> createState() => _ChoicesWidgetState<T>();
}

class _ChoicesWidgetState<T> extends State<ChoicesWidget> {
  final searchController = TextEditingController();
  List filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.availableValues;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: searchController,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.search),
          hint: widget.title,
          onChanged: (search) => setState(() => filtered = widget
              .availableValues
              .where((e) => widget.labels[e]!
                  .toLowerCase()
                  .contains(search.toLowerCase()))
              .toList()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                children: filtered
                    .map(
                      (e) => Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () =>
                              onChanged(e, !widget.selectedValues.contains(e)),
                          child: Row(
                            children: [
                              const SizedBox(width: 5),
                              Text(widget.labels[e]!),
                              Expanded(child: Container()),
                              Checkbox(
                                value: widget.selectedValues.contains(e),
                                onChanged: (checked) => onChanged(e, checked),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void onChanged(T e, bool? checked) {
    List newList;
    if (checked!) {
      newList = <T>[...widget.selectedValues, e];
    } else {
      newList = widget.selectedValues.where((e2) => e2 != e).toList();
    }
    widget.onChange(newList);
  }
}
