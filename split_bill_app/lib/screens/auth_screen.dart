import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_routes.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  static const _iconSize = 20.0;

  bool _isLogin = true;
  bool _hidePass = true;
  bool _remember = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _formKey.currentState?.reset();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(value);
    if (!ok) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(backend): panggil AuthProvider (login atau register).
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  /// Kolom pill dengan ikon kiri, sesuai desain.
  InputDecoration _dec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder pill([Color? color]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide:
              color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
        );
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: _iconSize),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: pill(),
      enabledBorder: pill(),
      focusedBorder: pill(cs.secondary),
      errorBorder: pill(cs.error),
      focusedErrorBorder: pill(cs.error),
    );
  }

  Widget _rememberMe(ColorScheme cs, SplitInColors extra, TextTheme text) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _remember = !_remember),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: BorderSide(color: cs.onSurface, width: 1.5),
                fillColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected)
                      ? cs.primary
                      : extra.inputFill,
                ),
                checkColor: cs.onPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Ingat saya',
              style: text.bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    final extra = theme.extension<SplitInColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFFAFAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset(AppAssets.logo, height: 44),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Bagi tagihan bareng teman jadi mudah & transparan',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? cs.primaryContainer : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? 'Masuk Akun' : 'Daftar Akun',
                            style: text.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLogin
                                ? 'Lanjutkan sesi kumpul & patunganmu'
                                : 'Buat akun dan mulai patungan bareng teman',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                          const SizedBox(height: 20),
                          if (!_isLogin) ...[
                            const _FieldLabel('Nama Pengguna / Lengkap'),
                            TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: _dec(
                                hint: 'cth. Raka Aditya',
                                icon: Icons.person_outline,
                              ),
                              validator: _validateName,
                            ),
                            const SizedBox(height: 16),
                          ],
                          const _FieldLabel('Alamat Email'),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _dec(
                              hint: 'nama@email.com',
                              icon: Icons.mail_outline,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Kata Sandi'),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _hidePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _dec(
                              hint: 'Minimal 8 karakter',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _hidePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: _iconSize,
                                ),
                                onPressed: () => setState(() => _hidePass = !_hidePass),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),
                          if (_isLogin) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _rememberMe(cs, extra, text),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _submit,
                            iconAlignment: IconAlignment.end,
                            label: Text(
                              _isLogin ? 'Masuk ke Akun' : 'Daftar Akun Baru',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? 'Belum punya akun?'
                                    : 'Sudah punya akun?',
                                style: text.bodyMedium?.copyWith(color: muted),
                              ),
                              TextButton(
                                onPressed: _toggleMode,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isLogin ? 'Daftar Sekarang' : 'Masuk Sekarang',
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                    decoration: TextDecoration.underline,
                                    decorationColor: extra.beige,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

/// Label di atas kolom, dengan penanda "Wajib" di kanan.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.isRequired = true});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isRequired)
            Text(
              'Wajib',
              style: text.labelSmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
        ],
      ),
    );
  }
}