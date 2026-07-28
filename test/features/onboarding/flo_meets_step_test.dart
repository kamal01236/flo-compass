import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/flo_meets_preferences.dart';

void main() {
  test('defaults prefill experience without requiring optedIn', () {
    final defaults = FloMeetsPreferences.defaults();
    expect(defaults.experienceYears, 5);
    expect(defaults.isSetupComplete, isFalse);
  });

  test('incomplete prefs are not setup-complete', () {
    const prefs = FloMeetsPreferences(
      nickname: 'Av',
      identity: FloMeetIdentity.female,
      openTo: [FloMeetOpenTo.all],
      experienceYears: 5,
      purposes: ['networking'],
      personalInterests: ['hiking'],
      personalityTraits: ['curious'],
      enabledSlots: ['Day_1_0900'],
      meetAmenityId: 'amenity-1',
    );
    expect(prefs.isSetupComplete, isFalse);
  });

  test('coercedForSave fills experience and forces storage optedIn', () {
    const prefs = FloMeetsPreferences(
      nickname: 'Avery',
      identity: FloMeetIdentity.female,
      openTo: [FloMeetOpenTo.all],
      purposes: ['networking'],
      personalInterests: ['hiking'],
      personalityTraits: ['curious'],
      enabledSlots: ['Day_1_0900'],
      meetAmenityId: 'amenity-1',
    );
    final coerced = prefs.coercedForSave();
    expect(coerced.experienceYears, FloMeetsPreferences.defaultExperienceYears);
    expect(coerced.optedIn, isTrue);
    expect(coerced.isSetupComplete, isTrue);
  });

  test('empty prefs are not setup-complete', () {
    expect(FloMeetsPreferences.empty.isSetupComplete, isFalse);
  });
}
