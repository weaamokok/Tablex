import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/country.dart';

TablexRow<Country> countryRowBuilder(Country c) => TablexRow(
      data: c,
      key: c.code,
      cells: {
        'code': c.code,
        'name': c.name,
        'region': c.region,
        'population': c.population,
      },
    );
