/// The studio's phone dashboard: the four monetization rules, the wallet, and M-PESA withdrawals to the
/// account's own number. Uploading, casting and cast editing stay on the web dashboard.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import 'widgets/common.dart';

class StudioHome extends StatefulWidget {
  const StudioHome({super.key, required this.api, required this.session});
  final EdenApi api;
  final SessionController session;

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  late Future<StudioProfile> _profile = widget.api.studioProfile();
  Timer? _poll;

  Future<void> _reload() async {
    setState(() => _profile = widget.api.studioProfile());
    try {
      final p = await _profile;
      _watch(p.withdrawals.where((w) => w.pending).firstOrNull);
    } catch (_) {}
  }

  /// A payout settles when Daraja's result reaches the relay; GET /withdraw/:id asks the relay for it.
  void _watch(Withdrawal? pending) {
    _poll?.cancel();
    if (pending == null) return;
    var tries = 0;
    _poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (++tries > 24) return t.cancel();
      try {
        final w = await widget.api.withdrawal(pending.id);
        if (!w.pending) {
          t.cancel();
          if (!mounted) return;
          toast(context, w.status == 'completed' ? '${kes(w.amount)} sent. ${w.receipt}' : w.error);
          _reload();
        }
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    _profile.then((p) => _watch(p.withdrawals.where((w) => w.pending).firstOrNull), onError: (_) {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _withdraw(StudioProfile p) async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EdenColors.earth900,
      builder: (_) => _WithdrawSheet(profile: p),
    );
    if (amount == null || !mounted) return;
    try {
      final w = await widget.api.withdraw(amount);
      if (!mounted) return;
      toast(context, 'Withdrawal ${w.ref} started.');
      await _reload();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Studio'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: widget.session.signOut,
            ),
          ],
        ),
        body: FutureBuilder<StudioProfile>(
          future: _profile,
          builder: (context, snap) {
            if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            final p = snap.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _WalletCard(profile: p, onWithdraw: () => _withdraw(p)),
                  const SizedBox(height: 16),
                  _MonetizationCard(profile: p),
                  const SizedBox(height: 16),
                  Text('Withdrawals', style: fraunces(20)),
                  const SizedBox(height: 8),
                  if (p.withdrawals.isEmpty)
                    const Text('None yet.', style: TextStyle(color: EdenColors.muted))
                  else
                    for (final w in p.withdrawals) _WithdrawalRow(w),
                ],
              ),
            );
          },
        ),
      );
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.profile, required this.onWithdraw});
  final StudioProfile profile;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final busy = profile.withdrawals.any((w) => w.pending);
    final can = profile.monetized && !busy && profile.balance >= profile.minWithdrawal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wallet', style: TextStyle(color: EdenColors.muted)),
            const SizedBox(height: 4),
            Text(kes(profile.balance), style: fraunces(32)),
            const SizedBox(height: 4),
            Text('Payouts go to ${profile.payoutPhone} by M-PESA',
                style: const TextStyle(color: EdenColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            FilledButton(onPressed: can ? onWithdraw : null, child: const Text('Withdraw')),
            if (!profile.monetized)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Withdrawals open once every monetization rule below passes.',
                    style: TextStyle(color: EdenColors.muted, fontSize: 12)),
              )
            else if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('A withdrawal is still being processed.',
                    style: TextStyle(color: EdenColors.muted, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonetizationCard extends StatelessWidget {
  const _MonetizationCard({required this.profile});
  final StudioProfile profile;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Monetization', style: fraunces(20)),
                const Spacer(),
                Icon(
                  profile.monetized ? Icons.verified : Icons.hourglass_bottom,
                  color: profile.monetized ? EdenColors.good : EdenColors.muted,
                  size: 20,
                ),
              ]),
              const SizedBox(height: 4),
              const Text('Studios earn 30% of credit views once every rule passes.',
                  style: TextStyle(color: EdenColors.muted, fontSize: 12)),
              for (final r in profile.rules) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text(r.label)),
                  Text('${NumberFormat.compact().format(r.value)} / ${r.target}',
                      style: TextStyle(color: r.complete ? EdenColors.good : EdenColors.muted)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: r.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: EdenColors.earth800,
                  color: r.complete ? EdenColors.good : EdenColors.clay400,
                ),
              ],
            ],
          ),
        ),
      );
}

class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow(this.w);
  final Withdrawal w;

  @override
  Widget build(BuildContext context) {
    final color = switch (w.status) {
      'completed' => EdenColors.good,
      'failed' => EdenColors.bad,
      _ => EdenColors.clay300,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${kes(w.amount)} · ${w.ref}'),
      subtitle: Text(
        [
          if (w.time != null) DateFormat('d MMM y, HH:mm').format(w.time!.toLocal()),
          if (w.receipt.isNotEmpty) w.receipt,
          if (w.status == 'failed' && w.error.isNotEmpty) w.error,
        ].join(' · '),
        style: const TextStyle(color: EdenColors.muted, fontSize: 12),
      ),
      trailing: Text(w.status, style: TextStyle(color: color)),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.profile});
  final StudioProfile profile;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();
  String? _error;

  void _submit() {
    final p = widget.profile;
    final amount = int.tryParse(_amount.text.trim());
    final error = amount == null
        ? 'Enter a whole number of shillings.'
        : amount < p.minWithdrawal
            ? 'The minimum is ${kes(p.minWithdrawal)}.'
            : amount > p.balance
                ? 'Your wallet holds ${kes(p.balance)}.'
                : null;
    if (error != null) return setState(() => _error = error);
    Navigator.of(context).pop(amount);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Withdraw to M-PESA', style: fraunces(22)),
            const SizedBox(height: 4),
            Text('To ${widget.profile.payoutPhone}. Available: ${kes(widget.profile.balance)}.',
                style: const TextStyle(color: EdenColors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'Amount (KES)', errorText: _error),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Send')),
          ],
        ),
      );
}
