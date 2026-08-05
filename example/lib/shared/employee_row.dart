import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/employee.dart';

TablexRow<Employee> employeeRowBuilder(Employee e) => TablexRow(
      data: e,
      key: e.id.toString(),
      cells: {
        'id': e.id,
        'name': e.name,
        'department': e.department,
        'salary': e.salary,
        'joinDate': e.joinDate,
        'status': e.status,
        'isManager': e.isManager,
        'actions': null,
      },
    );
