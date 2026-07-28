import 'package:provider/provider.dart';
import 'package:flo_compass/providers/agenda_alerts_provider.dart';

/// Inert agenda alerts provider for widget tests that do not exercise detection.
ChangeNotifierProvider<AgendaAlertsState> testAgendaAlertsProvider([
  AgendaAlertsState? state,
]) {
  return ChangeNotifierProvider<AgendaAlertsState>(
    create: (_) => state ?? AgendaAlertsState(),
  );
}
