// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast
//
// Source files: lib/i18n/strings_<locale>.i18n.yaml
// Run `dart run build_runner build` to regenerate from the YAML source files.

import 'dart:ui';
import 'package:flutter/widgets.dart';

// ============================================================================
// Locale enum
// ============================================================================

/// Locales built into the Tablex package.
///
/// To add a new locale:
/// 1. Create `lib/i18n/strings_<lang>.i18n.yaml` with all keys translated.
/// 2. Add a case to [TablexLocale] and [TablexLocale.fromLocale].
/// 3. Add an implementation class at the bottom of `strings.g.dart` and wire
///    it into [TablexStrings.of].
/// 4. Run `dart run build_runner build` to regenerate this file from YAML.
enum TablexLocale {
  /// English (default / fallback)
  en,

  /// Arabic — عربي
  ar,

  /// Mandarin Chinese — 普通话
  zh,

  /// Hindi — हिन्दी
  hi,

  /// Spanish — Español
  es,

  /// French — Français
  fr,

  /// Bengali — বাংলা
  bn,

  /// Portuguese — Português
  pt,

  /// Russian — Русский
  ru,

  /// Urdu — اردو
  ur,

  /// Indonesian — Bahasa Indonesia
  id,

  /// German — Deutsch
  de,

  /// Japanese — 日本語
  ja,

  /// Hausa — Hausa (widely spoken in Nigeria and West Africa)
  ha,

  /// Vietnamese — Tiếng Việt
  vi,

  /// Italian — Italiano
  it;

  /// Maps a Flutter [Locale] to the closest supported [TablexLocale].
  /// Falls back to [TablexLocale.en] for any unsupported language code.
  static TablexLocale fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return TablexLocale.ar;
      case 'zh':
        return TablexLocale.zh;
      case 'hi':
        return TablexLocale.hi;
      case 'es':
        return TablexLocale.es;
      case 'fr':
        return TablexLocale.fr;
      case 'bn':
        return TablexLocale.bn;
      case 'pt':
        return TablexLocale.pt;
      case 'ru':
        return TablexLocale.ru;
      case 'ur':
        return TablexLocale.ur;
      case 'id':
        return TablexLocale.id;
      case 'de':
        return TablexLocale.de;
      case 'ja':
        return TablexLocale.ja;
      case 'ha':
        return TablexLocale.ha;
      case 'vi':
        return TablexLocale.vi;
      case 'it':
        return TablexLocale.it;
      default:
        return TablexLocale.en;
    }
  }
}

// ============================================================================
// Accessor — called once per build() by each widget
// ============================================================================

/// Returns the [TablexStrings] instance for the current locale.
///
/// Locale resolution order:
/// 1. [Localizations.maybeLocaleOf] — the app's locale (set via
///    `MaterialApp.locale` or a localization delegate).
/// 2. [PlatformDispatcher.instance.locale] — the device system locale.
/// 3. English, as a hard fallback.
///
/// Call this inside `build()` — it is a cheap map lookup.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final t = tablexStrings(context);
///   return Text(t.noData);
/// }
/// ```
TablexStrings tablexStrings(BuildContext context) {
  final locale = Localizations.maybeLocaleOf(context) ??
      PlatformDispatcher.instance.locale;
  return TablexStrings.of(TablexLocale.fromLocale(locale));
}

// ============================================================================
// Abstract base
// ============================================================================

/// All user-visible strings used by the Tablex package.
///
/// Obtain an instance with [tablexStrings]. Implement this class to add
/// a custom locale without forking the package:
///
/// ```dart
/// class MyTablexStrings implements TablexStrings {
///   @override String get noData => 'Keine Daten';
///   // … implement every getter …
/// }
/// ```
abstract class TablexStrings {
  /// Returns the implementation for [locale].
  factory TablexStrings.of(TablexLocale locale) {
    switch (locale) {
      case TablexLocale.ar:
        return _TablexStringsAr();
      case TablexLocale.zh:
        return _TablexStringsZh();
      case TablexLocale.hi:
        return _TablexStringsHi();
      case TablexLocale.es:
        return _TablexStringsEs();
      case TablexLocale.fr:
        return _TablexStringsFr();
      case TablexLocale.bn:
        return _TablexStringsBn();
      case TablexLocale.pt:
        return _TablexStringsPt();
      case TablexLocale.ru:
        return _TablexStringsRu();
      case TablexLocale.ur:
        return _TablexStringsUr();
      case TablexLocale.id:
        return _TablexStringsId();
      case TablexLocale.de:
        return _TablexStringsDe();
      case TablexLocale.ja:
        return _TablexStringsJa();
      case TablexLocale.ha:
        return _TablexStringsHa();
      case TablexLocale.vi:
        return _TablexStringsVi();
      case TablexLocale.it:
        return _TablexStringsIt();
      case TablexLocale.en:
        return _TablexStringsEn();
    }
  }

  // Grid
  /// Shown in the centre of the grid when there are no data rows.
  String get noData;

  // Pagination
  /// e.g. "Showing 1–13 of 120"
  String showing(int start, int end, int total);

  /// Shown instead of [showing] when [total] is 0.
  String get noResults;

  /// Tooltip for the previous-page icon button.
  String get previous;

  /// Tooltip for the next-page icon button.
  String get next;

  // Filters
  /// Label for the "clear all active filters" button in the filter bar.
  String get clearAll;

  /// Label for the cancel button in the filter dialog.
  String get cancel;

  /// Label for the apply button in the filter dialog.
  String get apply;

  /// Returns the localised label for a filter operator key.
  ///
  /// [operatorKey] matches [TablexFilterOperator.labelKey] — e.g.
  /// `'equals'`, `'greaterThan'`, `'isEmpty'`. Falls back to [operatorKey]
  /// itself for unknown keys so new operators degrade gracefully.
  String filterOperatorLabel(String operatorKey);

  // Selection
  /// e.g. "5 selected"
  String selected(int count);

  /// Label for the "clear selection" button in the selection summary bar.
  String get clear;

  // Column manager
  /// Tooltip for the [TablexColumnManagerButton].
  String get manageColumns;
}

// ============================================================================
// English
// ============================================================================

class _TablexStringsEn implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'equals',
    'notEquals': 'not equals',
    'contains': 'contains',
    'notContains': 'does not contain',
    'startsWith': 'starts with',
    'endsWith': 'ends with',
    'greaterThan': 'greater than',
    'greaterThanOrEqual': 'greater than or equal',
    'lessThan': 'less than',
    'lessThanOrEqual': 'less than or equal',
    'between': 'between',
    'isEmpty': 'is empty',
    'isNotEmpty': 'is not empty',
  };

  @override String get noData => 'No data';
  @override String showing(int start, int end, int total) => 'Showing $start–$end of $total';
  @override String get noResults => 'No results';
  @override String get previous => 'Previous';
  @override String get next => 'Next';
  @override String get clearAll => 'Clear all';
  @override String get cancel => 'Cancel';
  @override String get apply => 'Apply';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count selected';
  @override String get clear => 'Clear';
  @override String get manageColumns => 'Manage columns';
}

// ============================================================================
// Arabic — عربي
// ============================================================================

class _TablexStringsAr implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'يساوي',
    'notEquals': 'لا يساوي',
    'contains': 'يحتوي على',
    'notContains': 'لا يحتوي على',
    'startsWith': 'يبدأ بـ',
    'endsWith': 'ينتهي بـ',
    'greaterThan': 'أكبر من',
    'greaterThanOrEqual': 'أكبر من أو يساوي',
    'lessThan': 'أصغر من',
    'lessThanOrEqual': 'أصغر من أو يساوي',
    'between': 'بين',
    'isEmpty': 'فارغ',
    'isNotEmpty': 'غير فارغ',
  };

  @override String get noData => 'لا توجد بيانات';
  @override String showing(int start, int end, int total) => 'عرض $start–$end من $total';
  @override String get noResults => 'لا توجد نتائج';
  @override String get previous => 'السابق';
  @override String get next => 'التالي';
  @override String get clearAll => 'مسح الكل';
  @override String get cancel => 'إلغاء';
  @override String get apply => 'تطبيق';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => 'تم تحديد $count';
  @override String get clear => 'مسح';
  @override String get manageColumns => 'إدارة الأعمدة';
}

// ============================================================================
// Mandarin Chinese — 普通话
// ============================================================================

class _TablexStringsZh implements TablexStrings {
  static const _op = <String, String>{
    'equals': '等于',
    'notEquals': '不等于',
    'contains': '包含',
    'notContains': '不包含',
    'startsWith': '开头是',
    'endsWith': '结尾是',
    'greaterThan': '大于',
    'greaterThanOrEqual': '大于或等于',
    'lessThan': '小于',
    'lessThanOrEqual': '小于或等于',
    'between': '介于',
    'isEmpty': '为空',
    'isNotEmpty': '不为空',
  };

  @override String get noData => '暂无数据';
  @override String showing(int start, int end, int total) => '显示 $start–$end，共 $total 条';
  @override String get noResults => '无结果';
  @override String get previous => '上一页';
  @override String get next => '下一页';
  @override String get clearAll => '清除全部';
  @override String get cancel => '取消';
  @override String get apply => '应用';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '已选择 $count 项';
  @override String get clear => '清除';
  @override String get manageColumns => '管理列';
}

// ============================================================================
// Hindi — हिन्दी
// ============================================================================

class _TablexStringsHi implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'बराबर',
    'notEquals': 'बराबर नहीं',
    'contains': 'शामिल है',
    'notContains': 'शामिल नहीं',
    'startsWith': 'से शुरू होता है',
    'endsWith': 'से समाप्त होता है',
    'greaterThan': 'से बड़ा',
    'greaterThanOrEqual': 'से बड़ा या बराबर',
    'lessThan': 'से छोटा',
    'lessThanOrEqual': 'से छोटा या बराबर',
    'between': 'के बीच',
    'isEmpty': 'खाली है',
    'isNotEmpty': 'खाली नहीं है',
  };

  @override String get noData => 'कोई डेटा नहीं';
  @override String showing(int start, int end, int total) => '$start–$end दिखा रहे हैं, कुल $total में से';
  @override String get noResults => 'कोई परिणाम नहीं';
  @override String get previous => 'पिछला';
  @override String get next => 'अगला';
  @override String get clearAll => 'सभी साफ़ करें';
  @override String get cancel => 'रद्द करें';
  @override String get apply => 'लागू करें';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count चयनित';
  @override String get clear => 'साफ़ करें';
  @override String get manageColumns => 'कॉलम प्रबंधित करें';
}

// ============================================================================
// Spanish — Español
// ============================================================================

class _TablexStringsEs implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'igual a',
    'notEquals': 'no igual a',
    'contains': 'contiene',
    'notContains': 'no contiene',
    'startsWith': 'empieza con',
    'endsWith': 'termina con',
    'greaterThan': 'mayor que',
    'greaterThanOrEqual': 'mayor o igual que',
    'lessThan': 'menor que',
    'lessThanOrEqual': 'menor o igual que',
    'between': 'entre',
    'isEmpty': 'está vacío',
    'isNotEmpty': 'no está vacío',
  };

  @override String get noData => 'Sin datos';
  @override String showing(int start, int end, int total) => 'Mostrando $start–$end de $total';
  @override String get noResults => 'Sin resultados';
  @override String get previous => 'Anterior';
  @override String get next => 'Siguiente';
  @override String get clearAll => 'Borrar todo';
  @override String get cancel => 'Cancelar';
  @override String get apply => 'Aplicar';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count seleccionados';
  @override String get clear => 'Borrar';
  @override String get manageColumns => 'Gestionar columnas';
}

// ============================================================================
// French — Français
// ============================================================================

class _TablexStringsFr implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'est égal à',
    'notEquals': "n'est pas égal à",
    'contains': 'contient',
    'notContains': 'ne contient pas',
    'startsWith': 'commence par',
    'endsWith': 'se termine par',
    'greaterThan': 'supérieur à',
    'greaterThanOrEqual': 'supérieur ou égal à',
    'lessThan': 'inférieur à',
    'lessThanOrEqual': 'inférieur ou égal à',
    'between': 'entre',
    'isEmpty': 'est vide',
    'isNotEmpty': "n'est pas vide",
  };

  @override String get noData => 'Aucune donnée';
  @override String showing(int start, int end, int total) => 'Affichage $start–$end sur $total';
  @override String get noResults => 'Aucun résultat';
  @override String get previous => 'Précédent';
  @override String get next => 'Suivant';
  @override String get clearAll => 'Tout effacer';
  @override String get cancel => 'Annuler';
  @override String get apply => 'Appliquer';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count sélectionné(s)';
  @override String get clear => 'Effacer';
  @override String get manageColumns => 'Gérer les colonnes';
}

// ============================================================================
// Bengali — বাংলা
// ============================================================================

class _TablexStringsBn implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'সমান',
    'notEquals': 'সমান নয়',
    'contains': 'রয়েছে',
    'notContains': 'নেই',
    'startsWith': 'দিয়ে শুরু',
    'endsWith': 'দিয়ে শেষ',
    'greaterThan': 'এর চেয়ে বড়',
    'greaterThanOrEqual': 'এর চেয়ে বড় বা সমান',
    'lessThan': 'এর চেয়ে ছোট',
    'lessThanOrEqual': 'এর চেয়ে ছোট বা সমান',
    'between': 'এর মধ্যে',
    'isEmpty': 'খালি',
    'isNotEmpty': 'খালি নয়',
  };

  @override String get noData => 'কোনো তথ্য নেই';
  @override String showing(int start, int end, int total) => '$start–$end দেখানো হচ্ছে, মোট $total';
  @override String get noResults => 'কোনো ফলাফল নেই';
  @override String get previous => 'পূর্ববর্তী';
  @override String get next => 'পরবর্তী';
  @override String get clearAll => 'সব মুছুন';
  @override String get cancel => 'বাতিল';
  @override String get apply => 'প্রয়োগ করুন';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '${count}টি নির্বাচিত';
  @override String get clear => 'মুছুন';
  @override String get manageColumns => 'কলাম পরিচালনা করুন';
}

// ============================================================================
// Portuguese — Português
// ============================================================================

class _TablexStringsPt implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'igual a',
    'notEquals': 'diferente de',
    'contains': 'contém',
    'notContains': 'não contém',
    'startsWith': 'começa com',
    'endsWith': 'termina com',
    'greaterThan': 'maior que',
    'greaterThanOrEqual': 'maior ou igual a',
    'lessThan': 'menor que',
    'lessThanOrEqual': 'menor ou igual a',
    'between': 'entre',
    'isEmpty': 'está vazio',
    'isNotEmpty': 'não está vazio',
  };

  @override String get noData => 'Sem dados';
  @override String showing(int start, int end, int total) => 'Mostrando $start–$end de $total';
  @override String get noResults => 'Sem resultados';
  @override String get previous => 'Anterior';
  @override String get next => 'Próximo';
  @override String get clearAll => 'Limpar tudo';
  @override String get cancel => 'Cancelar';
  @override String get apply => 'Aplicar';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count selecionados';
  @override String get clear => 'Limpar';
  @override String get manageColumns => 'Gerenciar colunas';
}

// ============================================================================
// Russian — Русский
// ============================================================================

class _TablexStringsRu implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'равно',
    'notEquals': 'не равно',
    'contains': 'содержит',
    'notContains': 'не содержит',
    'startsWith': 'начинается с',
    'endsWith': 'заканчивается на',
    'greaterThan': 'больше',
    'greaterThanOrEqual': 'больше или равно',
    'lessThan': 'меньше',
    'lessThanOrEqual': 'меньше или равно',
    'between': 'между',
    'isEmpty': 'пусто',
    'isNotEmpty': 'не пусто',
  };

  @override String get noData => 'Нет данных';
  @override String showing(int start, int end, int total) => 'Показано $start–$end из $total';
  @override String get noResults => 'Нет результатов';
  @override String get previous => 'Назад';
  @override String get next => 'Вперёд';
  @override String get clearAll => 'Очистить всё';
  @override String get cancel => 'Отмена';
  @override String get apply => 'Применить';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => 'Выбрано $count';
  @override String get clear => 'Очистить';
  @override String get manageColumns => 'Управление столбцами';
}

// ============================================================================
// Urdu — اردو
// ============================================================================

class _TablexStringsUr implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'برابر',
    'notEquals': 'برابر نہیں',
    'contains': 'موجود ہے',
    'notContains': 'موجود نہیں',
    'startsWith': 'سے شروع ہوتا ہے',
    'endsWith': 'پر ختم ہوتا ہے',
    'greaterThan': 'سے زیادہ',
    'greaterThanOrEqual': 'سے زیادہ یا برابر',
    'lessThan': 'سے کم',
    'lessThanOrEqual': 'سے کم یا برابر',
    'between': 'کے درمیان',
    'isEmpty': 'خالی ہے',
    'isNotEmpty': 'خالی نہیں',
  };

  @override String get noData => 'کوئی ڈیٹا نہیں';
  @override String showing(int start, int end, int total) => '$start–$end دکھا رہے ہیں، کل $total میں سے';
  @override String get noResults => 'کوئی نتیجہ نہیں';
  @override String get previous => 'پچھلا';
  @override String get next => 'اگلا';
  @override String get clearAll => 'سب صاف کریں';
  @override String get cancel => 'منسوخ';
  @override String get apply => 'لاگو کریں';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count منتخب';
  @override String get clear => 'صاف کریں';
  @override String get manageColumns => 'کالم منظم کریں';
}

// ============================================================================
// Indonesian — Bahasa Indonesia
// ============================================================================

class _TablexStringsId implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'sama dengan',
    'notEquals': 'tidak sama dengan',
    'contains': 'mengandung',
    'notContains': 'tidak mengandung',
    'startsWith': 'dimulai dengan',
    'endsWith': 'diakhiri dengan',
    'greaterThan': 'lebih besar dari',
    'greaterThanOrEqual': 'lebih besar atau sama dengan',
    'lessThan': 'lebih kecil dari',
    'lessThanOrEqual': 'lebih kecil atau sama dengan',
    'between': 'antara',
    'isEmpty': 'kosong',
    'isNotEmpty': 'tidak kosong',
  };

  @override String get noData => 'Tidak ada data';
  @override String showing(int start, int end, int total) => 'Menampilkan $start–$end dari $total';
  @override String get noResults => 'Tidak ada hasil';
  @override String get previous => 'Sebelumnya';
  @override String get next => 'Berikutnya';
  @override String get clearAll => 'Hapus semua';
  @override String get cancel => 'Batal';
  @override String get apply => 'Terapkan';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count dipilih';
  @override String get clear => 'Hapus';
  @override String get manageColumns => 'Kelola kolom';
}

// ============================================================================
// German — Deutsch
// ============================================================================

class _TablexStringsDe implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'gleich',
    'notEquals': 'ungleich',
    'contains': 'enthält',
    'notContains': 'enthält nicht',
    'startsWith': 'beginnt mit',
    'endsWith': 'endet mit',
    'greaterThan': 'größer als',
    'greaterThanOrEqual': 'größer oder gleich',
    'lessThan': 'kleiner als',
    'lessThanOrEqual': 'kleiner oder gleich',
    'between': 'zwischen',
    'isEmpty': 'ist leer',
    'isNotEmpty': 'ist nicht leer',
  };

  @override String get noData => 'Keine Daten';
  @override String showing(int start, int end, int total) => 'Zeige $start–$end von $total';
  @override String get noResults => 'Keine Ergebnisse';
  @override String get previous => 'Zurück';
  @override String get next => 'Weiter';
  @override String get clearAll => 'Alle löschen';
  @override String get cancel => 'Abbrechen';
  @override String get apply => 'Anwenden';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count ausgewählt';
  @override String get clear => 'Löschen';
  @override String get manageColumns => 'Spalten verwalten';
}

// ============================================================================
// Japanese — 日本語
// ============================================================================

class _TablexStringsJa implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'と等しい',
    'notEquals': 'と等しくない',
    'contains': 'を含む',
    'notContains': 'を含まない',
    'startsWith': 'で始まる',
    'endsWith': 'で終わる',
    'greaterThan': 'より大きい',
    'greaterThanOrEqual': '以上',
    'lessThan': 'より小さい',
    'lessThanOrEqual': '以下',
    'between': 'の間',
    'isEmpty': '空',
    'isNotEmpty': '空ではない',
  };

  @override String get noData => 'データなし';
  @override String showing(int start, int end, int total) => '$total件中$start–$end件を表示';
  @override String get noResults => '結果なし';
  @override String get previous => '前へ';
  @override String get next => '次へ';
  @override String get clearAll => 'すべてクリア';
  @override String get cancel => 'キャンセル';
  @override String get apply => '適用';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count件選択中';
  @override String get clear => 'クリア';
  @override String get manageColumns => '列の管理';
}

// ============================================================================
// Hausa — هَوْسَ (widely spoken in Nigeria and West Africa)
// ============================================================================

class _TablexStringsHa implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'daidai',
    'notEquals': 'ba daidai ba',
    'contains': 'yana ƙunshe da',
    'notContains': 'ba ya ƙunshe da',
    'startsWith': 'yana farawa da',
    'endsWith': 'yana ƙarewa da',
    'greaterThan': 'ya fi',
    'greaterThanOrEqual': 'ya fi ko daidai',
    'lessThan': 'ya ƙasa da',
    'lessThanOrEqual': 'ya ƙasa ko daidai',
    'between': 'tsakanin',
    'isEmpty': 'fanko',
    'isNotEmpty': 'ba fanko ba',
  };

  @override String get noData => 'Babu bayani';
  @override String showing(int start, int end, int total) => 'Ana nuna $start–$end daga cikin $total';
  @override String get noResults => 'Babu sakamako';
  @override String get previous => 'Na baya';
  @override String get next => 'Na gaba';
  @override String get clearAll => 'Share duk';
  @override String get cancel => 'Soke';
  @override String get apply => 'Yi';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => 'An zaɓi $count';
  @override String get clear => 'Share';
  @override String get manageColumns => 'Sarrafa ginshiƙai';
}

// ============================================================================
// Vietnamese — Tiếng Việt
// ============================================================================

class _TablexStringsVi implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'bằng',
    'notEquals': 'không bằng',
    'contains': 'chứa',
    'notContains': 'không chứa',
    'startsWith': 'bắt đầu bằng',
    'endsWith': 'kết thúc bằng',
    'greaterThan': 'lớn hơn',
    'greaterThanOrEqual': 'lớn hơn hoặc bằng',
    'lessThan': 'nhỏ hơn',
    'lessThanOrEqual': 'nhỏ hơn hoặc bằng',
    'between': 'giữa',
    'isEmpty': 'trống',
    'isNotEmpty': 'không trống',
  };

  @override String get noData => 'Không có dữ liệu';
  @override String showing(int start, int end, int total) => 'Hiển thị $start–$end trong $total';
  @override String get noResults => 'Không có kết quả';
  @override String get previous => 'Trước';
  @override String get next => 'Tiếp';
  @override String get clearAll => 'Xóa tất cả';
  @override String get cancel => 'Hủy';
  @override String get apply => 'Áp dụng';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => 'Đã chọn $count';
  @override String get clear => 'Xóa';
  @override String get manageColumns => 'Quản lý cột';
}

// ============================================================================
// Italian — Italiano
// ============================================================================

class _TablexStringsIt implements TablexStrings {
  static const _op = <String, String>{
    'equals': 'uguale a',
    'notEquals': 'diverso da',
    'contains': 'contiene',
    'notContains': 'non contiene',
    'startsWith': 'inizia con',
    'endsWith': 'finisce con',
    'greaterThan': 'maggiore di',
    'greaterThanOrEqual': 'maggiore o uguale a',
    'lessThan': 'minore di',
    'lessThanOrEqual': 'minore o uguale a',
    'between': 'tra',
    'isEmpty': 'è vuoto',
    'isNotEmpty': 'non è vuoto',
  };

  @override String get noData => 'Nessun dato';
  @override String showing(int start, int end, int total) => 'Mostrando $start–$end di $total';
  @override String get noResults => 'Nessun risultato';
  @override String get previous => 'Precedente';
  @override String get next => 'Successivo';
  @override String get clearAll => 'Cancella tutto';
  @override String get cancel => 'Annulla';
  @override String get apply => 'Applica';
  @override String filterOperatorLabel(String k) => _op[k] ?? k;
  @override String selected(int count) => '$count selezionati';
  @override String get clear => 'Cancella';
  @override String get manageColumns => 'Gestisci colonne';
}
