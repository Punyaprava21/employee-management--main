import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kredipal/controller/login-controller.dart';
import 'package:kredipal/services/attendance_api_service.dart';
import '../models/attendance_model.dart';

enum AttendanceState {
  initial,
  camera,
  processing,
  checkedIn,
  checkedOut,
  error,
}

class AttendanceController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController authController = Get.find<AuthController>();

  final Rx<AttendanceState> currentState = AttendanceState.initial.obs;
  final RxString errorMessage = ''.obs;
  final RxInt countdown = 3.obs;
  final RxString currentLocation = ''.obs;
  final RxString currentCoordinates = ''.obs;
  final Rx<AttendanceRecord?> todayAttendance = Rx<AttendanceRecord?>(null);
  final Rx<AttendanceStatusResponse?> attendanceStatus =
      Rx<AttendanceStatusResponse?>(null);
  final Rx<dynamic> attendanceLocation = Rx<dynamic>(null);

  final RxBool isLoading = false.obs;
  final RxBool isCheckingIn = false.obs;
  final RxBool isCheckingOut = false.obs;
  final RxBool isLocationLoading = false.obs;
  final RxBool isCameraInitialized = false.obs;

  final RxBool canReCheckIn = false.obs;

  CameraController? cameraController;
  Timer? countdownTimer;

  @override
  void onInit() {
    super.onInit();
    _loadAttendanceStatus();
  }

  @override
  void onClose() {
    countdownTimer?.cancel();
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> _loadAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('attendanceDate') ?? '';
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastDate != today) {
      await _resetAttendanceInPrefs();
      todayAttendance.value = null;
      canReCheckIn.value = true;
    } else {
      _restoreFromPrefs(prefs);
    }

    try {
      isLoading.value = true;
      await Future.wait([
        _fetchAttendanceStatus(),
        _fetchAttendanceLocation(),
      ]);
      canReCheckIn.value = !isAttendanceComplete &&
          (todayAttendance.value?.checkIn == null ||
              attendanceStatus.value?.status == 'error');
    } catch (e) {
      print('❌ Failed to load attendance data: $e');
      errorMessage.value = e.toString();
      currentState.value = AttendanceState.error;
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);

      if (lastDate == today) {
        _restoreFromPrefs(prefs);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAttendanceStatus() async {
    try {
      final response = await _apiService.checkAttendanceStatus(
        token: authController.token.value,
      );
      attendanceStatus.value = response;
      todayAttendance.value = AttendanceRecord(
        checkIn: response.checkInTime,
        checkOut: response.checkOutTime,
        checkInCoordinates: response.latitude != null && response.longitude != null
            ? '${response.latitude},${response.longitude}'
            : null,
      );

      if (response.status == 'completed') {
        currentState.value = AttendanceState.checkedOut;
        canReCheckIn.value = false;
      } else if (response.buttonAction == 'checkout') {
        currentState.value = AttendanceState.checkedIn;
        canReCheckIn.value = false;
      } else {
        currentState.value = AttendanceState.initial;
        canReCheckIn.value = true;
      }
    } catch (e) {
      print('❌ Error fetching attendance status: $e');
      attendanceStatus.value = e is AttendanceStatusResponse
          ? e
          : AttendanceStatusResponse(
              status: 'error',
              message: 'Failed to fetch status: $e',
              buttonAction: 'Retry',
              workedHours: 0,
            );
      canReCheckIn.value = true;
      rethrow;
    }
  }

  Future<void> _fetchAttendanceLocation() async {
    try {
      if (currentCoordinates.value.isEmpty || currentLocation.value.isEmpty) {
        await getCurrentLocation();
      }
      final response = await _apiService.fetchAttendanceLocation(
        token: authController.token.value,
        currentCoordinates: currentCoordinates.value,
        currentLocation: currentLocation.value,
      );
      attendanceLocation.value = response;
      if (response is AttendanceLocationResponse) {
        currentLocation.value = response.currentLocation ?? currentLocation.value;
        currentCoordinates.value = response.currentCoordinates ?? currentCoordinates.value;
      } else if (response is AttendanceStatusResponse) {
        currentLocation.value = response.message;
        currentCoordinates.value = '0.0,0.0';
        if (response.status == 'error') {
          Get.snackbar('Location Error', response.message,
              backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }
    } catch (e) {
      print('❌ Error fetching attendance location: $e');
      attendanceLocation.value = e is AttendanceStatusResponse
          ? e
          : AttendanceStatusResponse(
              status: 'error',
              message: 'Failed to fetch location: $e',
              buttonAction: 'Retry',
              workedHours: 0,
            );
      currentLocation.value = 'Location unavailable';
      currentCoordinates.value = '0.0,0.0';
      rethrow;
    }
  }

  void _restoreFromPrefs(SharedPreferences prefs) {
    final hasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
    final hasCheckedOut = prefs.getBool('hasCheckedOut') ?? false;

    if (hasCheckedOut) {
      currentState.value = AttendanceState.checkedOut;
      canReCheckIn.value = false;
      todayAttendance.value = AttendanceRecord(
        id: prefs.getInt('attendanceId'),
        checkIn: prefs.getString('checkInTime'),
        checkOut: prefs.getString('checkOutTime'),
        checkInLocation: prefs.getString('checkInLocation'),
        checkOutLocation: prefs.getString('checkOutLocation'),
      );
    } else if (hasCheckedIn) {
      currentState.value = AttendanceState.checkedIn;
      canReCheckIn.value = false;
      todayAttendance.value = AttendanceRecord(
        id: prefs.getInt('attendanceId'),
        checkIn: prefs.getString('checkInTime'),
        checkOut: null,
        checkInLocation: prefs.getString('checkInLocation'),
        checkOutLocation: null,
      );
    } else {
      currentState.value = AttendanceState.initial;
      canReCheckIn.value = true;
      todayAttendance.value = null;
    }
  }

  Future<void> _saveAttendanceStatus({
    required bool checkedIn,
    required bool checkedOut,
    AttendanceRecord? record,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    await prefs.setString('attendanceDate', today);
    await prefs.setBool('hasCheckedIn', checkedIn);
    await prefs.setBool('hasCheckedOut', checkedOut);

    if (record != null) {
      if (record.id != null) await prefs.setInt('attendanceId', record.id!);
      if (record.checkIn != null)
        await prefs.setString('checkInTime', record.checkIn!);
      if (record.checkOut != null)
        await prefs.setString('checkOutTime', record.checkOut!);
      if (record.checkInLocation != null)
        await prefs.setString('checkInLocation', record.checkInLocation!);
      if (record.checkOutLocation != null)
        await prefs.setString('checkOutLocation', record.checkOutLocation!);
    }
  }

  Future<void> _resetAttendanceInPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('attendanceDate');
    await prefs.remove('hasCheckedIn');
    await prefs.remove('hasCheckedOut');
    await prefs.remove('attendanceId');
    await prefs.remove('checkInTime');
    await prefs.remove('checkOutTime');
    await prefs.remove('checkInLocation');
    await prefs.remove('checkOutLocation');
    canReCheckIn.value = true;
  }

  Future<void> initializeCamera() async {
    try {
      await _disposeCamera();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      print("Camera initialized: ${frontCamera.lensDirection}");
      currentState.value = AttendanceState.camera;
    } catch (e) {
      errorMessage.value = 'Camera error: $e';
      print("Camera init error: $e");
      currentState.value = AttendanceState.error;
      canReCheckIn.value = true;
    }
  }

  void startCountdown() {
    countdown.value = 3;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        timer.cancel();
        if (isCheckingIn.value) {
          captureAndCheckIn();
        } else if (isCheckingOut.value) {
          captureAndCheckOut();
        }
      }
    });
  }

  Future<void> startCheckIn() async {
    if (isAttendanceComplete) {
      Get.snackbar('Notice', 'Attendance is already complete for today.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (!canCheckIn && !canReCheckIn.value) {
      Get.snackbar('Notice', 'Check-in not allowed at this time.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isCheckingIn.value = true;
    isCheckingOut.value = false;
    errorMessage.value = '';
    await initializeCamera();
    await getCurrentLocation();
    startCountdown();
  }

  Future<void> startCheckOut() async {
    if (todayAttendance.value?.id == null) {
      Get.snackbar('Error', 'Check-in not found. Please check in first.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (isAttendanceComplete) {
      Get.snackbar('Notice', 'You have already checked out for today.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (!canCheckOut) {
      Get.snackbar('Notice', 'Check-out not allowed at this time.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isCheckingIn.value = false;
    isCheckingOut.value = true;
    errorMessage.value = '';
    await initializeCamera();
    await getCurrentLocation();
    startCountdown();
  }

  Future<void> captureAndCheckIn() async {
    if (!(cameraController?.value.isInitialized ?? false)) {
      _handleError('Camera not ready');
      canReCheckIn.value = true;
      return;
    }

    if (currentLocation.value.isEmpty || currentLocation.value == 'Location unavailable') {
      _handleError('Location not available');
      canReCheckIn.value = true;
      return;
    }

    try {
      currentState.value = AttendanceState.processing;
      isLoading.value = true;

      final XFile imageFile = await cameraController!.takePicture();

      final response = await _apiService.checkIn(
        token: authController.token.value,
        image: File(imageFile.path),
        location: currentLocation.value,
        coordinates: currentCoordinates.value,
        notes: 'Checked in',
      );

      if (response.status == 'success') {
        todayAttendance.value = response.data;
        currentState.value = AttendanceState.checkedIn;
        canReCheckIn.value = false;

        await _saveAttendanceStatus(
          checkedIn: true,
          checkedOut: false,
          record: response.data,
        );

        _showSuccessDialog(
          'Check-in Successful!',
          'Time: ${formatTime(response.data?.checkIn ?? '')}',
          'Location: ${response.data?.checkInLocation ?? ''}',
          Icons.login,
          Colors.green,
        );
      } else {
        _handleError(response.message);
        canReCheckIn.value = true;
      }
    } catch (e) {
      _handleError('Check-in failed: $e');
      canReCheckIn.value = true;
    } finally {
      isLoading.value = false;
      isCheckingIn.value = false;
      await _disposeCamera();
    }
  }

  Future<void> captureAndCheckOut() async {
    if (!(cameraController?.value.isInitialized ?? false)) {
      _handleError('Camera not ready');
      return;
    }

    if (currentLocation.value.isEmpty || currentLocation.value == 'Location unavailable') {
      _handleError('Location not available');
      return;
    }

    try {
      currentState.value = AttendanceState.processing;
      isLoading.value = true;

      final XFile imageFile = await cameraController!.takePicture();

      final response = await _apiService.checkOut(
        token: authController.token.value,
        attendanceId: todayAttendance.value!.id!,
        image: File(imageFile.path),
        location: currentLocation.value,
        coordinates: currentCoordinates.value,
        notes: 'Checked out',
      );

      if (response.status == 'success') {
        todayAttendance.value = response.data;
        currentState.value = AttendanceState.checkedOut;
        canReCheckIn.value = false;

        await _saveAttendanceStatus(
          checkedIn: true,
          checkedOut: true,
          record: response.data,
        );

        _showSuccessDialog(
          'Check-out Successful!',
          'Time: ${formatTime(response.data?.checkOut ?? '')}',
          'Total: ${_calculateWorkHours()}',
          Icons.logout,
          Colors.red,
        );
      } else {
        _handleError(response.message);
      }
    } catch (e) {
      _handleError('Checkout failed: $e');
    } finally {
      isLoading.value = false;
      isCheckingOut.value = false;
      await _disposeCamera();
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isLocationLoading.value = true;
      currentLocation.value = 'Fetching location...';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location services disabled');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentCoordinates.value = '${position.latitude},${position.longitude}';

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.name}, ${place.locality}, ${place.administrativeArea}';
        currentLocation.value = address;
      } else {
        currentLocation.value = 'Unknown Location';
      }
    } catch (e) {
      currentLocation.value = 'Location unavailable';
      currentCoordinates.value = '0.0,0.0';
      Get.snackbar('Location Error', e.toString(),
          backgroundColor: Colors.orange, colorText: Colors.white);
    } finally {
      isLocationLoading.value = false;
    }
  }

  void _handleError(String msg) {
    errorMessage.value = msg;
    currentState.value = AttendanceState.error;
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  void _showSuccessDialog(
      String title, String time, String location, IconData icon, Color color) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(location,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('OK')),
      ],
    ));
  }

  Future<void> _disposeCamera() async {
    try {
      countdownTimer?.cancel();
      await cameraController?.dispose();
      cameraController = null;
      isCameraInitialized.value = false;
    } catch (_) {}
  }

  String formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    try {
      final dateTime = DateTime.parse(timeString).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '--:--';
    }
  }

  String _calculateWorkHours() {
    try {
      final checkIn = DateTime.parse(todayAttendance.value!.checkIn!);
      final checkOut = DateTime.parse(todayAttendance.value!.checkOut!);
      final diff = checkOut.difference(checkIn);
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } catch (_) {
      return '--:--';
    }
  }

  void resetState() {
    currentState.value = AttendanceState.initial;
    errorMessage.value = '';
    isCheckingIn.value = false;
    isCheckingOut.value = false;
    countdownTimer?.cancel();
    _disposeCamera();
    canReCheckIn.value = todayAttendance.value?.checkIn == null ||
        attendanceStatus.value?.status == 'error';
  }

  bool get canCheckIn => attendanceStatus.value?.buttonAction == 'checkin';
  bool get canCheckOut => attendanceStatus.value?.buttonAction == 'checkout';
  bool get isAttendanceComplete => attendanceStatus.value?.status == 'completed';
}