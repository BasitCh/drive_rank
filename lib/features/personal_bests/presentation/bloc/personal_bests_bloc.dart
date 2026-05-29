import 'dart:async';

import 'package:drive_rank/features/personal_bests/data/personal_bests_repository.dart';
import 'package:drive_rank/features/personal_bests/domain/personal_bests.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@immutable
sealed class PersonalBestsEvent {
  const PersonalBestsEvent();
}

class PersonalBestsStarted extends PersonalBestsEvent {
  const PersonalBestsStarted();
}

class _PersonalBestsUpdated extends PersonalBestsEvent {
  const _PersonalBestsUpdated(this.bests);
  final PersonalBests bests;
}

@immutable
class PersonalBestsState {
  const PersonalBestsState({required this.isLoading, required this.bests});

  factory PersonalBestsState.initial() =>
      PersonalBestsState(isLoading: true, bests: PersonalBests.empty());

  final bool isLoading;
  final PersonalBests bests;

  PersonalBestsState copyWith({bool? isLoading, PersonalBests? bests}) =>
      PersonalBestsState(
        isLoading: isLoading ?? this.isLoading,
        bests: bests ?? this.bests,
      );
}

/// Drives the Personal Bests page. Subscribes to the repository's
/// reactive stream once on start and re-emits state on every trip
/// table change — the screen redraws the instant a new trip lands.
@injectable
class PersonalBestsBloc extends Bloc<PersonalBestsEvent, PersonalBestsState> {
  PersonalBestsBloc(this._repo) : super(PersonalBestsState.initial()) {
    on<PersonalBestsStarted>(_onStarted);
    on<_PersonalBestsUpdated>(_onUpdated);
  }

  final PersonalBestsRepository _repo;
  StreamSubscription<PersonalBests>? _sub;

  Future<void> _onStarted(
    PersonalBestsStarted event,
    Emitter<PersonalBestsState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _repo.watch().listen((b) => add(_PersonalBestsUpdated(b)));
  }

  void _onUpdated(
    _PersonalBestsUpdated event,
    Emitter<PersonalBestsState> emit,
  ) {
    emit(state.copyWith(isLoading: false, bests: event.bests));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
