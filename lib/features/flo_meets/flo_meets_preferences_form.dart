import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/flo_meets_preferences.dart';
import '../../data/models/networking_card.dart';
import '../../data/services/flo_meets_service.dart';
import '../../data/services/flo_meets_slot_catalog.dart';
import '../../data/services/meet_nickname_service.dart';
import '../../data/mappers/amenity_mapper.dart';
import '../../domain/entities/amenity.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/flo_meet_amenity_label.dart';

// ignore_for_file: deprecated_member_use

/// Flo Meets preferences form (no opt-in toggle). Used for first-open setup and edits.
class FloMeetsPreferencesForm extends StatefulWidget {
  const FloMeetsPreferencesForm({
    super.key,
    required this.initial,
    required this.networkingCard,
    required this.onChanged,
  });

  final FloMeetsPreferences initial;
  final NetworkingCard networkingCard;
  final ValueChanged<FloMeetsPreferences> onChanged;

  @override
  State<FloMeetsPreferencesForm> createState() =>
      _FloMeetsPreferencesFormState();
}

class _FloMeetsPreferencesFormState extends State<FloMeetsPreferencesForm> {
  late TextEditingController _nicknameController;
  late TextEditingController _noteController;
  String _identity = '';
  final Set<String> _openTo = {};
  late int _experienceYears;
  final Set<String> _purposes = {};
  final Set<String> _personalInterests = {};
  final Set<String> _personality = {};
  final Set<String> _slots = {};
  String _amenityId = '';
  FloMeetContactMedium _contactMedium = FloMeetContactMedium.none;

  List<_TaxonomyItem> _purposesList = [];
  List<_TaxonomyItem> _personalList = [];
  List<_TaxonomyItem> _personalityList = [];
  List<Amenity> _meetAmenities = [];
  bool _loading = true;

  final _nicknameService = MeetNicknameService();

  static const _contactOptions = [
    FloMeetContactMedium.email,
    FloMeetContactMedium.phone,
    FloMeetContactMedium.linkedin,
  ];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initial.nickname);
    _noteController = TextEditingController(text: widget.initial.meetNote);
    _identity = widget.initial.identity;
    _openTo.addAll(widget.initial.openTo);
    _experienceYears =
        widget.initial.experienceYears ??
        FloMeetsPreferences.defaultExperienceYears;
    _purposes.addAll(widget.initial.purposes);
    _personalInterests.addAll(widget.initial.personalInterests);
    _personality.addAll(widget.initial.personalityTraits);
    _slots.addAll(widget.initial.enabledSlots);
    _amenityId = widget.initial.meetAmenityId;
    _contactMedium = widget.initial.contactMedium;
    _loadTaxonomy();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emit();
      if (_nicknameController.text.isEmpty) {
        _suggestNickname();
      }
    });
  }

  Future<void> _loadTaxonomy() async {
    final purposesRaw = await rootBundle.loadString(
      'assets/data/flo_meets_purposes.json',
    );
    final personalRaw = await rootBundle.loadString(
      'assets/data/flo_meets_personal_interests.json',
    );
    final personalityRaw = await rootBundle.loadString(
      'assets/data/flo_meets_personality_traits.json',
    );
    final amenitiesRaw = await rootBundle.loadString(
      'assets/data/flo2026_amenities.json',
    );

    if (!mounted) return;
    setState(() {
      _purposesList = _parseTaxonomy(purposesRaw);
      _personalList = _parseTaxonomy(personalRaw);
      _personalityList = _parseTaxonomy(personalityRaw);
      final amenities = (jsonDecode(amenitiesRaw) as List<dynamic>)
          .map((e) => amenityFromJson(e as Map<String, dynamic>))
          .where((a) => floMeetAmenityTypes.contains(a.type))
          .toList();
      _meetAmenities = amenities;
      _loading = false;
    });
  }

  List<_TaxonomyItem> _parseTaxonomy(String raw) {
    return (jsonDecode(raw) as List<dynamic>)
        .map(
          (e) =>
              _TaxonomyItem(id: e['id'] as String, label: e['label'] as String),
        )
        .toList();
  }

  Future<void> _suggestNickname() async {
    final suggested = await _nicknameService.suggest();
    if (!mounted) return;
    _nicknameController.text = suggested;
    _emit();
  }

  void _emit() {
    widget.onChanged(
      FloMeetsPreferences(
        optedIn: true,
        nickname: _nicknameController.text.trim(),
        identity: _identity,
        openTo: _openTo.toList(),
        experienceYears: _experienceYears,
        purposes: _purposes.toList(),
        personalInterests: _personalInterests.toList(),
        personalityTraits: _personality.toList(),
        enabledSlots: _slots.toList(),
        meetAmenityId: _amenityId,
        contactMedium: _contactMedium,
        meetNote: _noteController.text.trim(),
      ).coercedForSave(),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.floMeetsIdentityTitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in FloMeetIdentity.all)
              ChoiceChip(
                label: Text(FloMeetIdentity.labelFor(id)),
                selected: _identity == id,
                onSelected: (_) {
                  setState(() => _identity = id);
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsOpenToTitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in FloMeetOpenTo.options)
              FilterChip(
                label: Text(FloMeetOpenTo.labelFor(id)),
                selected: _openTo.contains(id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _openTo.add(id);
                    } else {
                      _openTo.remove(id);
                    }
                  });
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsExperienceTitle),
        Slider(
          value: _experienceYears.toDouble(),
          min: 0,
          max: 40,
          divisions: 40,
          label: '$_experienceYears',
          onChanged: (v) {
            setState(() => _experienceYears = v.round());
            _emit();
          },
        ),
        Text('$_experienceYears ${l10n.floMeetsExperienceYears}'),
        const SizedBox(height: 16),
        Text(
          l10n.meetNicknameLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: l10n.meetNicknameHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.meetNicknameSuggest,
              onPressed: _suggestNickname,
            ),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 16),
        _chipSection(l10n.floMeetsPurposeTitle, _purposesList, _purposes),
        _chipSection(
          l10n.floMeetsPersonalInterestsTitle,
          _personalList,
          _personalInterests,
        ),
        _chipSection(
          l10n.floMeetsPersonalityTitle,
          _personalityList,
          _personality,
        ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsSlotsTitle),
        Text(
          l10n.floMeetsSlotsHint,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in FloMeetsSlotCatalog.slotsForDay('Day 1'))
              FilterChip(
                label: Text(slot.label),
                selected: _slots.contains(slot.key),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _slots.add(slot.key);
                    } else {
                      _slots.remove(slot.key);
                    }
                  });
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsAmenityTitle),
        DropdownButtonFormField<String>(
          value: _amenityId.isEmpty ? null : _amenityId,
          isExpanded: true,
          decoration: InputDecoration(hintText: l10n.floMeetsAmenityHint),
          items: _buildGroupedAmenityItems(context),
          selectedItemBuilder: (context) {
            return _buildGroupedAmenityItems(context).map((item) {
              final value = item.value;
              if (value == null || value.startsWith('__header_')) {
                return const SizedBox.shrink();
              }
              return Text(
                _amenityLabelForId(value) ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }).toList();
          },
          onChanged: (v) {
            if (v == null || v.startsWith('__header_')) return;
            setState(() => _amenityId = v);
            _emit();
          },
        ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsContactMediumTitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final medium in _contactOptions)
              FilterChip(
                label: Text(_contactLabel(l10n, medium)),
                selected: _contactMedium == medium,
                onSelected: (selected) {
                  setState(() {
                    _contactMedium = selected
                        ? medium
                        : FloMeetContactMedium.none;
                  });
                  _emit();
                },
              ),
          ],
        ),
        if (_contactMedium != FloMeetContactMedium.none &&
            !_hasContactField(widget.networkingCard, _contactMedium))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.floMeetsContactEmptyWarning,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        _sectionTitle(l10n.floMeetsMeetNoteTitle),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(hintText: l10n.floMeetsMeetNoteHint),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.floMeetsOnboardingFooter,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  String? _amenityLabelForId(String id) {
    for (final amenity in _meetAmenities) {
      if (amenity.id == id) return formatFloMeetAmenityLabel(amenity);
    }
    return null;
  }

  List<DropdownMenuItem<String>> _buildGroupedAmenityItems(
    BuildContext context,
  ) {
    final grouped = <String, List<Amenity>>{};
    for (final amenity in _meetAmenities) {
      grouped.putIfAbsent(amenity.floor, () => []).add(amenity);
    }
    final floors = grouped.keys.toList()..sort(compareFloMeetFloors);
    final items = <DropdownMenuItem<String>>[];
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    for (final floor in floors) {
      final floorAmenities = grouped[floor]!
        ..sort((a, b) => a.label.compareTo(b.label));
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '__header_$floor',
          child: Text(formatFloMeetFloorLabel(floor), style: headerStyle),
        ),
      );
      for (final amenity in floorAmenities) {
        items.add(
          DropdownMenuItem<String>(
            value: amenity.id,
            child: Text(
              formatFloMeetAmenityLabel(amenity),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    return items;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _chipSection(
    String title,
    List<_TaxonomyItem> items,
    Set<String> selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                FilterChip(
                  label: Text(item.label),
                  selected: selected.contains(item.id),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        selected.add(item.id);
                      } else {
                        selected.remove(item.id);
                      }
                    });
                    _emit();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _contactLabel(AppLocalizations l10n, FloMeetContactMedium m) =>
      switch (m) {
        FloMeetContactMedium.none => l10n.floMeetsContactNone,
        FloMeetContactMedium.email => l10n.floMeetsContactEmail,
        FloMeetContactMedium.phone => l10n.floMeetsContactPhone,
        FloMeetContactMedium.linkedin => l10n.floMeetsContactLinkedin,
      };

  static bool _hasContactField(
    NetworkingCard card,
    FloMeetContactMedium medium,
  ) {
    final field = switch (medium) {
      FloMeetContactMedium.email => card.email,
      FloMeetContactMedium.phone => card.phoneE164,
      FloMeetContactMedium.linkedin => card.linkedInUrl,
      FloMeetContactMedium.none => null,
    };
    return field != null && field.visible && field.value.trim().isNotEmpty;
  }
}

class _TaxonomyItem {
  const _TaxonomyItem({required this.id, required this.label});
  final String id;
  final String label;
}
