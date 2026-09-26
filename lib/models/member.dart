class Member {
  final int? id;
  final int srNo;
  final String name;
  final String perNo; // e.g. SNSD2015
  final String snsdNo; // e.g. 14878
  final String category; // 'Gents' or 'Ladies'
  final String subCategory; // '', 'Bal Sewadal - Gents', 'Bal Sewadal - Ladies'
  final int active;

  Member({
    this.id,
    required this.srNo,
    required this.name,
    required this.perNo,
    required this.snsdNo,
    required this.category,
    this.subCategory = '',
    this.active = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sr_no': srNo,
      'name': name,
      'per_no': perNo,
      'snsd_no': snsdNo,
      'category': category,
      'sub_category': subCategory,
      'active': active,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      srNo: map['sr_no'] as int,
      name: map['name'] as String,
      perNo: map['per_no'] as String? ?? '',
      snsdNo: map['snsd_no'] as String? ?? '',
      category: map['category'] as String,
      subCategory: map['sub_category'] as String? ?? '',
      active: map['active'] as int? ?? 1,
    );
  }

  Member copyWith({
    int? id,
    int? srNo,
    String? name,
    String? perNo,
    String? snsdNo,
    String? category,
    String? subCategory,
    int? active,
  }) {
    return Member(
      id: id ?? this.id,
      srNo: srNo ?? this.srNo,
      name: name ?? this.name,
      perNo: perNo ?? this.perNo,
      snsdNo: snsdNo ?? this.snsdNo,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      active: active ?? this.active,
    );
  }
}
