class VehicleType {
  final int id;
  final String name;
  final String? description;
  final int? maxCapacityKg;

  VehicleType({
    required this.id,
    required this.name,
    this.description,
    this.maxCapacityKg,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      maxCapacityKg: json['max_capacity_kg'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (maxCapacityKg != null) 'max_capacity_kg': maxCapacityKg,
    };
  }
}

class Vehicle {
  final int id;
  final String plateNumber;
  final String? driverName;
  final String? driverPhone;
  final VehicleType? vehicleType;
  final int? vehicleTypeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehicle({
    required this.id,
    required this.plateNumber,
    this.driverName,
    this.driverPhone,
    this.vehicleType,
    this.vehicleTypeId,
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      plateNumber: json['plate_number'] as String,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      vehicleType: json['vehicle_type'] != null
          ? VehicleType.fromJson(json['vehicle_type'] as Map<String, dynamic>)
          : null,
      vehicleTypeId: json['vehicle_type_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      if (driverName != null) 'driver_name': driverName,
      if (driverPhone != null) 'driver_phone': driverPhone,
      if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
    };
  }
}
