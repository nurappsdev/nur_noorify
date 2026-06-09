import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/dua/models/dua_meta.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class MainCategoryGrid extends StatelessWidget {
  const MainCategoryGrid({
    super.key,
    required this.items,
    required this.isBangla,
    required this.onTap,
  });

  final List<MainCategoryTileData> items;
  final bool isBangla;
  final ValueChanged<MainCategoryTileData> onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final itemWidth = (MediaQuery.of(context).size.width - 38) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => onTap(item),
          child: SizedBox(
            width: itemWidth,
            child: NoorifyGlassCard(
              radius: BorderRadius.circular(16.r),
              padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46.r,
                    height: 46.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: glass.isDark ? const Color(0x33243C46) : const Color(0xFFE5F5F6),
                    ),
                    child: Icon(item.meta.icon, color: glass.accent),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    isBangla ? item.meta.titleBn : item.meta.titleEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    isBangla ? item.meta.subtitleBn : item.meta.subtitleEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5.sp, color: glass.textSecondary),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      CountPill(text: isBangla ? '${item.subCategoryCount} টাইল' : '${item.subCategoryCount} tiles'),
                      CountPill(text: isBangla ? '${item.duaCount} দুআ' : '${item.duaCount} duas'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class SubCategoryGrid extends StatelessWidget {
  const SubCategoryGrid({
    super.key,
    required this.items,
    required this.isBangla,
    required this.onTap,
  });

  final List<SubCategoryTileData> items;
  final bool isBangla;
  final ValueChanged<SubCategoryTileData> onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final itemWidth = (MediaQuery.of(context).size.width - 38) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => onTap(item),
          child: SizedBox(
            width: itemWidth,
            child: NoorifyGlassCard(
              radius: BorderRadius.circular(16.r),
              padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
              child: Column(
                children: [
                  Container(
                    width: 70.r,
                    height: 70.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glass.isDark ? const Color(0x33243C46) : const Color(0xFFE5F5F6),
                    ),
                    child: Icon(item.meta.icon, size: 32.sp, color: glass.textSecondary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isBangla ? item.meta.titleBn : item.meta.titleEn,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  CountPill(text: isBangla ? '${item.duaCount} দুআ' : '${item.duaCount} duas'),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: glass.isDark ? const Color(0x2A2EB8E6) : const Color(0x221EA8B8),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: glass.accent, fontSize: 11.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    required this.retryText,
  });

  final String error;
  final VoidCallback onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: glass.textSecondary)),
            SizedBox(height: 10.h),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                foregroundColor: glass.isDark ? const Color(0xFF052830) : Colors.white,
              ),
              child: Text(retryText),
            ),
          ],
        ),
      ),
    );
  }
}
