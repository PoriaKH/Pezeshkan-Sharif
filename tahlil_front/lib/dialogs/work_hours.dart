import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tahlil_front/enums/weekday.dart';
import 'package:tahlil_front/services/profile.dart';
import 'package:tahlil_front/widgets/text_field.dart';

class WorkHoursDialog extends StatefulWidget {
  final dynamic user;

  const WorkHoursDialog(this.user, {super.key});

  @override
  State<WorkHoursDialog> createState() => _WorkHoursDialogState();
}

class _WorkHoursDialogState extends State<WorkHoursDialog> {
  final _profileService = ProfileService.instance;

  final Map<Weekday, String> workTimes = {};
  final Map<Weekday, String?> errors = {};
  final Map<Weekday, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    for (final wd in Weekday.values) {
      controllers[wd] = TextEditingController(
          text: user.workTimes
              .where((wt) => wt.weekday == wd)
              .map((wt) => '${wt.startHour}-${wt.endHour}')
              .join(','));
      workTimes[wd] = controllers[wd]!.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Manage Work Hours',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              ...Weekday.values.map(
                (wd) => CustomTextField(
                  controller: controllers[wd]!,
                  onChanged: (str) => workTimes[wd] = str,
                  label: '$wd\'s Hours'.capitalizeFirst,
                  hint: 'e.g. 9-11,15-17',
                  errorText: errors[wd],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Discard Changes'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Save Changes'),
                          onPressed: _editWorkHours,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validate() {
    void incorrectFormat(Weekday k) => errors[k] = 'Invalid Format.';
    void correctFormat(Weekday k) => errors[k] = null;

    for (final e in workTimes.entries) {
      final key = e.key, val = e.value;
      if (!RegExp(r'^[0-9,-]*$').hasMatch(val)) {
        incorrectFormat(key);
      } else if (val.isEmpty) {
        correctFormat(key);
      } else {
        try {
          val.split(',').forEach((e) {
            assert(e.split('-').map(int.parse).length == 2);
          });
          correctFormat(key);
        } catch (_) {
          incorrectFormat(key);
        }
      }
    }
    return errors.values.where((e) => e != null).isEmpty;
  }

  Future<void> _editWorkHours() async {
    final success = _validate();
    setState(() {});
    if (success && await _profileService.editWorkTimes(workTimes)) {
      Navigator.of(context).pop(false);
    }
  }
}
