import 'package:flutter/material.dart';
/// SettingsScreen
/// Core & extended profile editing surface. Upgrades legacy manual date
/// parsing to intl DateFormat, adds optional fields (pronouns, program,
/// yearOfStudy, bio) for the course project while keeping sparse update
/// semantics. All operations surface feedback through Aurora snackbars.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/aurora_snackbar.dart';
import '../widgets/small_glowing_candle.dart';
import 'aurora_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController(); // yyyy-MM-dd
  final _heightCtrl = TextEditingController(); // cm
  final _weightCtrl = TextEditingController(); // kg
  final _pronounsCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(); // academic year
  final _bioCtrl = TextEditingController(); // short bio/context
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Loads existing profile document into form controllers.
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
        _birthdayCtrl.text = _dateFormat.format(d);
      }
      final h = data['heightCm'];
      if (h != null) _heightCtrl.text = h.toString();
      final w = data['weightKg'];
      if (w != null) _weightCtrl.text = w.toString();
      _pronounsCtrl.text = (data['pronouns'] as String?)?.trim() ?? '';
      _programCtrl.text = (data['program'] as String?)?.trim() ?? '';
      final yos = data['yearOfStudy'];
      if (yos != null) _yearCtrl.text = yos.toString();
      _bioCtrl.text = (data['bio'] as String?)?.trim() ?? '';
      setState(() {});
    }
  }
  /// Parses yyyy-MM-dd strictly; enforces boundaries (>=1900, <= today).
  DateTime? _tryParseDate(String input) {
    if (input.trim().isEmpty) return null;
    try {
      final dt = _dateFormat.parseStrict(input.trim());
      final now = DateTime.now();
      if (dt.year < 1900 || dt.isAfter(now)) return null;
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  /// Opens a Material date picker, defaulting to birthday or ~18 years ago.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _tryParseDate(_birthdayCtrl.text) ?? DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      _birthdayCtrl.text = _dateFormat.format(picked);
      setState(() {});
    }
  }

  /// Computes age in years from birthday (null-safe).
  int? _calculateAge(DateTime? birthday) {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Validates form, builds sparse profile update, and persists via AuthService.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final displayName = _displayNameCtrl.text.trim().isEmpty ? null : _displayNameCtrl.text.trim();
      final birthday = _tryParseDate(_birthdayCtrl.text);
      final height = _heightCtrl.text.trim().isEmpty ? null : double.tryParse(_heightCtrl.text.trim());
      final weight = _weightCtrl.text.trim().isEmpty ? null : double.tryParse(_weightCtrl.text.trim());
      final pronouns = _pronounsCtrl.text.trim().isEmpty ? null : _pronounsCtrl.text.trim();
      final program = _programCtrl.text.trim().isEmpty ? null : _programCtrl.text.trim();
      final yearOfStudy = _yearCtrl.text.trim().isEmpty ? null : int.tryParse(_yearCtrl.text.trim());
      final bio = _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim();
      await AuthService.instance.updateProfile(
        displayName: displayName,
        birthday: birthday,
        heightCm: height,
        weightKg: weight,
        pronouns: pronouns,
        program: program,
        yearOfStudy: yearOfStudy,
        bio: bio,
      );
      if (!mounted) return;
      showAuroraSnackBar(context, 'Profile updated', variant: AuroraSnackVariant.success);
      // If Settings is shown as a tab inside AuroraShell, do not pop the
      // route (popping would expose a blank screen). Only pop when this page
      // was pushed as a standalone route.
      final inShell = context.findAncestorWidgetOfExactType<AuroraShell>() != null;
      if (!inShell && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
    _pronounsCtrl.dispose();
    _programCtrl.dispose();
    _yearCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(_tryParseDate(_birthdayCtrl.text));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2F2E2C)),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: SmallGlowingCandle()),
          ),
        ),
        title: const Text('Settings', style: TextStyle(color: Color(0xFF2F2E2C))),
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
                            return _tryParseDate(v) == null ? 'Invalid date' : null;
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
                const Text('Optional Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2F2E2C))),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Pronouns',
                  child: TextFormField(
                    controller: _pronounsCtrl,
                    decoration: const InputDecoration(hintText: 'e.g., she/her, he/him, they/them'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Program',
                  child: TextFormField(
                    controller: _programCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'e.g., Computer Science'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Year of Study',
                  child: TextFormField(
                    controller: _yearCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                    decoration: const InputDecoration(hintText: 'e.g., 2'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 1 || n > 10) return 'Enter 1-10';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Bio / Context',
                  child: TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Short bio or notes (optional)'),
                    validator: (v) {
                      if (v != null && v.length > 300) return 'Max 300 chars';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),

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
