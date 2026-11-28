import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_routes.dart';

/// Ringkasan satu tagihan untuk kartu di beranda.
/// TODO(backend): petakan dari model asli di folder models/.
class _Bill {
  const _Bill({
    required this.place,
    required this.total,
    required this.date,
    required this.paidCount,
    required this.memberCount,
  });

  final String place;
  final int total;
  final String date;
  final int paidCount;
  final int memberCount;

  bool get isPaid => paidCount >= memberCount;
}

enum _Filter { semua, belumLunas, lunas }

String _rp(int v) {
  final s = v
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return 'Rp $s';
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Filter _filter = _Filter.semua;

  static const _labels = {
    _Filter.semua: 'Semua',
    _Filter.belumLunas: 'Belum Lunas',
    _Filter.lunas: 'Lunas',
  };

  // TODO(backend): ambil daftar tagihan dari SplitBillProvider.
  List<_Bill> get _bills => const <_Bill>[];

  // TODO(backend): ambil nama pengguna dari AuthProvider.
  String? get _name => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    final all = _bills;
    final shown = all.where((b) {
      switch (_filter) {
        case _Filter.semua:
          return true;
        case _Filter.belumLunas:
          return !b.isPaid;
        case _Filter.lunas:
          return b.isPaid;
      }
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFFAFAFF),
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Dashboard Split Bill', style: text.headlineSmall),
            const SizedBox(height: 20),
            _Header(name: _name),
            const SizedBox(height: 20),
            const _HeroCard(),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Riwayat Split Bill',
                    style: text.titleMedium?.copyWith(fontSize: 20)),
                Text('${shown.length} Tagihan',
                    style: text.bodySmall?.copyWith(color: muted)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final f in _Filter.values)
                  _FilterPill(
                    label: _labels[f]!,
                    selected: f == _filter,
                    onTap: () => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (shown.isEmpty)
              _EmptyState(filter: _filter)
            else
              for (final b in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BillCard(bill: b, index: all.indexOf(b)),
                ),
          ],
        ),
      ),
    );
  }
}

/// Avatar, sapaan, dan lonceng notifikasi.
class _Header extends StatelessWidget {
  const _Header({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;

    return Row(
      children: [
        // TODO: ganti dengan foto profil pengguna.
        CircleAvatar(
          radius: 28,
          backgroundColor: extra.inputFill,
          child: Icon(Icons.person_outline, color: cs.onSurface),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: text.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
              ),
              Text(
                name == null ? 'Halo!' : '$name!',
                style: text.titleMedium
                    ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: extra.inputFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none),
            ),
            Positioned(
              top: 14,
              right: 15,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartu krem "Input Split Bill".
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;

    return Material(
      color: extra.beige,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => Navigator.pushNamed(context, AppRoutes.createBill),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Input Split Bill',
                        style: text.titleMedium?.copyWith(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text(
                      'Catat rincian pesanan',
                      style: text.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: cs.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final extra = theme.extension<SplitInColors>()!;

    return Material(
      color: selected ? cs.primary : extra.inputFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: selected
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill, required this.index});

  final _Bill bill;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;

    final tints = [extra.mint, extra.beige, extra.sky];
    final tint = tints[index % tints.length];

    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => Navigator.pushNamed(context, AppRoutes.billDetail),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(isPaid: bill.isPaid),
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.north_east,
                        size: 22, color: cs.onPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(bill.place,
                  style: text.titleMedium?.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text(_rp(bill.total),
                  style: text.headlineMedium?.copyWith(fontSize: 26)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(bill.date),
                  bill.isPaid
                      ? _InfoChip(
                          'Lunas • ${bill.memberCount} orang',
                          icon: Icons.check_circle_outline,
                        )
                      : _InfoChip(
                          '${bill.paidCount}/${bill.memberCount} orang lunas',
                          icon: Icons.group_outlined,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? cs.surface : cs.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPaid ? 'Lunas' : 'Belum Lunas',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isPaid ? cs.onSurface : cs.onPrimary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, {this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    final isLunas = filter == _Filter.lunas;
    final title =
        isLunas ? 'Belum ada tagihan lunas' : 'Belum ada tagihan aktif';
    final desc = switch (filter) {
      _Filter.semua =>
        'Semua catatan patungan dan riwayat pembagian tagihanmu akan muncul di sini setelah kamu membuat split bill baru.',
      _Filter.belumLunas => 'Tagihan yang belum lunas akan muncul di sini.',
      _Filter.lunas => 'Tagihan yang sudah lunas akan muncul di sini.',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Image.asset(
            isLunas ? AppAssets.emptyHistory : AppAssets.emptyDashboard,
            height: 96,
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom nav: Beranda, Riwayat, Profil.
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Beranda',
                selected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Riwayat',
                onTap: () {
                  // TODO: buka layar Riwayat (belum ada route).
                },
              ),
              _NavItem(
                icon: Icons.account_circle_outlined,
                label: 'Profil',
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<SplitInColors>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? extra.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}