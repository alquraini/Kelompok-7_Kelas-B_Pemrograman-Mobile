import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

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
      ),
    );
  }
}