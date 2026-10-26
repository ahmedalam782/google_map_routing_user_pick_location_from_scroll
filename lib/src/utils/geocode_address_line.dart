/// Builds the one-line place name ("الرشيد، بغداد") from a Google Geocoding
/// reverse response. The line is an area name plus one wider area for
/// context, Arabic names first; streets and buildings only when nothing wider
/// exists. Never empty for an `OK` response.
///
/// [nearby] is a place close to the point; it is appended as "قرب …".
String geocodeAddressLine(Map<String, dynamic> body, {String? nearby}) {
  final fields = _GeocodeFields(body);
  final candidates = fields.candidates;
  final near = nearby?.trim();
  final nearPart = (near == null || near.isEmpty) ? null : 'قرب $near';
  if (candidates.isEmpty) {
    final base = fields.plusCode ?? _unnamed;
    return nearPart == null ? base : '$base، $nearPart';
  }

  final arabic = candidates.where((c) => _hasArabic(c.value)).toList();
  final best = (arabic.isNotEmpty ? arabic : candidates).first;
  _Candidate? wider;

  for (final c in candidates) {
    if (c.key == best.key || !_areaKeys.contains(c.key)) continue;
    if (c.rank > best.rank) continue;
    if (_hasArabic(best.value) && !_hasArabic(c.value)) continue;
    if (c.value.contains(best.value) || best.value.contains(c.value)) continue;
    wider = c;
    break;
  }

  // "العلوية، حي الوحدة": the wider district first, unless it is the city.
  final areas = wider == null
      ? [best.value]
      : wider.key == 'locality'
          ? [best.value, wider.value]
          : [wider.value, best.value];
  return [...areas, if (nearPart != null) nearPart].join('، ');
}

const String _unnamed = 'موقع على الخريطة';

/// Keys that give an area as context; streets and buildings are not.
const Set<String> _areaKeys = {
  'neighborhood',
  'sublocality_level_2',
  'sublocality_level_1',
  'administrative_area_level_3',
  'administrative_area_level_2',
  'locality',
};

bool _hasArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

final RegExp _plusCodeRe =
    RegExp(r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}$');

/// Not a name to show: "Unnamed Road", a plus code, digits only.
bool _isJunkName(String? v) {
  final s = v?.trim();
  if (s == null || s.isEmpty) return true;
  final low = s.toLowerCase();
  if (low.contains('unnamed') || low == 'null' || low == 'n/a') return true;
  if (_plusCodeRe.hasMatch(s.split(RegExp(r'\s+')).first)) return true;
  return !RegExp(r'[؀-ۿA-Za-z]').hasMatch(s);
}

typedef _Candidate = ({String key, String value, int rank});

class _GeocodeFields {
  _GeocodeFields(Map<String, dynamic> body) {
    // The first value of each type, over all results, is the most precise.
    for (final result in (body['results'] as List?) ?? const []) {
      final components = ((result as Map)['address_components'] as List?) ?? [];
      for (final component in components) {
        final comp = component as Map;
        final name = (comp['long_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        for (final type in List<String>.from(comp['types'] ?? const [])) {
          if (type == 'political') continue;
          final values = _all.putIfAbsent(type, () => <String>[]);
          if (!values.contains(name)) values.add(name);
        }
      }
    }
    final compound = (body['plus_code'] as Map?)?['compound_code'] as String?;
    plusCode = compound?.trim().split(RegExp(r'\s+')).first;
  }

  final Map<String, List<String>> _all = {};
  String? plusCode;

  String? _first(String key) {
    final values = _all[key];
    return (values == null || values.isEmpty) ? null : values.first;
  }

  /// "881-63" is no name for a driver, so it becomes "شارع 881-63".
  static String? _cleanRoute(String? v) {
    final s = v?.trim();
    if (s == null || s.isEmpty) return null;
    if (s.startsWith('شارع') || s.startsWith('طريق')) return s;
    if (RegExp(r'^[٠-٩0-9\-/ ]+$').hasMatch(s)) return 'شارع $s';
    return s;
  }

  /// "شارع الشهداء - بغداد" becomes "شارع الشهداء": only the parts equal to
  /// an administrative value of the same response are dropped.
  String _stripAdminTail(String v) {
    final admins = <String>{
      ...?_all['locality'],
      ...?_all['administrative_area_level_1'],
      ...?_all['administrative_area_level_2'],
      ...?_all['administrative_area_level_3'],
      ...?_all['country'],
    }.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final parts = v.split(RegExp(r'\s+[-–—]\s+'));
    if (admins.isEmpty || parts.length < 2) return v;
    final kept = parts.where((p) => !admins.contains(p.trim())).toList();
    return kept.isEmpty ? v : kept.join(' - ');
  }

  String? get _route {
    final v = _cleanRoute(_first('route'));
    return v == null ? null : _stripAdminTail(v);
  }

  /// Valid names, most precise first.
  List<_Candidate> get candidates {
    final out = <_Candidate>[];
    void add(String key, String? v, int rank) {
      final s = v?.trim();
      if (s == null || _isJunkName(s) || out.any((e) => e.value == s)) return;
      out.add((key: key, value: s, rank: rank));
    }

    add('neighborhood', _first('neighborhood'), 90);
    add('sublocality_level_2', _first('sublocality_level_2'), 85);
    add('sublocality_level_1',
        _first('sublocality_level_1') ?? _first('sublocality'), 80);
    add('premise', _first('premise'), 75);
    add('route', _route, 70);
    add('administrative_area_level_3',
        _first('administrative_area_level_3'), 50);
    add('administrative_area_level_2',
        _first('administrative_area_level_2'), 40);
    add('locality', _first('locality'), 30);
    add('administrative_area_level_1',
        _first('administrative_area_level_1'), 10);
    out.sort((a, b) => b.rank.compareTo(a.rank));
    return out;
  }
}
