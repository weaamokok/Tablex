import 'dart:math';

import 'fake_data.dart';

enum EmployeeStatus { active, inactive, onLeave }

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.salary,
    this.joinDate,
    required this.status,
    required this.isManager,
    this.avatarInitial = '',
  });

  final int id;
  final String name;
  final String email;
  final String department;
  final num salary;
  final DateTime? joinDate;
  final EmployeeStatus status;
  final bool isManager;
  final String avatarInitial;

  /// Parses a CSV/Excel import row (keyed by column title, e.g. from
  /// [TablexToolbar.importRowFactory]) back into an [Employee].
  factory Employee.fromMap(Map<String, String> map) {
    final id = int.tryParse(map['Id'] ?? '') ?? 0;
    final name = map['Name'] ?? '';
    final salary = double.tryParse(map['Salary'] ?? '') ?? 0.0;

    DateTime? joinDate;
    try {
      joinDate = DateTime.parse(map['Joined'] ?? '');
    } catch (_) {}

    var status = EmployeeStatus.active;
    final statusStr = (map['Status'] ?? '').toLowerCase();
    if (statusStr.contains('inactive')) {
      status = EmployeeStatus.inactive;
    } else if (statusStr.contains('leave')) {
      status = EmployeeStatus.onLeave;
    }

    final parts = name.split(' ');
    final first = parts.isNotEmpty ? parts.first.toLowerCase() : 'user';
    final last = parts.length > 1 ? parts.last.toLowerCase() : 'unknown';

    return Employee(
      id: id,
      name: name,
      email: '$first.$last@corp.io',
      department: map['Department'] ?? '',
      salary: salary,
      joinDate: joinDate,
      status: status,
      isManager: (map['Manager'] ?? 'false').toLowerCase() == 'true',
      avatarInitial: name.isNotEmpty ? name[0] : '',
    );
  }

  Employee copyWith({
    String? name,
    String? email,
    String? department,
    num? salary,
    DateTime? joinDate,
    EmployeeStatus? status,
    bool? isManager,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        department: department ?? this.department,
        salary: salary ?? this.salary,
        joinDate: joinDate ?? this.joinDate,
        status: status ?? this.status,
        isManager: isManager ?? this.isManager,
        avatarInitial: avatarInitial,
      );
}

Employee makeEmployee(int id, Random rng) {
  final first = firstNames[rng.nextInt(firstNames.length)];
  final last = lastNames[rng.nextInt(lastNames.length)];
  final name = '$first $last';
  final email = '${first.toLowerCase()}.${last.toLowerCase()}@corp.io';
  return Employee(
    id: id,
    name: name,
    email: email,
    department: departments[rng.nextInt(departments.length)],
    salary: (50000 + rng.nextInt(100000).toDouble()),
    // joinDate: DateTime.now().subtract(Duration(days: rng.nextInt(3650))),
    status: EmployeeStatus.values[rng.nextInt(EmployeeStatus.values.length)],
    isManager: rng.nextBool(),
    avatarInitial: first[0],
  );
}

List<Employee> get allEmployees => List.generate(
      500,
      (i) => makeEmployee(i + 1, Random(i * 31)),
    );
