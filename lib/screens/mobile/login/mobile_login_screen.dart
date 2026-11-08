import 'package:flutter/material.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../widgets/mobile/mobile_sub_header.dart';

enum MobileRole { admin, sarpras }

extension MobileRoleX on MobileRole {
  String get label =>
      this == MobileRole.admin ? 'Admin / Pembina Rayon' : 'Sarpras Kesantrian';
}

class MobileSession {
  final MobileRole role;
  final String name;
  final String? email;
  const MobileSession({required this.role, required this.name, this.email});
}

/// Alur: Pilih peran -> Masuk. UI saja.
/// Jika [onSignIn] diisi (mis. dihubungkan ke autentikasi proyek), kolom kata
/// sandi muncul dan hasilnya dipakai sebagai sesi; jika kosong, hanya nama
/// yang diminta. Pembatasan akses sebenarnya tetap di Security Rules.
class MobileLoginScreen extends StatefulWidget {
  final void Function(MobileSession session) onSignedIn;
  final Future<MobileSession?> Function(
      MobileRole role, String email, String password)? onSignIn;

  const MobileLoginScreen({
    super.key,
    required this.onSignedIn,
    this.onSignIn,
  });

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  MobileRole? _role;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final role = _role!;
    final name = _name.text.trim();
    final email = _email.text.trim();

    if (widget.onSignIn == null) {
      if (name.isEmpty) {
        setState(() => _error = 'Nama wajib diisi.');
        return;
      }
      widget.onSignedIn(MobileSession(
          role: role, name: name, email: email.isEmpty ? null : email));
      return;
    }

    if (email.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await widget.onSignIn!(role, email, _pass.text);
      if (!mounted) return;
      if (s == null) {
        setState(() {
          _loading = false;
          _error = 'Email atau kata sandi salah.';
        });
      } else {
        widget.onSignedIn(s);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal masuk. Periksa koneksi lalu coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _role == null ? _chooser() : _form(),
    );
  }

  Widget _chooser() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MobileColors.locked.withAlpha(36),
          ),
          child: const Icon(Icons.lock_rounded,
              color: MobileColors.locked, size: 32),
        ),
        const SizedBox(height: 22),
        const Text('Smart Locker', style: MobileText.display),
        const SizedBox(height: 6),
        const Text('Pilih peran untuk melanjutkan', style: MobileText.label),
        const SizedBox(height: 28),
        _RoleCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Admin / Pembina Rayon',
          desc: 'Semua fitur dan semua rayon.',
          onTap: () => setState(() => _role = MobileRole.admin),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.visibility_rounded,
          title: 'Sarpras Kesantrian',
          desc: 'Mode pantau: status locker, riwayat, dan peringatan.',
          onTap: () => setState(() => _role = MobileRole.sarpras),
        ),
      ],
    );
  }

  Widget _form() {
    final needPass = widget.onSignIn != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        MobileSubHeader(
          title: 'Masuk',
          subtitle: _role!.label,
          onBack: () => setState(() {
            _role = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          enabled: !_loading,
          textCapitalization: TextCapitalization.words,
          style: MobileText.body,
          cursorColor: MobileColors.softBlue,
          decoration: const InputDecoration(
            hintText: 'Nama',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          style: MobileText.body,
          cursorColor: MobileColors.softBlue,
          decoration: InputDecoration(
            hintText: needPass ? 'Email' : 'Email (opsional)',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
        ),
        if (needPass) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            enabled: !_loading,
            obscureText: _hide,
            style: MobileText.body,
            cursorColor: MobileColors.softBlue,
            decoration: InputDecoration(
              hintText: 'Kata sandi',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(_hide
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: MobileText.caption.copyWith(color: MobileColors.denied)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MobileColors.softBlue,
              foregroundColor: MobileColors.bgTop,
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: MobileColors.bgTop),
                  )
                : const Text('Masuk'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MobileColors.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MobileColors.softBlue.withAlpha(36),
                ),
                child: Icon(icon, color: MobileColors.softBlue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MobileText.title.copyWith(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(desc, style: MobileText.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: MobileColors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
