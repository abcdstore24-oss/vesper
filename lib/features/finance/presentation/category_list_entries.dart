import '../../../core/db/app_database.dart';
import '../data/categories_table.dart';

/// One entry of the flattened Categories list: the "Archived" header or a row.
sealed class CategoryListEntry {
  const CategoryListEntry();
}

/// The header above the archived rows.
final class CategoryArchivedHeader extends CategoryListEntry {
  const CategoryArchivedHeader();
}

/// One category row.
final class CategoryRowEntry extends CategoryListEntry {
  const CategoryRowEntry(this.category);

  final CategoryRow category;
}

/// Flattens [categories] for a lazy ListView.builder: the ACTIVE rows A-Z (by
/// name, ignoring case), then, only if there are any, the "Archived" header
/// and the archived rows A-Z. System categories are never listed. Pure: no
/// BuildContext, no providers.
List<CategoryListEntry> flattenCategories(List<CategoryRow> categories) {
  int byName(CategoryRow a, CategoryRow b) {
    final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return c != 0 ? c : a.name.compareTo(b.name);
  }

  final managed = categories.where((c) => c.kind != CategoryKind.system);
  final active = managed.where((c) => !c.isArchived).toList()..sort(byName);
  final archived = managed.where((c) => c.isArchived).toList()..sort(byName);

  return [
    for (final c in active) CategoryRowEntry(c),
    if (archived.isNotEmpty) ...[
      const CategoryArchivedHeader(),
      for (final c in archived) CategoryRowEntry(c),
    ],
  ];
}
