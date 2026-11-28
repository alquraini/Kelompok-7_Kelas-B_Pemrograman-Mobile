import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_theme.dart';

String _rp(int v) {
  final s = v
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return 'Rp $s';
}

enum _PayMethod {
  cash('Cash'),
  qris('QRIS'),
  transfer('Transfer');

  const _PayMethod(this.label);
  final String label;
}

/// Satu anggota patungan.
/// TODO(backend): petakan dari model asli di folder models/.
class _Member {
  const _Member({
    required this.name,
    required this.amount,
    required this.isPaid,
    required this.subtitle,
    this.isYou = false,
  });

  final String name;
  final int amount;
  final bool isPaid;
  final String subtitle; // contoh: "GoPay • 16:10 WIB", "Menunggu Transfer"
  final bool isYou;
}

class _OrderItem {
  const _OrderItem({
    required this.title,
    required this.note,
    required this.price,
  });

  final String title; // contoh: "2× Kenangan Mantan Large"
  final String note; // contoh: "@ Rp 24.000 • Raka & Dimas"
  final int price;
}

class _Charge {
  const _Charge(this.label, this.amount);

  final String label;
  final int amount;
}

class _BillDetail {
  const _BillDetail({
    required this.place,
    required this.dateLabel,
    required this.itemCount,
    required this.total,
    required this.members,
    required this.items,
    required this.subtotal,
    required this.charges,
  });

  final String place;
  final String dateLabel;
  final int itemCount;
  final int total;
  final List<_Member> members;
  final List<_OrderItem> items;
  final int subtotal;
  final List<_Charge> charges;

  int get paidCount => members.where((m) => m.isPaid).length;
  int get collected =>
      members.where((m) => m.isPaid).fold<int>(0, (s, m) => s + m.amount);
  List<_Member> get unpaid => members.where((m) => !m.isPaid).toList();
  int get remaining => unpaid.fold<int>(0, (s, m) => s + m.amount);
  int get percent => total == 0 ? 0 : (collected * 100) ~/ total;
  bool get isPaid => unpaid.isEmpty;

  _Member? get you {
    for (final m in members) {
      if (m.isYou) return m;
    }
    return null;
  }
}

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _initializedFromRoute = false;
  Map<String, dynamic>? _billData;
  int? _isSyncedFlag;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      final billId = arg is String ? arg : null;
      _loadBillFromLocal(billId: billId);
    }
  }

  Future<void> _loadBillFromLocal({String? billId}) async {
    setState(() => _isLoading = true);

    try {
      final rows = await LocalDbService.instance.getAllCachedBills();
      Map<String, dynamic>? matchedRow;

      if (billId != null && billId.isNotEmpty) {
        for (final row in rows) {
          if (row['id']?.toString() == billId) {
            matchedRow = row;
            break;
          }
        }
      }

      // Fallback ke tagihan terbaru di SQLite jika billId kosong atau tidak ditemukan
      matchedRow ??= rows.isNotEmpty ? rows.first : null;

      if (matchedRow != null) {
        final rawJson = matchedRow['data_json'] as String;
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        final syncedVal = matchedRow['is_synced'];
        final isSyncedInt = syncedVal is int
            ? syncedVal
            : int.tryParse(syncedVal?.toString() ?? '0') ?? 0;

        if (!mounted) return;
        setState(() {
          _billData = decoded;
          _isSyncedFlag = isSyncedInt;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _billData = null;
        _isSyncedFlag = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat rincian tagihan: $e')),
      );
    }
  }

  Future<void> _retrySyncAndReload() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      await SyncService().syncPendingBillsToFirestore();
      final currentId = _billData?['id']?.toString();
      await _loadBillFromLocal(billId: currentId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sinkronisasi tagihan diperbarui')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  int? _editing; // indeks anggota yang panel editnya terbuka
  bool _draftPaid = false;
  _PayMethod _draftMethod = _PayMethod.cash;
  bool _receiptOpen = true;

  // TODO(backend): ambil rincian dari SplitBillProvider berdasarkan id
  // yang dikirim lewat Navigator arguments.
  _BillDetail? _loadDetail() => null;

  void _startEdit(int index, _Member m) {
    setState(() {
      _editing = index;
      _draftPaid = m.isPaid;
      _draftMethod = _PayMethod.cash;
    });
  }

  void _cancelEdit() => setState(() => _editing = null);

  void _save(_Member m) {
    // TODO(backend): simpan status lunas, metode (_draftMethod), dan waktu.
    setState(() => _editing = null);
  }

  @override
  Widget build(BuildContext context) {
    final title = _billData?['title']?.toString() ?? 'Tagihan';
    final id = _billData?['id']?.toString() ?? '-';
    final amount = _billData?['amount']?.toString() ?? '-';
    final baseCurrency = _billData?['baseCurrency']?.toString() ?? '';
    final targetCurrency = _billData?['targetCurrency']?.toString() ?? '';
    final updatedAt = _billData?['updatedAt']?.toString() ?? '-';
    final statusText = _isSyncedFlag == 1
        ? 'Tersinkron ke Firestore (is_synced = 1)'
        : 'Menunggu sinkronisasi (is_synced = 0)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Pembagian Tagihan'),
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _retrySyncAndReload,
            tooltip: 'Sinkronkan Ulang',
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _billData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum ada data tagihan tersimpan di lokal.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text('ID: $id'),
                              Text('Nominal: $amount $baseCurrency -> $targetCurrency'),
                              Text('Diperbarui: $updatedAt'),
                              const SizedBox(height: 8),
                              Text(
                                'Status: $statusText',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _retrySyncAndReload,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(
                          _isSyncing ? 'Menyinkronkan...' : 'Coba Sinkron Ulang',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFAFAFF);
    final detail = _loadDetail();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text('Rincian Pembayaran',
            style: text.titleMedium?.copyWith(fontSize: 20)),
      ),
      body: detail == null
          ? const _EmptyDetail()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _SummaryCard(detail),
                const SizedBox(height: 20),
                _buildProgress(detail),
                const SizedBox(height: 20),
                _buildReceipt(detail),
              ],
            ),
    );
  }

  Widget _buildProgress(_BillDetail d) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.data_usage,
            title: 'Progres Pembayaran',
            subtitle: 'Status pelunasan & verifikasi manual Host',
            trailing: Text(
              '${d.percent}%',
              style: text.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: d.total == 0 ? 0 : d.collected / d.total,
              minHeight: 10,
              backgroundColor: extra.inputFill,
              color: cs.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                text: 'Terkumpul: ',
                style: text.bodySmall?.copyWith(color: muted),
                children: [
                  TextSpan(
                    text: _rp(d.collected),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              )),
              Text.rich(TextSpan(
                text: 'Target: ',
                style: text.bodySmall?.copyWith(color: muted),
                children: [
                  TextSpan(
                    text: _rp(d.total),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < d.members.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
            _MemberRow(
              member: d.members[i],
              editing: _editing == i,
              onEdit: () => _editing == i
                  ? _cancelEdit()
                  : _startEdit(i, d.members[i]),
            ),
            if (_editing == i) _editPanel(d.members[i]),
          ],
        ],
      ),
    );
  }

  /// Panel inline: toggle Lunas, metode bayar, Batal, Simpan.
  Widget _editPanel(_Member m) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: extra.inputFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lunas',
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _draftPaid,
                      onChanged: (v) => setState(() => _draftPaid = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              for (final method in _PayMethod.values)
                _MethodChip(
                  label: method.label,
                  selected: _draftMethod == method,
                  onTap: () => setState(() => _draftMethod = method),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waktu tercatat otomatis saat disimpan',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ),
              TextButton(onPressed: _cancelEdit, child: const Text('Batal')),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () => _save(m),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Simpan'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt(_BillDetail d) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    Widget body = Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in d.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: text.titleMedium?.copyWith(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(item.note,
                            style: text.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_rp(item.price),
                      style: text.titleMedium?.copyWith(fontSize: 16)),
                ],
              ),
            ),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          _AmountLine('Subtotal', d.subtotal),
          for (final c in d.charges) _AmountLine(c.label, c.amount),
          const SizedBox(height: 4),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Akhir Struk',
                  style: text.titleMedium?.copyWith(fontSize: 18)),
              Text(
                _rp(d.total),
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Item Pesanan Struk',
            subtitle: 'Rincian pesanan dari struk',
            trailing: Material(
              color: extra.inputFill,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _receiptOpen = !_receiptOpen),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedRotation(
                    turns: _receiptOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _receiptOpen
                ? body
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Kartu hijau di atas: status, nama tempat, total, bagianmu, sisa teman.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.detail);

  final _BillDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = cs.onSurface.withValues(alpha: 0.65);
    final you = detail.you;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color.lerp(extra.mint, cs.surface, 0.55)!, extra.mint],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            isPaid: detail.isPaid,
            paidCount: detail.paidCount,
            total: detail.members.length,
          ),
          const SizedBox(height: 16),
          Text(detail.place,
              style: text.headlineMedium?.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(detail.dateLabel,
                    style: text.bodySmall?.copyWith(color: muted)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL TRANSAKSI',
                  style: text.labelSmall
                      ?.copyWith(letterSpacing: 0.8, color: muted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _rp(detail.total),
                          style: text.headlineMedium?.copyWith(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: extra.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${detail.itemCount} Pesanan',
                          style: text.labelSmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Tagihanmu',
                  value: _rp(you?.amount ?? 0),
                  color: cs.surface.withValues(alpha: 0.6),
                  trailing: (you?.isPaid ?? false)
                      ? Icon(Icons.check_circle, size: 18, color: cs.secondary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Sisa Tagihan Teman',
                  value:
                      '${_rp(detail.remaining)} (${detail.unpaid.length} org)',
                  color: extra.beige.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.isPaid,
    required this.paidCount,
    required this.total,
  });

  final bool isPaid;
  final int paidCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isPaid ? cs.secondary : const Color(0xFF7A6652),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPaid ? 'Lunas' : 'Belum Lunas ($paidCount/$total Terbayar)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
  });

  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: text.titleMedium?.copyWith(fontSize: 16)),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih pembungkus (Progres Pembayaran, Item Pesanan Struk).
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232C) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: extra.inputFill,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium?.copyWith(fontSize: 20)),
              Text(subtitle, style: text.bodySmall?.copyWith(color: muted)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.editing,
    required this.onEdit,
  });

  final _Member member;
  final bool editing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(member.name,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(fontSize: 16)),
                    ),
                    if (member.isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: extra.mint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Kamu', style: text.labelSmall),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.subtitle,
                  style: text.bodySmall
                      ?.copyWith(color: member.isPaid ? muted : cs.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rp(member.amount),
                  style: text.titleMedium?.copyWith(fontSize: 17)),
              const SizedBox(height: 2),
              if (member.isPaid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: cs.secondary),
                    const SizedBox(width: 4),
                    Text('Lunas',
                        style: text.bodySmall?.copyWith(color: cs.secondary)),
                  ],
                )
              else
                Text('Belum Bayar',
                    style: text.bodySmall?.copyWith(color: cs.error)),
            ],
          ),
          const SizedBox(width: 12),
          Material(
            color: editing ? cs.secondary : extra.inputFill,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: editing ? cs.onSecondary : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
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
      color: selected ? cs.secondary : extra.inputFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: selected
                  ? cs.onSecondary
                  : cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine(this.label, this.amount);

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(_rp(amount), style: style),
        ],
      ),
    );
  }
}

/// Tampil saat rincian belum ada / tidak ditemukan.
class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.emptyHistory, height: 96),
            const SizedBox(height: 20),
            Text(
              'Rincian tagihan belum tersedia',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih salah satu tagihan dari Beranda untuk melihat rincian pembayarannya.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.maybePop(context),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}