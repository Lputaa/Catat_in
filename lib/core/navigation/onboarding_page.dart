import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 3;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: progress + skip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  // Segmented progress bar
                  Expanded(
                    child: Row(
                      children: List.generate(_totalPages, (index) {
                        final isDone = index < _currentPage;
                        final isActive = index == _currentPage;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < _totalPages - 1 ? 6 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive || isDone)
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Skip — hidden on last page
                  AnimatedOpacity(
                    opacity: isLastPage ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: isLastPage,
                      child: TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Lewati',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(context),
                  _buildTimeValuePage(context),
                  _buildFeaturesPage(context),
                ],
              ),
            ),

            // ── Bottom controls ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  // Hint text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isLastPage
                          ? 'Pengaturan dapat diubah kapan saja'
                          : 'Geser layar untuk berpindah halaman',
                      key: ValueKey(isLastPage),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Next / Finish button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _nextPage,
                      icon: Icon(
                        isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isLastPage ? 'Mulai Catat-In!' : 'Lanjut',
                            key: ValueKey(isLastPage),
                            style: const TextStyle(fontSize: 17),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Screen 1: Welcome ─────────────────────────────────────────────────────
  Widget _buildWelcomePage(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero icon — compact (96px) so content below fits
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('📝', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Selamat datang',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kenali cara kerjamu\ndengan waktu',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Catat setiap aktivitas, ukur nilai waktumu, dan lihat laporan produktivitasmu — semua di satu tempat.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _FeatureRow(
            emoji: '⚡',
            title: 'Catat dalam hitungan detik',
            description:
                'Pilih template atau buat aktivitas baru dengan cepat.',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            emoji: '📊',
            title: 'Laporan otomatis tiap minggu',
            description: 'Lihat tren aktivitasmu dan ke mana waktumu pergi.',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  // ─── Screen 2: Time Value System ───────────────────────────────────────────
  Widget _buildTimeValuePage(BuildContext context) {
    final theme = Theme.of(context);

    const valueItems = [
      _ValueItem(
        emoji: '⭐',
        label: 'Investasi',
        points: 5,
        color: Color(0xFFF59E0B),
      ),
      _ValueItem(
        emoji: '✅',
        label: 'Produktif',
        points: 4,
        color: Color(0xFF10B981),
      ),
      _ValueItem(
        emoji: '🔧',
        label: 'Kebutuhan',
        points: 3,
        color: Color(0xFF3B82F6),
      ),
      _ValueItem(
        emoji: '🎯',
        label: 'Santai',
        points: 2,
        color: Color(0xFF8B5CF6),
      ),
      _ValueItem(
        emoji: '⚠️',
        label: 'Terbuang',
        points: 1,
        color: Color(0xFFEF4444),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Sistem nilai waktu',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.amber.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak semua waktu\nbernilai sama',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Setiap aktivitas punya bobot poin. Rata-rata tertimbang semua aktivitasmu menentukan Grade harian.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // 2×2 + 1 grid of value cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: valueItems
                .take(4)
                .map((item) => _ValueCard(item: item))
                .toList(),
          ),
          const SizedBox(height: 10),
          // 5th item full-width
          _ValueCard(item: valueItems.last, fullWidth: true),
          const SizedBox(height: 16),
          // Grade hint row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rata-rata ≥ 4.5 → Grade A · Semakin tinggi, semakin baik!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screen 3: Key Features / CTA ─────────────────────────────────────────
  Widget _buildFeaturesPage(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Siap untuk mulai?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.tertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai hari ini,\nsatu aktivitas pertama',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak perlu langsung sempurna. Cukup catat satu aktivitas hari ini dan lihat laporan pertamamu terbentuk.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _FeatureRow(
            emoji: '📅',
            title: 'Sync ke Google Calendar',
            description: 'Ekspor aktivitasmu langsung ke kalender favoritmu.',
            color: Colors.blue,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            emoji: '🔔',
            title: 'Pengingat harian',
            description: 'Kami ingatkan kamu sebelum lupa mencatat.',
            color: Colors.orange,
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            emoji: '📱',
            title: 'Widget home screen',
            description: 'Mulai tracking tanpa perlu membuka aplikasi.',
            color: theme.colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}

// ─── Value Item Model ────────────────────────────────────────────────────────
class _ValueItem {
  final String emoji;
  final String label;
  final int points;
  final Color color;

  const _ValueItem({
    required this.emoji,
    required this.label,
    required this.points,
    required this.color,
  });
}

// ─── Value Card ──────────────────────────────────────────────────────────────
class _ValueCard extends StatelessWidget {
  final _ValueItem item;
  final bool fullWidth;

  const _ValueCard({required this.item, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: fullWidth ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: fullWidth
          ? Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.points} poin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.points} poin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.color,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Feature Row ─────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _FeatureRow({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
