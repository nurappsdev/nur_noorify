import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/mosque/models/mosque_item.dart';
import 'package:first_project/features/mosque/utils/mosque_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class MosqueListItem extends StatelessWidget {
  const MosqueListItem({super.key, required this.item, required this.onTapDirection});

  final MosqueItem item;
  final VoidCallback onTapDirection;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildThumbnail(glass),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: glass.textPrimary)),
                SizedBox(height: 2.h),
                Text(item.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, color: glass.textSecondary, fontWeight: FontWeight.w500)),
                SizedBox(height: 7.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: glass.isDark ? const Color(0x2A2EB8E6) : const Color(0x221EA8B8),
                    borderRadius: BorderRadius.circular(1000.r),
                  ),
                  child: Text(MosqueUtils.distanceText(item.distanceKm), style: TextStyle(fontSize: 11.sp, color: glass.accentSoft, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            height: 34.h,
            child: FilledButton.icon(
              onPressed: onTapDirection,
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                foregroundColor: glass.isDark ? const Color(0xFF072734) : Colors.white,
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                minimumSize: Size(0.w, 34.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.near_me_rounded, size: 14.sp),
              label: Text(MosqueUtils.text('Direction', 'দিকনির্দেশ'), style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(NoorifyGlassTheme glass) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 64.r, height: 64.r,
        child: Image.asset(
          'assets/images/header-bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: glass.isDark ? const Color(0x33214255) : const Color(0xFFE8F0F5),
            alignment: Alignment.center,
            child: Icon(Icons.location_city_rounded, color: glass.textSecondary),
          ),
        ),
      ),
    );
  }
}
