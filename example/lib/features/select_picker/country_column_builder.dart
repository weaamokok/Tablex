import 'package:flutter/material.dart';
import 'package:tablex/tablex.dart';
import 'package:tablex_example/domain/country.dart';

final countryColumns = <TablexColumnBase<Country>>[
  TablexColumn<Country, String>(
    fieldKey: 'code',
    title: 'Code',
    width: 70,
    valueGetter: (c) => c.code,
  ),
  TablexColumn<Country, String>(
    fieldKey: 'name',
    title: 'Country',
    width: 180,
    valueGetter: (c) => c.name,
  ),
  TablexColumn<Country, String>(
    fieldKey: 'region',
    title: 'Region',
    width: 110,
    valueGetter: (c) => c.region,
    cellRenderer: TablexRenderers.statusChip(
      colors: {
        'Americas': Colors.blue,
        'Asia': Colors.purple,
        'Europe': Colors.teal,
        'Africa': Colors.orange,
      },
    ),
  ),
  TablexColumn<Country, int>(
    fieldKey: 'population',
    title: 'Population',
    width: 140,
    textAlign: TextAlign.end,
    valueGetter: (c) => c.population,
    formatter: (v) {
      if (v >= 1000000000) {
        return '${(v / 1000000000).toStringAsFixed(1)}B';
      } else if (v >= 1000000) {
        return '${(v / 1000000).toStringAsFixed(0)}M';
      }
      return v.toString();
    },
  ),
];
