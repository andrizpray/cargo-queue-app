import 'vehicle_model.dart';
import 'location_model.dart';

enum QueueStatus { waiting, processing, completed, cancelled }

extension QueueStatusExtension on QueueStatus {
  String get label {
    switch (this) {
      case QueueStatus.waiting:
        return 'Waiting';
      case QueueStatus.processing:
        return 'Processing';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.cancelled:
        return 'Cancelled';
    }
  }

  static QueueStatus fromString(String value) {
    return QueueStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QueueStatus.waiting,
    );
  }
}

class Queue {
  final int id;
  final String queueNumber;
  final QueueStatus status;
  final Vehicle? vehicle;
  final int? vehicleId;
  final Location? location;
  final int? locationId;
  final String? notes;
  final String? cargoDescription;
  final double? weightKg;
  final DateTime? arrivedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Queue({
    required this.id,
    required this.queueNumber,
    required this.status,
    this.vehicle,
    this.vehicleId,
    this.location,
    this.locationId,
    this.notes,
    this.cargoDescription,
    this.weightKg,
    this.arrivedAt,
    this.processedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Queue.fromJson(Map<String, dynamic> json) {
    return Queue(
      id: json['id'] as int,
      queueNumber: json['queue_number'] as String,
      status: QueueStatusExtension.fromString(json['status'] as String),
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      vehicleId: json['vehicle_id'] as int?,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      locationId: json['location_id'] as int?,
      notes: json['notes'] as String?,
      cargoDescription: json['cargo_description'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'] as String)
          : null,
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
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
      'queue_number': queueNumber,
      'status': status.name,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (locationId != null) 'location_id': locationId,
      if (notes != null) 'notes': notes,
      if (cargoDescription != null) 'cargo_description': cargoDescription,
      if (weightKg != null) 'weight_kg': weightKg,
    };
  }

  Queue copyWith({
    QueueStatus? status,
    String? notes,
    String? cargoDescription,
    double? weightKg,
  }) {
    return Queue(
      id: id,
      queueNumber: queueNumber,
      status: status ?? this.status,
      vehicle: vehicle,
      vehicleId: vehicleId,
      location: location,
      locationId: locationId,
      notes: notes ?? this.notes,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      weightKg: weightKg ?? this.weightKg,
      arrivedAt: arrivedAt,
      processedAt: processedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class QueueHistory {
  final int id;
  final int queueId;
  final QueueStatus fromStatus;
  final QueueStatus toStatus;
  final String? notes;
  final DateTime? createdAt;

  QueueHistory({
    required this.id,
    required this.queueId,
    required this.fromStatus,
    required this.toStatus,
    this.notes,
    this.createdAt,
  });

  factory QueueHistory.fromJson(Map<String, dynamic> json) {
    return QueueHistory(
      id: json['id'] as int,
      queueId: json['queue_id'] as int,
      fromStatus:
          QueueStatusExtension.fromString(json['from_status'] as String),
      toStatus: QueueStatusExtension.fromString(json['to_status'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
