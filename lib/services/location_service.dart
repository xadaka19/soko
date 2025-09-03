import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class LocationService {
  // Kenya counties and their major cities/towns
  static final Map<String, Map<String, dynamic>> _kenyaLocations = {
    'nairobi': {
      'name': 'Nairobi',
      'id': 1,
      'subcities': {
        'westlands': {'name': 'Westlands', 'id': 101},
        'karen': {'name': 'Karen', 'id': 102},
        'kilimani': {'name': 'Kilimani', 'id': 103},
        'lavington': {'name': 'Lavington', 'id': 104},
        'kileleshwa': {'name': 'Kileleshwa', 'id': 105},
        'upperhill': {'name': 'Upper Hill', 'id': 106},
        'cbd': {'name': 'CBD', 'id': 107},
        'kasarani': {'name': 'Kasarani', 'id': 108},
        'embakasi': {'name': 'Embakasi', 'id': 109},
        'kahawa': {'name': 'Kahawa', 'id': 110},
        'ruaka': {'name': 'Ruaka', 'id': 111},
        'runda': {'name': 'Runda', 'id': 112},
        'muthaiga': {'name': 'Muthaiga', 'id': 113},
        'parklands': {'name': 'Parklands', 'id': 114},
        'south_c': {'name': 'South C', 'id': 115},
        'south_b': {'name': 'South B', 'id': 116},
        'langata': {'name': 'Langata', 'id': 117},
        'kibera': {'name': 'Kibera', 'id': 118},
        'dagoretti': {'name': 'Dagoretti', 'id': 119},
        'roysambu': {'name': 'Roysambu', 'id': 120},
      },
    },
    'mombasa': {
      'name': 'Mombasa',
      'id': 2,
      'subcities': {
        'nyali': {'name': 'Nyali', 'id': 201},
        'bamburi': {'name': 'Bamburi', 'id': 202},
        'kisauni': {'name': 'Kisauni', 'id': 203},
        'likoni': {'name': 'Likoni', 'id': 204},
        'changamwe': {'name': 'Changamwe', 'id': 205},
        'tudor': {'name': 'Tudor', 'id': 206},
        'old_town': {'name': 'Old Town', 'id': 207},
        'mtwapa': {'name': 'Mtwapa', 'id': 208},
        'diani': {'name': 'Diani', 'id': 209},
        'malindi': {'name': 'Malindi', 'id': 210},
      },
    },
    'kiambu': {
      'name': 'Kiambu',
      'id': 3,
      'subcities': {
        'thika': {'name': 'Thika', 'id': 301},
        'kikuyu': {'name': 'Kikuyu', 'id': 302},
        'limuru': {'name': 'Limuru', 'id': 303},
        'ruiru': {'name': 'Ruiru', 'id': 304},
        'juja': {'name': 'Juja', 'id': 305},
        'kiambu_town': {'name': 'Kiambu Town', 'id': 306},
        'githunguri': {'name': 'Githunguri', 'id': 307},
        'karuri': {'name': 'Karuri', 'id': 308},
      },
    },
    'nakuru': {
      'name': 'Nakuru',
      'id': 4,
      'subcities': {
        'nakuru_town': {'name': 'Nakuru Town', 'id': 401},
        'naivasha': {'name': 'Naivasha', 'id': 402},
        'gilgil': {'name': 'Gilgil', 'id': 403},
        'molo': {'name': 'Molo', 'id': 404},
        'njoro': {'name': 'Njoro', 'id': 405},
        'bahati': {'name': 'Bahati', 'id': 406},
      },
    },
    'machakos': {
      'name': 'Machakos',
      'id': 5,
      'subcities': {
        'machakos_town': {'name': 'Machakos Town', 'id': 501},
        'athi_river': {'name': 'Athi River', 'id': 502},
        'kangundo': {'name': 'Kangundo', 'id': 503},
        'matungulu': {'name': 'Matungulu', 'id': 504},
        'yatta': {'name': 'Yatta', 'id': 505},
      },
    },
    'kajiado': {
      'name': 'Kajiado',
      'id': 6,
      'subcities': {
        'kajiado_town': {'name': 'Kajiado Town', 'id': 601},
        'kitengela': {'name': 'Kitengela', 'id': 602},
        'ngong': {'name': 'Ngong', 'id': 603},
        'ongata_rongai': {'name': 'Ongata Rongai', 'id': 604},
        'bissil': {'name': 'Bissil', 'id': 605},
      },
    },
    'uasin_gishu': {
      'name': 'Uasin Gishu',
      'id': 7,
      'subcities': {
        'eldoret': {'name': 'Eldoret', 'id': 701},
        'moiben': {'name': 'Moiben', 'id': 702},
        'soy': {'name': 'Soy', 'id': 703},
        'turbo': {'name': 'Turbo', 'id': 704},
      },
    },
    'kisumu': {
      'name': 'Kisumu',
      'id': 8,
      'subcities': {
        'kisumu_central': {'name': 'Kisumu Central', 'id': 801},
        'kisumu_east': {'name': 'Kisumu East', 'id': 802},
        'kisumu_west': {'name': 'Kisumu West', 'id': 803},
        'nyando': {'name': 'Nyando', 'id': 804},
        'muhoroni': {'name': 'Muhoroni', 'id': 805},
      },
    },
    'meru': {
      'name': 'Meru',
      'id': 9,
      'subcities': {
        'meru_town': {'name': 'Meru Town', 'id': 901},
        'maua': {'name': 'Maua', 'id': 902},
        'mikinduri': {'name': 'Mikinduri', 'id': 903},
        'timau': {'name': 'Timau', 'id': 904},
      },
    },
    'nyeri': {
      'name': 'Nyeri',
      'id': 10,
      'subcities': {
        'nyeri_town': {'name': 'Nyeri Town', 'id': 1001},
        'karatina': {'name': 'Karatina', 'id': 1002},
        'othaya': {'name': 'Othaya', 'id': 1003},
        'mukurweini': {'name': 'Mukurweini', 'id': 1004},
      },
    },
    'kirinyaga': {
      'name': 'Kirinyaga',
      'id': 11,
      'subcities': {
        'kerugoya': {'name': 'Kerugoya', 'id': 1101},
        'sagana': {'name': 'Sagana', 'id': 1102},
        'kutus': {'name': 'Kutus', 'id': 1103},
        'baricho': {'name': 'Baricho', 'id': 1104},
      },
    },
    'murang_a': {
      'name': 'Murang\'a',
      'id': 12,
      'subcities': {
        'murang_a_town': {'name': 'Murang\'a Town', 'id': 1201},
        'kenol': {'name': 'Kenol', 'id': 1202},
        'kandara': {'name': 'Kandara', 'id': 1203},
        'gatanga': {'name': 'Gatanga', 'id': 1204},
      },
    },
    'nyandarua': {
      'name': 'Nyandarua',
      'id': 13,
      'subcities': {
        'ol_kalou': {'name': 'Ol Kalou', 'id': 1301},
        'nyahururu': {'name': 'Nyahururu', 'id': 1302},
        'engineer': {'name': 'Engineer', 'id': 1303},
      },
    },
    'laikipia': {
      'name': 'Laikipia',
      'id': 14,
      'subcities': {
        'nanyuki': {'name': 'Nanyuki', 'id': 1401},
        'nyahururu': {'name': 'Nyahururu', 'id': 1402},
        'rumuruti': {'name': 'Rumuruti', 'id': 1403},
      },
    },
    'other': {
      'name': 'Other Counties',
      'id': 99,
      'subcities': {
        'other_location': {'name': 'Other Location', 'id': 9901},
      },
    },
  };

  /// Get all counties/cities
  static Map<String, Map<String, dynamic>> getLocations() {
    return _kenyaLocations;
  }

  /// Get subcities for a specific county
  static Map<String, dynamic>? getSubcities(String countyKey) {
    return _kenyaLocations[countyKey]?['subcities'];
  }

  /// Get location ID for API
  static int? getLocationId(String? countyKey, String? subcityKey) {
    if (countyKey != null && subcityKey != null) {
      return _kenyaLocations[countyKey]?['subcities']?[subcityKey]?['id'];
    }
    return null;
  }

  /// Get location name for display
  static String? getLocationName(String? countyKey, String? subcityKey) {
    if (countyKey != null && subcityKey != null) {
      final countyName = _kenyaLocations[countyKey]?['name'];
      final subcityName =
          _kenyaLocations[countyKey]?['subcities']?[subcityKey]?['name'];
      if (countyName != null && subcityName != null) {
        return '$subcityName, $countyName';
      }
    }
    return null;
  }

  /// Search locations by query
  static List<Map<String, dynamic>> searchLocations(String query) {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    for (final county in _kenyaLocations.entries) {
      final countyKey = county.key;
      final countyData = county.value;
      final countyName = countyData['name'].toString().toLowerCase();

      // Check if county name matches
      if (countyName.contains(lowerQuery)) {
        results.add({
          'type': 'county',
          'key': countyKey,
          'name': countyData['name'],
          'fullName': countyData['name'],
        });
      }

      // Check subcities
      final subcities = countyData['subcities'] as Map<String, dynamic>;
      for (final subcity in subcities.entries) {
        final subcityKey = subcity.key;
        final subcityData = subcity.value;
        final subcityName = subcityData['name'].toString().toLowerCase();

        if (subcityName.contains(lowerQuery)) {
          results.add({
            'type': 'subcity',
            'countyKey': countyKey,
            'subcityKey': subcityKey,
            'name': subcityData['name'],
            'fullName': '${subcityData['name']}, ${countyData['name']}',
          });
        }
      }
    }

    return results;
  }

  /// Get popular locations (most commonly used)
  static List<Map<String, dynamic>> getPopularLocations() {
    return [
      {
        'type': 'subcity',
        'countyKey': 'nairobi',
        'subcityKey': 'westlands',
        'name': 'Westlands',
        'fullName': 'Westlands, Nairobi',
      },
      {
        'type': 'subcity',
        'countyKey': 'nairobi',
        'subcityKey': 'karen',
        'name': 'Karen',
        'fullName': 'Karen, Nairobi',
      },
      {
        'type': 'subcity',
        'countyKey': 'nairobi',
        'subcityKey': 'kilimani',
        'name': 'Kilimani',
        'fullName': 'Kilimani, Nairobi',
      },
      {
        'type': 'subcity',
        'countyKey': 'mombasa',
        'subcityKey': 'nyali',
        'name': 'Nyali',
        'fullName': 'Nyali, Mombasa',
      },
      {
        'type': 'subcity',
        'countyKey': 'kiambu',
        'subcityKey': 'thika',
        'name': 'Thika',
        'fullName': 'Thika, Kiambu',
      },
      {
        'type': 'subcity',
        'countyKey': 'nakuru',
        'subcityKey': 'nakuru_town',
        'name': 'Nakuru Town',
        'fullName': 'Nakuru Town, Nakuru',
      },
    ];
  }

  /// Fetch locations from API (if available)
  static Future<List<dynamic>> fetchLocationsFromAPI() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/get-locations.php'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ? data['locations'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching locations from API: $e');
      return [];
    }
  }
}
