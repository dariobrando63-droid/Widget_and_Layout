import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'auth_controller.dart';

/// Form masuk ke akun lokal yang tersimpan di perangkat.
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.auth, this.initialEmail = '', super.key});

  final AuthController auth;
  final String initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _busy = false;
  bool _enteringGuest = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
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
      error = await widget.auth.login(
        email: _emailController.text,
        kataSandi: _passwordController.text,
        ingatSaya: _rememberMe,
      );
    } catch (exception) {
      error = 'Gagal menyimpan sesi lokal: $exception';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = error;
      _messageIsError = error != null;
    });
  }

  Future<void> _openRegistration() async {
    final email = await Navigator.pushNamed<String>(
      context,
      AppRoutes.register,
    );
    if (!mounted || email == null) return;
    _emailController.text = email;
  }

  Future<void> _enterGuest() async {
    setState(() {
      _enteringGuest = true;
      _message = null;
    });
    try {
      await widget.auth.enterGuest();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _message = 'Gagal membuka sesi tamu: $exception';
        _messageIsError = true;
        _enteringGuest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                _AuthBrand(),
                const SizedBox(height: 32),
                Text(
                  'Selamat datang kembali',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk dan lanjutkan satu langkah fokusmu.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: validasiEmail,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
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
                            validator: (value) => value == null || value.isEmpty
                                ? 'Kata sandi wajib diisi.'
                                : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                        () => _rememberMe = value ?? false,
                                      ),
                              ),
                              const Expanded(child: Text('Ingat saya')),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgotPassword,
                                      ),
                                child: const Text('Lupa kata sandi?'),
                              ),
                            ],
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 8),
                            _InlineMessage(
                              message: _message!,
                              isError: _messageIsError,
                            ),
                          ],
                          const SizedBox(height: 16),
                          PillButton(
                            label: 'Masuk',
                            busy: _busy || _enteringGuest,
                            onPressed: _busy || _enteringGuest ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      TextButton(
                        onPressed: _openRegistration,
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _busy || _enteringGuest ? null : _enterGuest,
                    child: _enteringGuest
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk tanpa akun'),
                  ),
                ),
                Center(
                  child: Text(
                    'Akun disimpan lokal di perangkat ini.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }
}

class _AuthBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        'assets/images/tomato.png',
        width: 42,
        height: 42,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.local_florist_outlined, size: 40),
      ),
      const SizedBox(width: 10),
      Text(
        'POMODORO BELAJAR',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(letterSpacing: 1.4),
      ),
    ],
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
