import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccordionItemWidget extends StatefulWidget {
  final String title;
  final String? badge;
  final Widget child;

  const AccordionItemWidget({
    super.key,
    required this.title,
    required this.child,
    this.badge,
  });

  @override
  State<AccordionItemWidget> createState() => _AccordionItemWidgetState();
}

class _AccordionItemWidgetState extends State<AccordionItemWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Badge(
                        label: Text(widget.badge ?? ''),
                        offset: const Offset(17.5, -4),
                        backgroundColor: theme.primaryColor,
                        child: Text(
                          widget.title.capitalize!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(child: Container()),
                      ExpandIcon(
                        isExpanded: expanded,
                        onPressed: (_) => setState(() => expanded = !expanded),
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 5),
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }
}
