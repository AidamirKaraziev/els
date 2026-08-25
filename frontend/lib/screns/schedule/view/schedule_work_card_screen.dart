import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../in_progress_works/bloc/work_details_bloc.dart';
import '../../submitted_works/models/submitted_work.dart' show WorkKind;
import '../../in_progress_works/repository/work_details_repository.dart';
import '../../in_progress_works/widgets/work_card_body.dart';

class ScheduleWorkCardScreen extends StatelessWidget {
  const ScheduleWorkCardScreen({
    Key? key,
    required this.workId,
    required this.objectName,
    this.repository,
  }) : super(key: key);

  final int workId;
  final String objectName;
  final WorkDetailsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkDetailsBloc>(
      create: (_) => WorkDetailsBloc(
        workId: workId,
        kind: WorkKind.maintenance,
        phase: WorkPhase.submitted,
        repository: repository,
      )..add(const WorkDetailsRequested()),
      child: _CardView(objectName: objectName),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({Key? key, required this.objectName}) : super(key: key);

  final String objectName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(objectName.isEmpty ? 'Работа' : objectName),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: ColorApp.myColorBlack,
      ),
      body: BlocBuilder<WorkDetailsBloc, WorkDetailsState>(
        builder: (BuildContext context, WorkDetailsState state) {
          if (state is WorkDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkDetailsFailure) {
            return Center(
              child: Text(state.message),
            );
          }

          if (state is WorkDetailsReady) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkChecklistBlock(
                    checklist: state.details.checklist,
                    photos: state.photos,
                  ),
                  const SizedBox(height: 16),
                  WorkTimesBlock(
                    details: state.details,
                    isProblem: false,
                    showFinished: true,
                    note: 'Информация о выполнении работы',
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
