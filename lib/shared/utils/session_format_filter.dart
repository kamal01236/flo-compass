import '../../data/models/models.dart';
import '../../data/models/user_profile.dart';

const lightKeynoteFormats = {
  'Keynote',
  'Fireside Chat',
  'Ignite',
  'Masterclass',
  'Showcase',
};

const deepWorkshopFormats = {
  'Live Lab',
  'Deep Dive',
  'Hands-on',
  'Roundtable',
  'Playbook',
  'AMA',
};

bool sessionMatchesEnergyFilter(Session session, EnergyFilter filter) {
  switch (filter) {
    case EnergyFilter.all:
      return true;
    case EnergyFilter.lightKeynotes:
      return lightKeynoteFormats.contains(session.format);
    case EnergyFilter.deepWorkshops:
      return deepWorkshopFormats.contains(session.format);
  }
}

List<ScoredSession> applyEnergyFilter(
  List<ScoredSession> ranked,
  EnergyFilter filter,
) {
  if (filter == EnergyFilter.all) return ranked;
  return ranked
      .where((item) => sessionMatchesEnergyFilter(item.session, filter))
      .toList();
}

String energyFilterCountLabel(int count, EnergyFilter filter) {
  switch (filter) {
    case EnergyFilter.lightKeynotes:
      return '$count keynote-style sessions';
    case EnergyFilter.deepWorkshops:
      return '$count workshop-style sessions';
    case EnergyFilter.all:
      return '$count sessions · personalized for you';
  }
}
