import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class Province {
  final String code;
  final String name;
  final String? nameEn;
  final String? fullName;
  final String? fullNameEn;
  final String? codeName;
  final int? regionCode;

  Province({
    required this.code,
    required this.name,
    this.nameEn,
    this.fullName,
    this.fullNameEn,
    this.codeName,
    this.regionCode,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      fullName: json['full_name'],
      fullNameEn: json['full_name_en'],
      codeName: json['code_name'],
      regionCode: json['region_code'],
    );
  }
}

class District {
  final String code;
  final String name;
  final String? nameEn;
  final String? fullName;
  final String? fullNameEn;
  final String? codeName;
  final String provinceCode;

  District({
    required this.code,
    required this.name,
    this.nameEn,
    this.fullName,
    this.fullNameEn,
    this.codeName,
    required this.provinceCode,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      fullName: json['full_name'],
      fullNameEn: json['full_name_en'],
      codeName: json['code_name'],
      provinceCode: json['province_code']?.toString() ?? '',
    );
  }
}

class Ward {
  final String code;
  final String name;
  final String? nameEn;
  final String? fullName;
  final String? fullNameEn;
  final String? codeName;
  final String districtCode;

  Ward({
    required this.code,
    required this.name,
    this.nameEn,
    this.fullName,
    this.fullNameEn,
    this.codeName,
    required this.districtCode,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      fullName: json['full_name'],
      fullNameEn: json['full_name_en'],
      codeName: json['code_name'],
      districtCode: json['district_code']?.toString() ?? '',
    );
  }
}

class VietnamAddressService {
  static const String baseUrl = 'https://provinces.open-api.vn/api';

  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return true;
    };
    return IOClient(httpClient);
  }

  static Future<List<Province>> getProvinces() async {
    final client = _createHttpClient();
    try {
      final response = await client.get(Uri.parse('$baseUrl/p/'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Province.fromJson(json)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<List<District>> getDistrictsByProvince(String provinceCode) async {
    final client = _createHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/p/$provinceCode?depth=2'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> districts = data['districts'] ?? [];
        return districts.map((json) => District.fromJson(json)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<List<Ward>> getWardsByDistrict(String districtCode) async {
    final client = _createHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/d/$districtCode?depth=2'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> wards = data['wards'] ?? [];
        return wards.map((json) => Ward.fromJson(json)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        throw Exception('Failed to load wards: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<Province?> getProvinceByCode(String code) async {
    final client = _createHttpClient();
    try {
      final response = await client.get(Uri.parse('$baseUrl/p/$code'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Province.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading province: $e');
      return null;
    } finally {
      client.close();
    }
  }

  static Future<District?> getDistrictByCode(String code) async {
    final client = _createHttpClient();
    try {
      final response = await client.get(Uri.parse('$baseUrl/d/$code'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return District.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading district: $e');
      return null;
    } finally {
      client.close();
    }
  }

  static Future<Ward?> getWardByCode(String code) async {
    final client = _createHttpClient();
    try {
      final response = await client.get(Uri.parse('$baseUrl/w/$code'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Ward.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading ward: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
