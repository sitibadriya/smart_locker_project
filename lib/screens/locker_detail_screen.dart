import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mobile_colors.dart';
import '../core/theme/mobile_text_styles.dart';
import '../core/theme/mobile_theme.dart';

/// Detail locker.
///
/// - [dark] = false (default, dipakai web): tampilan terang seperti sebelumnya.
/// - [dark] = true (mobile): tema navy yang sama dengan halaman mobile lain.
/// - [canControl] = false (Sarpras / mode pantau): tombol Buka Loker dan
///   Reset / Ganti Pemilik tidak ditampilkan.
/// - [onRemoteUnlock]: opsional, mis. fungsi yang juga mencatat ke
///   remote-unlock-log. Jika null dipakai perintah lama (remoteCommand = UNLOCK).
class LockerDetailScreen extends StatefulWidget {
  final String idLocker;
  final String idPerangkat;
  final bool dark;
  final bool canControl;
  final Future<void> Function(String idLocker)? onRemoteUnlock;

  const LockerDetailScreen({
    super.key,
    required this.idLocker,
    required this.idPerangkat,
    this.dark = false,
    this.canControl = true,
    this.onRemoteUnlock,
  });

  @override
  State<LockerDetailScreen> createState() => _LockerDetailScreenState();
}

/// Kumpulan warna per mode, supaya satu layout dipakai untuk web dan mobile.
class _Palette {
  final Color card;
  final Color title;
  final Color sub;
  final Color accent;
  final Color ok;
  final Color warn;
  final Color danger;
  final Color divider;
  final List<Color> header;
  final Color primaryBg;
  final Color primaryFg;
  final double radius;

  const _Palette({
    required this.card,
    required this.title,
    required this.sub,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.danger,
    required this.divider,
    required this.header,
    required this.primaryBg,
    required this.primaryFg,
    required this.radius,
  });

  static const light = _Palette(
    card: Colors.white,
    title: Color(0xFF102746),
    sub: Color(0xFF64748B),
    accent: Color(0xFF00897B),
    ok: AppColors.success,
    warn: AppColors.warning,
    danger: AppColors.danger,
    divider: Color(0xFFE2E8F0),
    header: [Color(0xFF0B1F3A), Color(0xFF294A91)],
    primaryBg: Color(0xFF0B1F3A),
    primaryFg: Colors.white,
    radius: 20,
  );

  static const dark = _Palette(
    card: MobileColors.card,
    title: MobileColors.text,
    sub: MobileColors.textDim,
    accent: MobileColors.softBlue,
    ok: MobileColors.open,
    warn: MobileColors.locked,
    danger: MobileColors.denied,
    divider: Color(0x1FFFFFFF),
    header: [Color(0xFF1B3A82), MobileColors.card],
    primaryBg: MobileColors.softBlue,
    primaryFg: MobileColors.bgTop,
    radius: 28,
  );
}

class _LockerDetailScreenState extends State<LockerDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;

  _Palette get _p => widget.dark ? _Palette.dark : _Palette.light;

  // ============================================================
  // AKSI (isi perintah ke Firestore sama seperti sebelumnya)
  // ============================================================

  Future<void> _handleRemoteUnlock() async {
    if (!widget.canControl) return;

    setState(() => _isProcessing = true);
    try {
      if (widget.onRemoteUnlock != null) {
        await widget.onRemoteUnlock!(widget.idLocker);
      } else {
        await _firestore
            .collection('locker-config')
            .doc(widget.idLocker)
            .update({
          'remoteCommand': 'UNLOCK',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perintah Buka Loker berhasil dikirim!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengirim perintah: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleResetLocker() async {
    if (!widget.canControl) return;

    final p = _p;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.dark ? p.card : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.dark ? 28 : 20),
        ),
        title: Text(
          'Konfirmasi Reset / Ganti Pemilik',
          style: widget.dark
              ? MobileText.title
              : const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin mengosongkan Loker ${widget.idLocker}? '
          'Template sidik jari di sensor fisik akan dihapus dan kepemilikan santri akan dilepas.',
          style: widget.dark ? MobileText.body : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Batal',
              style: widget.dark
                  ? const TextStyle(color: MobileColors.softBlue)
                  : null,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.dark ? MobileColors.denied : Colors.red,
              foregroundColor: widget.dark ? MobileColors.bgTop : Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset Pemilik'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _firestore
            .collection('locker-config')
            .doc(widget.idLocker)
            .update({
          'resetCommand': 'RESET_OWNER',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perintah Reset dikirim ke ESP32...')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal melakukan reset: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scaffold = _buildScaffold(context);

    if (!widget.dark) return scaffold;

    // Mobile: halaman ini di-push dari luar MobileLayout, jadi tema dan latar
    // navy dipasang di sini, dan ikon status bar dibuat terang.
    return Theme(
      data: MobileTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: MobileBackground(child: scaffold),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = _p;
    final dark = widget.dark;

    return Scaffold(
      backgroundColor: dark ? Colors.transparent : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Locker ${widget.idLocker}',
          style: TextStyle(
            fontWeight: dark ? FontWeight.w800 : FontWeight.bold,
            fontSize: 20,
            color: dark ? MobileColors.text : Colors.white,
          ),
        ),
        backgroundColor: dark ? Colors.transparent : const Color(0xFF0B1F3A),
        foregroundColor: dark ? MobileColors.text : Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('locker-config')
            .doc(widget.idLocker)
            .snapshots(),
        builder: (context, snapshot) {
          final Map<String, dynamic> data =
              (snapshot.hasData && snapshot.data!.exists)
                  ? snapshot.data!.data() ?? <String, dynamic>{}
                  : <String, dynamic>{};

          final String activeSantriId =
              (data['activeSantriId'] ?? '').toString();
          final bool isOccupied = activeSantriId.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // KEPALA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: p.header,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(p.radius),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: dark ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius:
                            dark ? null : BorderRadius.circular(20),
                        color: Colors.white.withAlpha(dark ? 30 : 38),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: dark ? MobileColors.locked : Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.idLocker,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.idPerangkat,
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle('Status Perangkat'),
              const SizedBox(height: 12),
              _card(
                child: Row(
                  children: [
                    _iconBox(Icons.check_circle_outline_rounded, p.ok),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perangkat Aktif',
                            style: TextStyle(
                              color: p.title,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ESP32 terdaftar pada sistem.',
                            style: TextStyle(color: p.sub, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _sectionTitle('Informasi Locker'),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _detailRow(Icons.inventory_2_outlined, 'ID Locker',
                        widget.idLocker),
                    _divider(),
                    _detailRow(Icons.memory_outlined, 'ID Perangkat',
                        widget.idPerangkat),
                    _divider(),
                    _detailRow(Icons.fingerprint_rounded, 'Sensor', 'JM-101B'),
                    _divider(),
                    _detailRow(
                        Icons.lock_outline_rounded, 'Pengunci', 'Solenoid 12V'),
                    _divider(),
                    Row(
                      children: [
                        _iconBox(
                          isOccupied
                              ? Icons.person_rounded
                              : Icons.person_off_rounded,
                          isOccupied ? p.ok : p.warn,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status Pemilik',
                                  style: TextStyle(color: p.sub, fontSize: 12)),
                              const SizedBox(height: 3),
                              isOccupied
                                  ? FutureBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                      future: _firestore
                                          .collection('santri')
                                          .doc(activeSantriId)
                                          .get(),
                                      builder: (context, santriSnap) {
                                        var namaSantri = activeSantriId;
                                        if (santriSnap.hasData &&
                                            santriSnap.data!.exists) {
                                          final n = (santriSnap.data!
                                                      .data()?['nama'] ??
                                                  '')
                                              .toString()
                                              .trim();
                                          if (n.isNotEmpty) namaSantri = n;
                                        }
                                        return Text(
                                          'Terisi: $namaSantri',
                                          style: TextStyle(
                                            color: p.ok,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    )
                                  : Text(
                                      'Kosong / Belum Ada Pemilik',
                                      style: TextStyle(
                                        color: p.warn,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              if (!widget.canControl)
                _card(
                  child: Row(
                    children: [
                      _iconBox(Icons.visibility_outlined, p.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Mode pantau. Buka loker dan ganti pemilik hanya '
                          'bisa dilakukan Admin / Pembina.',
                          style: TextStyle(color: p.sub, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isProcessing)
                Center(
                  child: CircularProgressIndicator(
                    color: dark ? MobileColors.softBlue : null,
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Buka Loker (Remote Unlock)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primaryBg,
                    foregroundColor: p.primaryFg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(dark ? 20 : 12),
                    ),
                  ),
                  onPressed: _handleRemoteUnlock,
                ),
                const SizedBox(height: 12),
                if (isOccupied)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_remove_rounded),
                    label: const Text(
                      'Reset / Ganti Pemilik',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.danger,
                      side: BorderSide(color: p.danger),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(dark ? 20 : 12),
                      ),
                    ),
                    onPressed: _handleResetLocker,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // POTONGAN TAMPILAN
  // ============================================================

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
          color: widget.dark ? MobileColors.text : _p.title,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(widget.dark ? 28 : 18),
        ),
        child: child,
      );

  Widget _divider() => Divider(height: 24, color: _p.divider);

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 44,
        height: 44,
        decoration: widget.dark
            ? BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(36))
            : BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(13),
              ),
        child: Icon(icon, color: color, size: 22),
      );

  Widget _detailRow(IconData icon, String label, String value) {
    final p = _p;
    return Row(
      children: [
        _iconBox(icon, p.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: p.sub, fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: p.title,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
