class DeviceDetails {
  String deviceLat;
  String deviceLng;
  String deviceCourse;
  String deviceSpeed;
  String deviceIgnition;
  String deviceTime;
  String studentName;
  String studentClass;
  String mobile;
  String homeLat;
  String homeLng;
  String homeRadius;
  String inchargeNo;
  String driverNo;
  String schoolId;
  String schoolLat;
  String schoolLng;
  String alertRadius;
  String vehicleNo;
  String imei;
  String serialNo;
  String expiryDt;

  DeviceDetails({
    required this.deviceLat,
    required this.deviceLng,
    required this.deviceCourse,
    required this.deviceSpeed,
    required this.deviceIgnition,
    required this.deviceTime,
    required this.studentName,
    required this.studentClass,
    required this.mobile,
    required this.homeLat,
    required this.homeLng,
    required this.homeRadius,
    required this.inchargeNo,
    required this.driverNo,
    required this.schoolId,
    required this.schoolLat,
    required this.schoolLng,
    required this.alertRadius,
    required this.vehicleNo,
    required this.imei,
    required this.serialNo,
    required this.expiryDt,
  });

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    return DeviceDetails(
      deviceLat: json['device_lat'],
      deviceLng: json['device_lng'],
      deviceCourse: json['device_course'],
      deviceSpeed: json['device_speed'],
      deviceIgnition: json['device_ignition'],
      deviceTime: json['device_time'],
      studentName: json['student_name'],
      studentClass: json['class'],
      mobile: json['mobile'],
      homeLat: json['home_lat'],
      homeLng: json['home_lng'],
      homeRadius: json['home_radius'],
      inchargeNo: json['incharge_no'],
      driverNo: json['driver_no'],
      schoolId: json['school_id'],
      schoolLat: json['school_lat'],
      schoolLng: json['school_lng'],
      alertRadius: json['alert_radius'],
      vehicleNo: json['vehicle_no'],
      imei: json['imei'],
      serialNo: json['serial_no'],
      expiryDt: json['expiry_dt'],
    );
  }
}

