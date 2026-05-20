class ObatModel {
  final String id;
  final String name;
  final String scheduleTime;
  final String? dosage;
  final String? notes;
  final DateTime createdAt;

  ObatModel({
    required this.id,
    required this.name,
    required this.scheduleTime,
    this.dosage,
    this.notes,
    required this.createdAt,
  });

  factory ObatModel.fromJson(Map<String, dynamic> json) {
    return ObatModel(
      id: json['id'],
      name: json['name'],
      scheduleTime: json['schedule_time'],
      dosage: json['dosage'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schedule_time': scheduleTime,
      'dosage': dosage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MedicationLogModel {
  final String id;
  final String userId;
  final String medicationId;
  final DateTime logDate;
  final bool isTaken;
  final DateTime? takenAt;

  MedicationLogModel({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.logDate,
    required this.isTaken,
    this.takenAt,
  });

  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationLogModel(
      id: json['id'],
      userId: json['user_id'],
      medicationId: json['medication_id'],
      logDate: DateTime.parse(json['log_date']),
      isTaken: json['is_taken'],
      takenAt: json['taken_at'] != null ? DateTime.parse(json['taken_at']) : null,
    );
  }
}