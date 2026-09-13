import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shop_product.dart';
import '../../services/shop_service.dart';
import '../../services/firebase_service.dart';
import '../../services/theme_service.dart';

class ShopCategoryProductsScreen extends StatefulWidget {
  final String category;

  const ShopCategoryProductsScreen({super.key, required this.category});

  @override
  State<ShopCategoryProductsScreen> createState() =>
      _ShopCategoryProductsScreenState();
}

class _ShopCategoryProductsScreenState
    extends State<ShopCategoryProductsScreen> {
  static const Color primary = Color(0xFFE91E8C);

  final ShopService _shopService = ShopService();
  String _userCountry = '';
  bool _countryLoaded = false;

  static const List<Color> _palette = [
    Color(0xFFE91E8C),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
  }

  Future<void> _loadUserCountry() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _countryLoaded = true);
        return;
      }
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _userCountry = (doc.data()?['country'] ?? '').toString();
        _countryLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _countryLoaded = true);
    }
  }

  int _crossAxisCountFor(double width) {
    if (width >= 1000) return 5;
    if (width >= 720) return 4;
    if (width >= 480) return 3;
    return 2;
  }

  Future<void> _openProduct(String url) async {
    final online = FirestoreService.isOnline.value;
    if (!online) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          content: Text('No internet connection',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        ),
      );
      return;
    }

    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not open the product page',
              style: GoogleFonts.poppins(fontSize: 13)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDarkMode;
    final bg = ThemeService.bg(isDark);
    final surface = ThemeService.surface(isDark);
    final textPrimary = ThemeService.textPrimary(isDark);
    final textSecondary = ThemeService.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: primary),
        title: Text(widget.category,
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
      ),
      body: StreamBuilder<List<ShopProduct>>(
        stream: _shopService.streamActiveProductsByCategory(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !_countryLoaded) {
            return const Center(
                child: CircularProgressIndicator(color: primary));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 56, color: textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('No products yet',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('Please check back soon',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            );
          }

          final visibleProducts =
              products.where((p) => p.visibleTo(_userCountry)).toList();

          if (visibleProducts.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_rounded,
                        size: 56, color: textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Shop is currently not available\nin your region',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userCountry.isEmpty
                          ? 'We\'re working on bringing these products to more countries soon.'
                          : 'We\'re working on bringing these products to $_userCountry soon.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _crossAxisCountFor(constraints.maxWidth);
              final rows = <List<int>>[];
              for (var i = 0; i < visibleProducts.length; i += crossAxisCount) {
                final end = (i + crossAxisCount > visibleProducts.length)
                    ? visibleProducts.length
                    : i + crossAxisCount;
                rows.add(List.generate(end - i, (k) => i + k));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    for (final row in rows) ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var c = 0; c < crossAxisCount; c++) ...[
                              if (c < row.length)
                                Expanded(
                                  child: _ProductCard(
                                    product: visibleProducts[row[c]],
                                    isDark: isDark,
                                    palette: _palette[row[c] % _palette.length],
                                    onShopNow: () => _openProduct(
                                        visibleProducts[row[c]].productUrl),
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                              if (c != crossAxisCount - 1)
                                const SizedBox(width: 14),
                            ],
                          ],
                        ),
                      ),
                      if (row != rows.last) const SizedBox(height: 14),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ShopProduct product;
  final bool isDark;
  final Color palette;
  final VoidCallback onShopNow;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.palette,
    required this.onShopNow,
  });

  Widget _image() {
    final placeholderBg = isDark
        ? ThemeService.darkTintedChip(palette, amount: 0.18)
        : palette.withValues(alpha: 0.08);
    if (product.imageBase64.isEmpty) {
      return Container(
        color: placeholderBg,
        alignment: Alignment.center,
        child:
            Icon(Icons.image_not_supported_rounded, color: palette, size: 32),
      );
    }
    try {
      final bytes = base64Decode(product.imageBase64);
      return Container(
        color: placeholderBg,
        alignment: Alignment.center,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return Container(
        color: placeholderBg,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_rounded, color: palette, size: 32),
      );
    }
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Bestseller':
        return const Color(0xFFF59E0B);
      case 'New':
        return const Color(0xFF10B981);
      case 'Sale':
        return Colors.red.shade400;
      case 'Trending':
        return const Color(0xFF8B5CF6);
      default:
        return palette;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = ThemeService.surface(isDark);
    final textPrimary = ThemeService.textPrimary(isDark);
    final textSecondary = ThemeService.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: palette.withValues(alpha: isDark ? 0.30 : 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: 0.5,
          ),
        ],
        border: Border.all(
          color: palette.withValues(alpha: isDark ? 0.24 : 0.14),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _image(),
                  ),
                ),
                if (product.tag != null && product.tag!.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tagColor(product.tag!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.tag!,
                        style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            product.brand,
            style: GoogleFonts.poppins(fontSize: 10.5, color: textSecondary),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onShopNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Shop Now',
                style: GoogleFonts.poppins(
                    fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
