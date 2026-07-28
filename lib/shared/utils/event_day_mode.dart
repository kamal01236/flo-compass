import '../../core/theme/app_theme_mode.dart';
import '../../data/services/event_clock_service.dart';

/// Resolves whether event-day UI (Now/Next bar, quick actions) should show.
///
/// - [EventDayMode.on] → always true
/// - [EventDayMode.off] → always false
/// - [EventDayMode.auto] → true when [EventClockService.currentDay] is set
///
/// Demo: `--dart-define=EVENT_NOW=2026-11-04T10:30:00` makes `auto` true on Day 1.
bool resolveEventDayMode(AppSettings settings, EventClockService clock) {
  return resolveEventDayModeForEvent(settings, clock.currentDay());
}

/// Shell-friendly resolver using [EventState.currentDay] without importing
/// [EventState] (avoids circular provider dependencies).
bool resolveEventDayModeForEvent(AppSettings settings, String? currentDay) {
  return switch (settings.eventDayMode) {
    EventDayMode.on => true,
    EventDayMode.off => false,
    EventDayMode.auto => currentDay != null,
  };
}
