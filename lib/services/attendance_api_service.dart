import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:kredipal/constant/api_url.dart';
import '../models/attendance_model.dart';

class ApiService extends GetxService {
  Map<String, String> _getMultipartHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response,
      {bool expectSuccess = true}) {
    print('🔍 Decoding response with status: ${response.statusCode}');
    print('📥 Response headers: ${response.headers}');
    print('📄 Raw response body: ${response.body}');

    if (!response.headers['content-type']!.contains('application/json')) {
      print(
          '⚠️ Error: Non-JSON content type: ${response.headers['content-type']}');
      throw Exception('Unexpected response type (not JSON): ${response.body}');
    }

    try {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      print('✅ Decoded JSON: $jsonData');
      if (expectSuccess &&
          response.statusCode != 200 &&
          response.statusCode != 201) {
        print(
            '❌ HTTP Error: ${response.statusCode}, Message: ${jsonData['message'] ?? 'Unknown'}');
        throw Exception(
            jsonData['message'] ?? 'Request failed: ${response.statusCode}');
      }
      return jsonData;
    } catch (e) {
      print('❌ JSON decode error: $e');
      throw Exception('Failed to decode response: $e');
    }
  }

  Future<GeofenceSettingsResponse> fetchGeofenceSettings({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${ApiUrl.baseUrl}/api/geofence-settings');
      print('📤 Making geofence settings request to: $uri');
      print('📩 Headers: ${_getMultipartHeaders(token)}');

      final response = await http
          .get(
        uri,
        headers: _getMultipartHeaders(token),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Request timeout for $uri');
          throw Exception('Request timeout');
        },
      );

      print('✅ Geofence settings response status: ${response.statusCode}');
      final jsonData = _decodeResponse(response);
      print('🔧 Parsing response into GeofenceSettingsResponse');
      final geofenceResponse = GeofenceSettingsResponse.fromJson(jsonData);
      print('📡 Parsed response: $geofenceResponse');
      return geofenceResponse;
    } catch (e) {
      print('❌ Error in fetchGeofenceSettings: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch geofence settings: $e');
      }
    }
  }

  Future<AttendanceResponse> checkIn({
    required String token,
    required File image,
    required String location,
    required String coordinates,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('${ApiUrl.baseUrl}/api/attendances');
      print('📤 Making check-in request to: $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getMultipartHeaders(token));

      request.files.add(
        await http.MultipartFile.fromPath(
          'checkin_image',
          image.path,
          filename: 'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      request.fields['check_in_location'] = location;
      request.fields['check_in_coordinates'] = coordinates;
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      print('📦 Request fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('✅ Check-in response status: ${response.statusCode}');
      print('📄 Check-in response body: ${response.body}');

      final jsonData = _decodeResponse(response);
      return AttendanceResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Error in checkIn: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to check-in: $e');
      }
    }
  }

  Future<AttendanceResponse> checkOut({
    required String token,
    required int attendanceId,
    required File image,
    required String location,
    required String coordinates,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('${ApiUrl.baseUrl}/api/attendances/$attendanceId');
      print('📤 Making check-out request to: $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getMultipartHeaders(token));

      request.files.add(
        await http.MultipartFile.fromPath(
          'checkout_image',
          image.path,
          filename: 'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      request.fields['check_out_location'] = location;
      request.fields['check_out_coordinates'] = coordinates;
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      print('📦 Request fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('✅ Check-out response status: ${response.statusCode}');
      print('📄 Check-out response: ${response.body}');

      final jsonData = _decodeResponse(response);
      return AttendanceResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Error in checkOut: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to check-out: $e');
      }
    }
  }

  Future<AttendanceStatusResponse> checkAttendanceStatus({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${ApiUrl.baseUrl}/api/attendance/status');
      print('📤 Making attendance status request to: $uri');

      final response = await http
          .get(
        uri,
        headers: _getMultipartHeaders(token),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('✅ Attendance status response status: ${response.statusCode}');
      print('📄 Attendance status response: ${response.body}');

      final jsonData = _decodeResponse(response);
      return AttendanceStatusResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Error in checkAttendanceStatus: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to fetch attendance status: $e');
      }
    }
  }

  Future<dynamic> fetchAttendanceLocation({
    required String token,
    required String currentCoordinates,
    required String currentLocation, // Added as a required parameter
  }) async {
    try {
      final uri = Uri.parse('${ApiUrl.baseUrl}/api/attendance/location');
      print('📤 Making attendance location request to: $uri');
      print('📩 Headers: ${_getMultipartHeaders(token)}');
      print('📦 Request body: {"current_coordinates": "$currentCoordinates", "current_location": "$currentLocation"}');

      final response = await http.post(
        uri,
        headers: {
          ..._getMultipartHeaders(token),
          'Content-Type': 'application/json', // Explicitly set JSON content type
        },
        body: jsonEncode({
          'current_coordinates': currentCoordinates,
          'current_location': currentLocation, // Added to the request body
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Request timeout for $uri');
          throw Exception('Request timeout');
        },
      );

      print('✅ Attendance location response status: ${response.statusCode}');
      print('📄 Attendance location response body: ${response.body}');

      if (!response.headers['content-type']!.contains('application/json') ??
          true) {
        print('⚠️ Non-JSON response: ${response.body}');
        return AttendanceStatusResponse(
          status: 'error',
          message: 'Unexpected response type: ${response.body}',
          buttonAction: 'Retry',
          workedHours: 0,
        );
      }

      final jsonData = _decodeResponse(response, expectSuccess: false);
      print('🔧 Parsing response');

      if (jsonData['status'] == 'error') {
        final statusResponse = AttendanceStatusResponse.fromJson(jsonData);
        statusResponse.message = jsonData['errors']?['current_coordinates']?.first ??
            jsonData['errors']?['current_location']?.first ??
            'Unknown error';
        print('📡 Parsed error response: $statusResponse');
        return statusResponse;
      } else {
        final locationResponse = AttendanceLocationResponse.fromJson(jsonData);
        print('📡 Parsed success response: $locationResponse');
        return locationResponse;
      }
    } catch (e) {
      print('❌ Error in fetchAttendanceLocation: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return AttendanceStatusResponse(
          status: 'error',
          message: 'Network error: Please check your internet connection',
          buttonAction: 'Retry',
          workedHours: 0,
        );
      } else {
        return AttendanceStatusResponse(
          status: 'error',
          message: 'Failed to fetch attendance location: $e',
          buttonAction: 'Retry',
          workedHours: 0,
        );
      }
    }
  }

  Future<void> displayAttendanceStatus({
    required String token,
  }) async {
    try {
      print('📢 Fetching and displaying attendance status...');
      final response = await checkAttendanceStatus(token: token);

      String formatTime(String? timeString) {
        if (timeString == null || timeString.isEmpty) return 'Not available';
        try {
          final dateTime = DateTime.parse(timeString).toLocal();
          final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
          final minute = dateTime.minute.toString().padLeft(2, '0');
          final period = dateTime.hour >= 12 ? 'PM' : 'AM';
          return '$hour:$minute $period';
        } catch (e) {
          print('⚠️ Time format error: $e');
          return 'Invalid time format';
        }
      }

      print('📋 Attendance Status Response:');
      print('  Status: ${response.status}');
      print('  Message: ${response.message}');
      print('  Button Action: ${response.buttonAction}');
      print('  Check-in Time: ${formatTime(response.checkInTime)}');
      print('  Check-out Time: ${formatTime(response.checkOutTime)}');
      print('  Worked Hours: ${response.workedHours}');
      print('  Latitude: ${response.latitude ?? 'Not available'}');
      print('  Longitude: ${response.longitude ?? 'Not available'}');
      print(
          '  Within Geofence: ${response.isWithinGeofence ?? 'Not available'}');
    } catch (e) {
      print('❌ Failed to display attendance status: $e');
      throw Exception('Failed to display attendance status: $e');
    }
  }

  Future<void> displayCheckOutResponse({
    required String token,
    required int attendanceId,
    required File image,
    required String location,
    required String coordinates,
    String? notes,
  }) async {
    try {
      print('📢 Fetching and displaying check-out response...');
      final response = await checkOut(
        token: token,
        attendanceId: attendanceId,
        image: image,
        location: location,
        coordinates: coordinates,
        notes: notes,
      );

      String formatTime(String? timeString) {
        if (timeString == null || timeString.isEmpty) return 'Not available';
        try {
          final dateTime = DateTime.parse(timeString).toLocal();
          final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
          final minute = dateTime.minute.toString().padLeft(2, '0');
          final second = dateTime.second.toString().padLeft(2, '0');
          final period = dateTime.hour >= 12 ? 'PM' : 'AM';
          return '$hour:$minute:$second $period';
        } catch (e) {
          print('⚠️ Time format error: $e');
          return 'Invalid time format';
        }
      }

      String formatCoordinates(String? coords) {
        if (coords == null || coords.isEmpty) return 'Not available';
        final parts = coords.split(',');
        if (parts.length != 2) return 'Invalid coordinates';
        return 'Lat: ${parts[0].trim()}, Lng: ${parts[1].trim()}';
      }

      print('📋 Check-out Response:');
      print('  Status: ${response.status}');
      print('  Message: ${response.message}');
      print('  Button Action: ${response.buttonAction ?? 'N/A'}');
      print('  Data:');
      print('    ID: ${response.data?.id ?? 'N/A'}');
      print('    Employee ID: ${response.data?.employeeId ?? 'N/A'}');
      print('    Date: ${response.data?.date ?? 'N/A'}');
      print('    Check-in Time: ${formatTime(response.data?.checkIn)}');
      print('    Check-out Time: ${formatTime(response.data?.checkOut)}');
      print(
          '    Check-in Location: ${response.data?.checkInLocation ?? 'N/A'}');
      print(
          '    Check-out Location: ${response.data?.checkOutLocation ?? 'N/A'}');
      print(
          '    Check-in Coordinates: ${formatCoordinates(response.data?.checkInCoordinates)}');
      print(
          '    Check-out Coordinates: ${formatCoordinates(response.data?.checkOutCoordinates)}');
      print('    Notes: ${response.data?.notes ?? 'N/A'}');
      print('    Check-in Image: ${response.data?.checkinImage ?? 'N/A'}');
      print('    Check-out Image: ${response.data?.checkoutImage ?? 'N/A'}');
      print('    Within Geofence: ${response.data?.isWithinGeofence ?? 'N/A'}');
      print('    Created At: ${formatTime(response.data?.createdAt)}');
      print('    Updated At: ${formatTime(response.data?.updatedAt)}');
    } catch (e) {
      print('❌ Failed to display check-out response: $e');
      throw Exception('Failed to display check-out response: $e');
    }
  }

  Future<void> displayGeofenceSettings({
    required String token,
  }) async {
    try {
      print('📢 Fetching and displaying geofence settings...');
      final response = await fetchGeofenceSettings(token: token);

      print('📋 Geofence Settings Response:');
      print('  Status: ${response.status}');
      print('  Button Action: ${response.buttonAction}');
      print('  Data:');
      print('    Office Name: ${response.data?.officeName ?? 'N/A'}');
      print('    Latitude: ${response.data?.latitude ?? 'N/A'}');
      print('    Longitude: ${response.data?.longitude ?? 'N/A'}');
      print('    Radius: ${response.data?.radius ?? 'N/A'} meters');
    } catch (e) {
      print('❌ Failed to display geofence settings: $e');
      throw Exception('Failed to display geofence settings: $e');
    }
  }

  Future<void> displayAttendanceLocation({
    required String token,
  }) async {
    try {
      print('📢 Fetching and displaying attendance location...');
      final response = await fetchAttendanceLocation(
        token: token,
        currentCoordinates: '0.0,0.0', // Provide a default value for testing
        currentLocation: 'Unknown Location', // Default value for testing
      );

      print('📋 Attendance Location Response:');
      if (response is AttendanceStatusResponse) {
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  Button Action: ${response.buttonAction}');
      } else if (response is AttendanceLocationResponse) {
        print('  Current Coordinates: ${response.currentCoordinates ?? 'N/A'}');
        print('  Current Location: ${response.currentLocation ?? 'N/A'}');
        print('  Latitude: ${response.latitude ?? 'N/A'}');
        print('  Longitude: ${response.longitude ?? 'N/A'}');
      } else {
        print('⚠️ Unknown response type: $response');
      }
    } catch (e) {
      print('❌ Failed to display attendance location: $e');
      throw Exception('Failed to display attendance location: $e');
    }
  }
}