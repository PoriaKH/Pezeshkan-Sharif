import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tahlil_front/classes/doctor.dart';
import 'package:tahlil_front/classes/imaging_center.dart';
import 'package:tahlil_front/extensions/string_ext.dart';
import 'package:tahlil_front/services/appointment.dart';
import 'package:tahlil_front/services/router.dart';
import 'package:tahlil_front/widgets/empty.dart' as empty;
import 'package:tahlil_front/widgets/error.dart' as error;
import 'package:tahlil_front/widgets/text_field.dart';

class ExplorePage extends StatefulWidget {
  final bool doctors;

  const ExplorePage({super.key, required this.doctors});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final AppointmentService _appointmentService = AppointmentService.instance;

  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 100, right: 100, bottom: 25),
          child: CustomTextField(
            controller: _searchController,
            icon: const Icon(Icons.search),
            hint: 'Search for '
                '${widget.doctors ? 'Doctors' : 'Imaging Centers'}...',
            onChanged: (_) => setState(() {}),
          ),
        ),
        FutureBuilder<List>(
          future: widget.doctors
              ? _appointmentService.allDoctors(
                  search: _searchController.text.nullIfEmpty)
              : _appointmentService.allImagingCenters(
                  search: _searchController.text.nullIfEmpty),
          builder: (context, snapshot) {
            final userSearch = widget.doctors ? "Doctor" : "Imaging Center";
            if (snapshot.hasError) {
              return error.ErrorWidget(
                msg: '${userSearch}s.',
                refresh: () => setState(() {}),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data!.isEmpty) {
              return empty.EmptyWidget(
                msg: 'No ${userSearch}s found.',
                refresh: () => setState(() {}),
              );
            }

            return Expanded(
              child: GridView.builder(
                itemCount: snapshot.data!.length,
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  mainAxisExtent: widget.doctors ? 225 : 150,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemBuilder: (context, i) {
                  final textTheme = Theme.of(context).textTheme;
                  final titleMedium = textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold);
                  final bodyMedium = textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold);

                  final user =
                      widget.doctors ? (snapshot.data![i] as Doctor) : null;
                  final imagingCenter = widget.doctors
                      ? null
                      : (snapshot.data![i] as ImagingCenter);

                  return Material(
                    elevation: 2,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      onTap: () => RouterService.go(
                        widget.doctors
                            ? '/create-appointment?doctor=${user!.ssid}'
                            : '/create-appointment?imaging-center=${imagingCenter!.id}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              // ignore: prefer_interpolation_to_compose_strings
                              (user?.firstName + ' ' + user?.lastName) ??
                                  imagingCenter!.name,
                              style: titleMedium,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone),
                                      const SizedBox(width: 10),
                                      Text(
                                        user?.phoneNumber ??
                                            imagingCenter?.phoneNumber ??
                                            '-',
                                        style: bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.email),
                                      const SizedBox(width: 10),
                                      Text(
                                        user?.emailAddress ??
                                            imagingCenter?.emailAddress ??
                                            '-',
                                        style: bodyMedium,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            if (widget.doctors) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.userDoctor),
                                  const SizedBox(width: 10),
                                  Text(
                                    user!.specialty ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop),
                                const SizedBox(width: 10),
                                Text(
                                  // ignore: prefer_interpolation_to_compose_strings
                                  (user?.province +
                                          ', ' +
                                          user?.city +
                                          ', ' +
                                          user?.street) ??
                                      // ignore: prefer_interpolation_to_compose_strings
                                      (imagingCenter?.province +
                                          ', ' +
                                          imagingCenter?.city +
                                          ', ' +
                                          imagingCenter?.street) ??
                                      '-',
                                  style: bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.work),
                                const SizedBox(width: 10),
                                Text(
                                  (user?.workTimes ?? imagingCenter?.workTimes)
                                          ?.map((wt) => '$wt')
                                          .join(', ')
                                          .capitalize
                                          ?.nullIfEmpty ??
                                      '-',
                                  style: bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
