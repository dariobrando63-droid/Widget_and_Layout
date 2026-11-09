import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'auth_controller.dart';

/// Form pendaftaran yang menyimpan akun hanya di perangkat ini.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.auth, super.key});

  final AuthController auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _answerController = TextEditingController();
  String _question = pertanyaanKeamanan.first;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _busy = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    String? error;
    try {
      error = await widget.auth.register(
        nama: _nameController.text,
        email: _emailController.text,
        kataSandi: _passwordController.text,
        pertanyaan: _question,
        jawaban: _answerController.text,
      );
    } catch (exception) {
      error = 'Pendaftaran gagal disimpan: $exception';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = error ?? 'Akun berhasil dibuat. Silakan masuk.';
      _messageIsError = error != null;
    });
    if (error == null) {
      if (mounted) {
        Navigator.of(context).pop(_emailController.text.trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = hitungKekuatanKataSandi(_passwordController.text);
    final strengthColor = switch (score) {
      0 || 1 => theme.colorScheme.error,
      2 => Colors.orange.shade700,
      3 => Colors.green.shade700,
      _ => theme.colorScheme.primary,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text(
                  'Mulai perjalanan fokusmu',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat akun lokal untuk menyimpan progres belajarmu di perangkat ini.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: validasiNama,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: validasiEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: validasiKataSandi,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: score / 4,
                                  minHeight: 6,
                                  color: strengthColor,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              labelKekuatanKataSandi(score),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: strengthColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: _obscureConfirmation,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi kata sandi',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Tampilkan konfirmasi'
                                  : 'Sembunyikan konfirmasi',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => validasiKonfirmasi(
                            value,
                            _passwordController.text,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Pertanyaan keamanan',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _question,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Pilih pertanyaan',
                            prefixIcon: Icon(Icons.help_outline_rounded),
                          ),
                          items: pertanyaanKeamanan
                              .map(
                                (question) => DropdownMenuItem(
                                  value: question,
                                  child: Text(
                                    question,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _question = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _answerController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Jawaban keamanan',
                            helperText: 'Jawaban ini diperlukan untuk mengatur ulang kata sandi.',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          validator: validasiJawaban,
                        ),
                        if (_message case final message?) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _messageIsError
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        PillButton(
                          label: 'Buat akun',
                          icon: Icons.person_add_alt_1_rounded,
                          busy: _busy,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () =>
                                    Navigator.of(context)
                                        .pushReplacementNamed(AppRoutes.login),
                          child: const Text('Sudah punya akun? Masuk'),
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
    );
  }
}
