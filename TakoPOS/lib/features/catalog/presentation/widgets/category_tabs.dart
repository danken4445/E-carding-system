import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/catalog/presentation/providers/catalog_provider.dart';

/// Horizontal scrolling category tabs
class CategoryTabs extends ConsumerWidget {
  const CategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Container(
      height: AppSizing.categoryTabHeight + AppSpacing.sm * 2,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          final colorIndex = index % AppColors.categoryColors.length;
          final bgColor = AppColors.categoryColors[colorIndex];

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _CategoryChip(
              name: category.name,
              isSelected: isSelected,
              backgroundColor: bgColor,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = category.id;
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.isSelected,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : backgroundColor,
      borderRadius: AppRadius.chipRadius,
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.chipRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          constraints: const BoxConstraints(
            minHeight: AppSizing.categoryTabHeight,
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
