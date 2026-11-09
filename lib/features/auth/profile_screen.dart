import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'auth_controller.dart';

/// Mengelola nama, sandi, dan penghapusan akun lokal yang sedang aktif.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.auth, super.key});

  final AuthController auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _deleteForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _deletePassword = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void initState() {
    super.initState();
    _name.text = widget.auth.currentAccount?.nama ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _deletePassword.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_nameForm.currentState!.validate()) return;
    await _run(
      () => widget.auth.updateName(_name.text),
      success: 'Nama berhasil diperbarui.',
    );
  }

  Future<void> _savePassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    final error = await _run(
      () => widget.auth.updatePassword(
        kataSandiLama: _oldPassword.text,
        kataSandiBaru: _newPassword.text,
      ),
      success: 'Kata sandi berhasil diubah.',
    );
    if (error == null) {
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
  }

  Future<String?> _run(
    Future<String?> Function() action, {
    required String success,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String? error;
    try {
      error = await action();
    } catch (exception) {
      error = 'Perubahan gagal disimpan: $exception';
    }
    if (!mounted) return error;
    setState(() {
      _busy = false;
      _message = error ?? success;
      _messageIsError = error != null;
    });
    return error;
  }

  Future<void> _deleteAccount() async {
    if (!_deleteForm.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: const Text(
          'Akun dan data timer lokal milik akun ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await _run(
      () => widget.auth.deleteAccount(_deletePassword.text),
      success: 'Akun berhasil dihapus.',
    );
    if (error == null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = widget.auth.currentAccount?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      child: Text(inisialNama(_name.text)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name.text, style: theme.textTheme.titleLarge),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Nama tampilan', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              AppCard(
                child: Form(
                  key: _nameForm,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator: validasiNama,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      PillButton(
                        label: 'Simpan nama',
                        icon: Icons.check_rounded,
                        busy: _busy,
                        onPressed: _saveName,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Ubah kata sandi', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              AppCard(
                child: Form(
                  key: _passwordForm,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _oldPassword,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata sandi lama',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Kata sandi lama wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newPassword,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata sandi baru',
                        ),
                        validator: validasiKataSandi,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPassword,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi kata sandi baru',
                        ),
                        validator: (value) =>
                            validasiKonfirmasi(value, _newPassword.text),
                      ),
                      const SizedBox(height: 14),
                      PillButton(
                        label: 'Simpan kata sandi',
                        icon: Icons.lock_reset_rounded,
                        busy: _busy,
                        onPressed: _savePassword,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Hapus akun',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Form(
                  key: _deleteForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Data timer akun ini akan ikut dihapus dan tidak dapat dipulihkan.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _deletePassword,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi kata sandi',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Kata sandi wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _busy ? null : _deleteAccount,
                        child: const Text('Hapus akun dan data timer'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _messageIsError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
