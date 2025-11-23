import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/aurora_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController(); // yyyy-mm-dd
  final _heightCtrl = TextEditingController(); // cm
  final _weightCtrl = TextEditingController(); // kg
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data();
    if (data != null) {
      _displayNameCtrl.text = (data['displayName'] as String?) ?? (data['fullName'] as String?) ?? '';
      final ts = data['birthday'];
      if (ts is Timestamp) {
        final d = ts.toDate();
        _birthdayCtrl.text = _fmtDate(d);
      }
      final h = data['heightCm'];
      if (h != null) _heightCtrl.text = h.toString();
      final w = data['weightKg'];
      if (w != null) _weightCtrl.text = w.toString();
      setState(() {});
    }
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String input) {
    try {
      if (input.isEmpty) return null;
      final parts = input.split('-');
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _parseDate(_birthdayCtrl.text) ?? DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      _birthdayCtrl.text = _fmtDate(picked);
      setState(() {});
    }
  }

  int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final displayName = _displayNameCtrl.text.trim().isEmpty ? null : _displayNameCtrl.text.trim();
      final birthday = _parseDate(_birthdayCtrl.text);
      final height = _heightCtrl.text.trim().isEmpty ? null : double.tryParse(_heightCtrl.text.trim());
      final weight = _weightCtrl.text.trim().isEmpty ? null : double.tryParse(_weightCtrl.text.trim());
      await AuthService.instance.updateProfile(
        displayName: displayName,
        birthday: birthday,
        heightCm: height,
        weightKg: weight,
      );
      if (!mounted) return;
      showAuroraSnackBar(context, 'Profile updated', variant: AuroraSnackVariant.success);
      Navigator.pop(context);
    } catch (e) {
      final msg = AuthService.instance.mapAuthError(e);
      if (mounted) {
        showAuroraSnackBar(context, msg, variant: AuroraSnackVariant.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _birthdayCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_parseDate(_birthdayCtrl.text));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF2F2E2C))),
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F2E2C)),
      ),
      backgroundColor: const Color(0xFFF5EFE7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF2F2E2C))),
                const SizedBox(height: 16),

                _LabeledField(
                  label: 'Display name',
                  child: TextFormField(
                    controller: _displayNameCtrl,
                    decoration: const InputDecoration(hintText: 'John Doe'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => null,
                  ),
                ),

                const SizedBox(height: 16),

                _LabeledField(
                  label: 'Birthday',
                  helper: age != null ? 'Age: $age' : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _birthdayCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null; // optional
                            return _parseDate(v) == null ? 'Invalid date' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickDate,
                        child: const Text('Pick'),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _LabeledField(
                  label: 'Height (cm)',
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g., 175'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final d = double.tryParse(v);
                      if (d == null || d <= 0) return 'Enter a positive number';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _LabeledField(
                  label: 'Weight (kg)',
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g., 70'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final d = double.tryParse(v);
                      if (d == null || d <= 0) return 'Enter a positive number';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? helper;
  final Widget child;
  const _LabeledField({required this.label, this.helper, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6F6C66))),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: const TextStyle(fontSize: 12, color: Color(0xFF6F6C66))),
        ]
      ],
    );
  }
}
