import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kredipal/models/attendance_model.dart';
import 'package:kredipal/views/attendance_history.dart';
import 'package:kredipal/widgets/custom_app_bar.dart';
import '../controller/attendance_controller.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Attendance',
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => const AttendanceHistoryScreen());
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.currentState.value == AttendanceState.camera) {
            return _buildCameraView(controller);
          }
          if (controller.currentState.value == AttendanceState.processing) {
            return _buildProcessingView();
          }
          return _buildMainView(controller);
        }),
      ),
    );
  }

  Widget _buildMainView(AttendanceController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayStatusCard(controller),
          const SizedBox(height: 20),
          _buildActionButtons(controller),
          const SizedBox(height: 20),
          _buildLocationInfo(controller),
          if (controller.attendanceLocation.value is AttendanceStatusResponse &&
              (controller.attendanceLocation.value as AttendanceStatusResponse)
                      .status ==
                  'error')
            _buildRetryButton(controller),
        ],
      ),
    );
  }

  Widget _buildTodayStatusCard(AttendanceController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Attendance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final statusResponse = controller.attendanceStatus.value;
            final attendance = controller.todayAttendance.value;
            if (statusResponse != null && statusResponse.status == 'error') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusResponse.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Action: ${statusResponse.buttonAction}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    'Check-in',
                    'Time: ${controller.formatTime(attendance?.checkIn ?? statusResponse?.checkInTime ?? '--:--')}',
                    Icons.login,
                    Colors.green,
                    attendance?.checkInLocation ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeCard(
                    'Check-out',
                    'Time: ${controller.formatTime(attendance?.checkOut ?? statusResponse?.checkOutTime ?? '--:--')}',
                    Icons.logout,
                    Colors.red,
                    attendance?.checkOutLocation ?? 'N/A',
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color, String location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Loc: $location', style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AttendanceController controller) {
    return Obx(() {
      if (controller.isAttendanceComplete) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 36),
              SizedBox(height: 10),
              Text(
                'Attendance Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'You have completed check-in and check-out for today.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Row(
        children: [
          if (controller.canCheckIn || controller.canReCheckIn.value)
            Expanded(
              child: _buildActionButton(
                controller.canReCheckIn.value ? 'Re-Check In' : 'Check In',
                Icons.login,
                Colors.green,
                () => controller.startCheckIn(),
                controller.isLoading.value,
              ),
            ),
          if ((controller.canCheckIn || controller.canReCheckIn.value) &&
              controller.canCheckOut)
            const SizedBox(width: 16),
          if (controller.canCheckOut)
            Expanded(
              child: _buildActionButton(
                'Check Out',
                Icons.logout,
                Colors.red,
                () => controller.startCheckOut(),
                controller.isLoading.value,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationInfo(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final locationResponse = controller.attendanceLocation.value;
            if (locationResponse is AttendanceStatusResponse) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationResponse.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Action: ${locationResponse.buttonAction}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            } else if (locationResponse is AttendanceLocationResponse) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationResponse.currentLocation ?? 'Unknown location',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (locationResponse.currentCoordinates != null &&
                      locationResponse.currentCoordinates!.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    locationResponse.currentCoordinates != null &&
                            locationResponse.currentCoordinates!.isNotEmpty
                        ? 'Coordinates: ${locationResponse.currentCoordinates}'
                        : 'Coordinates unavailable',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  if (locationResponse.latitude != null &&
                      locationResponse.longitude != null)
                    Text(
                      'Lat: ${locationResponse.latitude}, Lng: ${locationResponse.longitude}',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                ],
              );
            }
            return const Text(
              'Fetching location...',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRetryButton(AttendanceController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: () {
          //controller._fetchAttendanceLocation(()); // Retry location fetch
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Retry Location Fetch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCameraView(AttendanceController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                controller.isCheckingIn.value
                    ? 'Check-in Camera'
                    : 'Check-out Camera',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Position yourself in the camera',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Obx(() {
              if (!controller.isCameraInitialized.value ||
                  controller.cameraController == null) {
                return const CircularProgressIndicator();
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: CameraPreview(controller.cameraController!),
                    ),
                  ),
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.isCheckingIn.value
                            ? Colors.green
                            : Colors.red,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${controller.countdown.value}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt,
                size: 48,
                color: controller.isCheckingIn.value ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Auto-capture in ${controller.countdown.value} seconds',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure your face is clearly visible',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.resetState(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
          SizedBox(height: 20),
          Text(
            'Processing your attendance...',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}