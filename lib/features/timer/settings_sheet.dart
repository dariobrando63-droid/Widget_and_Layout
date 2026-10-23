import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/pomodoro_cycle_utils.dart';
import '../../data/models/pomodoro_models.dart';
import 'pomodoro_controller.dart';

/// Form durasi sesi dengan validasi dan preview siklus langsung.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({required this.controller, super.key});

  final PomodoroController controller;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _focusController;
  late final TextEditingController _shortBreakController;
  late final TextEditingController _longBreakController;
  late int _focusesBeforeLongBreak;
  bool _saving = false;

  PomodoroSettings get _currentSettings => PomodoroSettings(
    focusMinutes: int.tryParse(_focusController.text) ?? 0,
    shortBreakMinutes: int.tryParse(_shortBreakController.text) ?? 0,
    longBreakMinutes: int.tryParse(_longBreakController.text) ?? 0,
    focusesBeforeLongBreak: _focusesBeforeLongBreak,
  );

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _focusController = TextEditingController(
      text: settings.focusMinutes.toString(),
    );
    _shortBreakController = TextEditingController(
      text: settings.shortBreakMinutes.toString(),
    );
    _longBreakController = TextEditingController(
      text: settings.longBreakMinutes.toString(),
    );
    _focusesBeforeLongBreak = settings.focusesBeforeLongBreak;
    for (final controller in [
      _focusController,
      _shortBreakController,
      _longBreakController,
    ]) {
      controller.addListener(_onValueChanged);
    }
  }

  void _onValueChanged() {
    if (mounted) setState(() {});
  }

  String? _validateMinutes(String? value, {required int maximum}) {
    final minutes = int.tryParse(value ?? '');
    if (minutes == null) return 'Masukkan angka dalam menit.';
    if (minutes < 1 || minutes > maximum) {
      return 'Isi nilai antara 1–$maximum menit.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.controller.updateSettings(_currentSettings);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengaturan belum tersimpan: $error')),
      );
    }
  }

  Future<void> _restoreDefaults() async {
    final defaults = pengaturanDefault;
    _focusController.text = defaults.focusMinutes.toString();
    _shortBreakController.text = defaults.shortBreakMinutes.toString();
    _longBreakController.text = defaults.longBreakMinutes.toString();
    setState(() => _focusesBeforeLongBreak = defaults.focusesBeforeLongBreak);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _currentSettings;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pengaturan sesi',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Waktu disimpan di perangkat ini dan berlaku untuk sesi berikutnya.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                _MinutesField(
                  controller: _focusController,
                  label: 'Durasi fokus',
                  icon: Icons.center_focus_strong,
                  maximum: 120,
                  validator: (value) => _validateMinutes(value, maximum: 120),
                ),
                const SizedBox(height: 14),
                _MinutesField(
                  controller: _shortBreakController,
                  label: 'Istirahat pendek',
                  icon: Icons.coffee_outlined,
                  maximum: 60,
                  validator: (value) => _validateMinutes(value, maximum: 60),
                ),
                const SizedBox(height: 14),
                _MinutesField(
                  controller: _longBreakController,
                  label: 'Istirahat panjang',
                  icon: Icons.self_improvement,
                  maximum: 60,
                  validator: (value) => _validateMinutes(value, maximum: 60),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _focusesBeforeLongBreak,
                  decoration: const InputDecoration(
                    labelText: 'Sesi fokus sebelum istirahat panjang',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: [
                    for (var count = 2; count <= 8; count++)
                      DropdownMenuItem(
                        value: count,
                        child: Text('$count sesi fokus'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _focusesBeforeLongBreak = value);
                          }
                        },
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview siklus',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(teksPratinjauSiklus(settings)),
                        const SizedBox(height: 8),
                        Text(
                          'Total ${totalMenitSiklus(settings)} menit'
                          ' · fokus ${totalMenitFokus(settings)} menit',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Menyimpan…' : 'Simpan pengaturan'),
                ),
                TextButton(
                  onPressed: _saving ? null : _restoreDefaults,
                  child: const Text('Kembalikan pengaturan default'),
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
    _focusController
      ..removeListener(_onValueChanged)
      ..dispose();
    _shortBreakController
      ..removeListener(_onValueChanged)
      ..dispose();
    _longBreakController
      ..removeListener(_onValueChanged)
      ..dispose();
    super.dispose();
  }
}

class _MinutesField extends StatelessWidget {
  const _MinutesField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.maximum,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maximum;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: 'menit (maks. $maximum)',
      ),
    );
  }
}
