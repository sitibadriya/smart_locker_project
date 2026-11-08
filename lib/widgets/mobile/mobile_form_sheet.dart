import 'package:flutter/material.dart';

import '../../core/theme/mobile_colors.dart';
import '../../core/theme/mobile_text_styles.dart';

/// Tombol + yang sama untuk semua halaman mobile (Locker, Santri, dst.).
/// heroTag dimatikan agar tidak bentrok antar halaman di IndexedStack.
class MobileAddFab extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const MobileAddFab({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: MobileColors.softBlue,
      foregroundColor: MobileColors.bgTop,
      elevation: 3,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.add_rounded),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

/// Deskripsi satu kolom isian pada form.
class MobileFieldSpec {
  final String key;
  final String label;
  final String? hint;
  final IconData icon;
  final String initial;
  final bool enabled;
  final TextCapitalization capitalization;

  const MobileFieldSpec({
    required this.key,
    required this.label,
    required this.icon,
    this.hint,
    this.initial = '',
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
  });
}

/// Form tambah/edit bergaya sama untuk semua halaman mobile.
///
/// - [onSubmit] menerima nilai tiap kolom (sudah di-trim, kunci = MobileFieldSpec.key).
///   Lempar exception jika gagal; pesannya tampil di dalam form.
/// - Mengembalikan true jika berhasil disimpan, false jika dibatalkan.
Future<bool> showMobileFormSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required IconData icon,
  required List<MobileFieldSpec> fields,
  required String submitLabel,
  required String requiredMessage,
  required Future<void> Function(Map<String, String> values) onSubmit,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _MobileFormSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      fields: fields,
      submitLabel: submitLabel,
      requiredMessage: requiredMessage,
      onSubmit: onSubmit,
    ),
  );
  return saved == true;
}

class _MobileFormSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<MobileFieldSpec> fields;
  final String submitLabel;
  final String requiredMessage;
  final Future<void> Function(Map<String, String> values) onSubmit;

  const _MobileFormSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    required this.submitLabel,
    required this.requiredMessage,
    required this.onSubmit,
  });

  @override
  State<_MobileFormSheet> createState() => _MobileFormSheetState();
}

class _MobileFormSheetState extends State<_MobileFormSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.initial),
  };

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    // Dilepas bersama State, jadi aman: TextField sudah lepas dari tree.
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final values = {
      for (final e in _controllers.entries) e.key: e.value.text.trim(),
    };

    if (values.values.any((v) => v.isEmpty)) {
      setState(() => _error = widget.requiredMessage);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal menyimpan: $e';
        });
      }
    }
  }

  InputDecoration _decoration(MobileFieldSpec f) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: 1.4),
        );

    return InputDecoration(
      labelText: f.label,
      hintText: f.hint,
      labelStyle: MobileText.label,
      floatingLabelStyle:
          MobileText.label.copyWith(color: MobileColors.softBlue),
      hintStyle: MobileText.label,
      prefixIcon: Icon(f.icon, color: MobileColors.textDim),
      filled: true,
      fillColor: f.enabled
          ? MobileColors.bgTop.withAlpha(170)
          : MobileColors.bgTop.withAlpha(90),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      disabledBorder: border(Colors.transparent),
      focusedBorder: border(MobileColors.softBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_loading,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: MobileColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MobileColors.textDim.withAlpha(110),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MobileColors.softBlue.withAlpha(36),
                        ),
                        child: Icon(widget.icon,
                            color: MobileColors.softBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: MobileText.title),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(widget.subtitle!,
                                  style: MobileText.caption),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < widget.fields.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    TextField(
                      controller: _controllers[widget.fields[i].key],
                      enabled: widget.fields[i].enabled && !_loading,
                      textCapitalization: widget.fields[i].capitalization,
                      cursorColor: MobileColors.softBlue,
                      style: MobileText.body,
                      decoration: _decoration(widget.fields[i]),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: MobileColors.denied.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: MobileColors.denied),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: MobileText.caption.copyWith(
                                  color: MobileColors.denied,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MobileColors.softBlue,
                            minimumSize: const Size.fromHeight(52),
                            side: BorderSide(
                                color: MobileColors.softBlue.withAlpha(90)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: MobileColors.softBlue,
                            foregroundColor: MobileColors.bgTop,
                            disabledBackgroundColor:
                                MobileColors.softBlue.withAlpha(120),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: MobileColors.bgTop,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(widget.submitLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
