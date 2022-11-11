import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'changes_detector_cubit.dart';

class ChangesDetector extends StatefulWidget {
  const ChangesDetector({
    Key? key,
  }) : super(key: key);

  @override
  State<ChangesDetector> createState() => _ChangesDetectorState();
}

class _ChangesDetectorState extends State<ChangesDetector> {
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChangesDetectorCubit, ChangesDetectorState>(
      builder: (context, state) {
        if (state.hasChanges) {
          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "You have unsaved changes.",
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      child: const Text(
                        "Save now",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () async {
                        if (isSaving) return;
                        try {
                          setState(() {
                            isSaving = true;
                          });
                          await context.read<ChangesDetectorCubit>().save();
                        } catch (e) {
                          print(e);
                        } finally {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      },
                    ),
                    if (isSaving) ...[
                      const Gap(5),
                      const CupertinoActivityIndicator(),
                    ],
                  ],
                )
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
