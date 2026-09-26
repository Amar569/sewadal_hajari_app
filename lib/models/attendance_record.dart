/// One attendance entry for a member on a specific satsang date.
class AttendanceRecord {
  final int? id;
  final int memberId;
  final String date; // stored as 'yyyy-MM-dd'
  final String day; // e.g. 'Sunday'
  final String status; // 'Present' | 'Absent' | '' (not marked)
  final String pvTime; // e.g. "7:15 PV" or "6:00 DT" - free text, same as chart

  AttendanceRecord({
    this.id,
    required this.memberId,
    required this.date,
    required this.day,
    required this.status,
    required this.pvTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'date': date,
      'day': day,
      'status': status,
      'pv_time': pvTime,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      date: map['date'] as String,
      day: map['day'] as String? ?? '',
      status: map['status'] as String? ?? '',
      pvTime: map['pv_time'] as String? ?? '',
    );
  }

  AttendanceRecord copyWith({
    int? id,
    int? memberId,
    String? date,
    String? day,
    String? status,
    String? pvTime,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      day: day ?? this.day,
      status: status ?? this.status,
      pvTime: pvTime ?? this.pvTime,
    );
  }
}
