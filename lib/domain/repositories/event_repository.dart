import '../entities/amenity.dart';
import '../entities/campus_layout.dart';
import '../entities/event_meta.dart';
import '../entities/learning_path.dart';
import '../entities/navigation_hint.dart';
import '../entities/session.dart';
import '../entities/speaker.dart';
import '../entities/track.dart';
import '../entities/venue.dart';

abstract class EventRepository {
  Future<EventMeta> loadMeta();
  Future<List<Session>> loadSessions();
  Future<List<Speaker>> loadSpeakers();
  Future<List<Venue>> loadVenues();
  Future<List<Track>> loadTracks();
  Future<List<LearningPath>> loadLearningPaths();
  Future<List<Amenity>> loadAmenities();
  Future<List<NavigationHint>> loadNavigationHints();
  Future<CampusLayout> loadCampus();
  Future<Session?> getSessionById(String id);
}
