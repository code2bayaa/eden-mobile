/// The two ways in. A studio signs in with its telephone and password (the PHP account); a person —
/// cast or crew a studio registered — asks for a six-digit code at their e-mail and types it back.
library;

import 'package:flutter/material.dart';

import '../api.dart';
import '../session.dart';
import '../theme.dart';
import 'widgets/common.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, required this.api, required this.session});
  final EdenApi api;
  final SessionController session;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Sign in'),
            bottom: const TabBar(tabs: [Tab(text: 'Studio'), Tab(text: 'Cast & crew')]),
          ),
          body: TabBarView(
            children: [
              _StudioForm(api: api, session: session),
              _PersonForm(api: api, session: session),
            ],
          ),
        ),
      );
}

class _StudioForm extends StatefulWidget {
  const _StudioForm({required this.api, required this.session});
  final EdenApi api;
  final SessionController session;

  @override
  State<_StudioForm> createState() => _StudioFormState();
}

class _StudioFormState extends State<_StudioForm> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      toast(context, 'Enter your telephone and password.');
      return;
    }
    setState(() => _busy = true);
    try {
      final signed = await widget.api.studioSignIn(_phone.text.trim(), _password.text);
      await widget.session.signedIn(signed);
    } on Object catch (e) {
      if (mounted) toast(context, e is FormatException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Studio', style: fraunces(24)),
          const SizedBox(height: 6),
          const Text('Your UKO account telephone and password.',
              style: TextStyle(color: EdenColors.muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(labelText: 'Telephone', hintText: '07XX XXX XXX'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
        ],
      );
}

class _PersonForm extends StatefulWidget {
  const _PersonForm({required this.api, required this.session});
  final EdenApi api;
  final SessionController session;

  @override
  State<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<_PersonForm> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      toast(context, 'Enter the e-mail your studio registered.');
      return;
    }
    setState(() => _busy = true);
    try {
      final message = await widget.api.personRequestCode(email);
      if (!mounted) return;
      setState(() => _sent = true);
      toast(context, message);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length != 6) {
      toast(context, 'The code is six digits.');
      return;
    }
    setState(() => _busy = true);
    try {
      final signed = await widget.api.personConfirm(_email.text.trim(), _code.text.trim());
      await widget.session.signedIn(signed);
    } on Object catch (e) {
      if (mounted) toast(context, e is FormatException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Cast & crew', style: fraunces(24)),
          const SizedBox(height: 6),
          const Text('Sign in with the e-mail your studio registered. We send a code, no password.',
              style: TextStyle(color: EdenColors.muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            enabled: !_sent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          if (_sent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              autofillHints: const [AutofillHints.oneTimeCode],
              onSubmitted: (_) => _confirm(),
              decoration: const InputDecoration(labelText: 'Six-digit code', counterText: ''),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : (_sent ? _confirm : _requestCode),
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_sent ? 'Sign in' : 'Send code'),
          ),
          if (_sent)
            TextButton(
              onPressed: _busy ? null : () => setState(() => _sent = false),
              child: const Text('Use a different e-mail'),
            ),
        ],
      );
}
