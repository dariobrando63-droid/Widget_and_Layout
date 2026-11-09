import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'auth_controller.dart';

/// Mengatur ulang kata sandi melalui jawaban keamanan akun lokal.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.auth, super.key});

  final AuthController auth;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _answer = TextEditingController();
  final _password = TextEditingController();
  String? _question;
  String? _message;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _answer.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final question = widget.auth.securityQuestionFor(_email.text);
    if (question == null) {
      setState(() {
        _message = 'Email atau jawaban keamanan salah.';
        _question = null;
      });
      return;
    }
    setState(() {
      _question = question;
      _message = null;
    });
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    String? error;
    try {
      error = await widget.auth.resetPassword(
        email: _email.text,
        jawaban: _answer.text,
        kataSandiBaru: _password.text,
      );
    } catch (exception) {
      error = 'Gagal menyimpan kata sandi: $exception';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = error ?? 'Kata sandi berhasil diubah. Silakan masuk.';
    });
    if (error == null) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Atur ulang kata sandi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Pulihkan akunmu', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Masukkan email dan jawaban keamanan yang dibuat saat mendaftar.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: validasiEmail,
                      ),
                      if (_question == null) ...[
                        const SizedBox(height: 18),
                        PillButton(
                          label: 'Lanjutkan',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _continue,
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        Text(_question!, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _answer,
                          enabled: !_busy,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Jawaban keamanan',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          validator: validasiJawaban,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Kata sandi baru',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              tooltip: _obscure
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: validasiKataSandi,
                        ),
                        const SizedBox(height: 18),
                        PillButton(
                          label: 'Simpan kata sandi',
                          icon: Icons.check_rounded,
                          busy: _busy,
                          onPressed: _reset,
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _message!.contains('berhasil')
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
