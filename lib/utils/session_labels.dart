import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/workout_session.dart';

enum UpNextPhaseType { round, rest, finish }

class UpNextPhaseDisplay {
  const UpNextPhaseDisplay({required this.type, required this.label});

  final UpNextPhaseType type;
  final String label;
}

String _translate(
  String key, {
  BuildContext? context,
  Map<String, String>? namedArgs,
}) {
  if (context != null) {
    return context.tr(key, namedArgs: namedArgs);
  }

  return key;
}

String localizedPhaseLabel(WorkoutSession session, {BuildContext? context}) {
  if (session.state == SessionState.idle) {
    return _translate('timer.phase.ready', context: context);
  }

  if (session.state == SessionState.preparing ||
      session.pausedDuringPreparation) {
    return _translate('timer.phase.get_ready', context: context);
  }

  if (session.state == SessionState.completed) {
    return _translate('timer.phase.done', context: context);
  }

  switch (session.phase) {
    case SessionPhase.warmUp:
      return _translate('timer.phase.warm_up', context: context);
    case SessionPhase.round:
      return _translate(
        'timer.phase.round',
        context: context,
        namedArgs: {'round': '${session.currentRound}'},
      );
    case SessionPhase.rest:
      return _translate('timer.phase.rest', context: context);
  }
}

UpNextPhaseDisplay? localizedUpNextPhase(
  WorkoutSession session, {
  BuildContext? context,
}) {
  if (session.state == SessionState.idle ||
      session.state == SessionState.preparing ||
      session.pausedDuringPreparation ||
      session.state == SessionState.completed) {
    return null;
  }

  if (session.phase == SessionPhase.warmUp) {
    return UpNextPhaseDisplay(
      type: UpNextPhaseType.round,
      label: _translate(
        'timer.up_next.round',
        context: context,
        namedArgs: {'round': '1'},
      ),
    );
  }

  if (session.phase == SessionPhase.round) {
    if (session.isLastRound) {
      return UpNextPhaseDisplay(
        type: UpNextPhaseType.finish,
        label: _translate('timer.up_next.finish', context: context),
      );
    }

    return UpNextPhaseDisplay(
      type: UpNextPhaseType.rest,
      label: _translate('timer.up_next.rest', context: context),
    );
  }

  return UpNextPhaseDisplay(
    type: UpNextPhaseType.round,
    label: _translate(
      'timer.up_next.round',
      context: context,
      namedArgs: {'round': '${session.currentRound + 1}'},
    ),
  );
}
