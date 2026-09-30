/// The shapes the Eden API hands back, mirrored from the web app's `src/lib/eden.ts` and the backend
/// routes. Parsing is forgiving: MySQL counts arrive as strings as often as numbers.
library;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String _str(Object? v) => v == null ? '' : '$v';

enum SessionKind { studio, person }

class SignedIn {
  const SignedIn({required this.kind, required this.token, required this.expiresAt});
  final SessionKind kind;
  final String token;
  final DateTime expiresAt;

  factory SignedIn.fromJson(Map<String, dynamic> json, SessionKind kind) {
    final token = _str(json['token']);
    if (token.isEmpty) {
      throw const FormatException('Eden did not return a mobile token. Is the backend up to date?');
    }
    final seconds = _int(json['expires_in']);
    return SignedIn(
      kind: kind,
      token: token,
      expiresAt: DateTime.now().add(Duration(seconds: seconds > 0 ? seconds : 3600)),
    );
  }
}

class Film {
  const Film({
    required this.movieId,
    required this.title,
    required this.overview,
    required this.poster,
    required this.releaseDate,
    required this.runtime,
    required this.genres,
    required this.meta,
    required this.studio,
  });

  final int movieId;
  final String title;
  final String overview;
  final String? poster;
  final String releaseDate;
  final int? runtime;
  final List<String> genres;
  final String meta;
  final StudioCard studio;

  factory Film.fromJson(Map json) => Film(
        movieId: _int(json['movie_id']),
        title: _str(json['title']),
        overview: _str(json['overview']),
        poster: json['poster'] as String?,
        releaseDate: _str(json['release_date']),
        runtime: json['runtime'] == null ? null : _int(json['runtime']),
        genres: [for (final g in (json['genres'] as List? ?? const [])) '$g'],
        meta: _str(json['meta']),
        studio: StudioCard.fromJson(json['studio'] as Map? ?? const {}),
      );
}

class CinemaPage {
  const CinemaPage({required this.films, required this.page, required this.pages, required this.total});
  final List<Film> films;
  final int page;
  final int pages;
  final int total;

  factory CinemaPage.fromJson(Map<String, dynamic> json) => CinemaPage(
        films: [for (final f in (json['data'] as List? ?? const [])) Film.fromJson(f as Map)],
        page: _int(json['page']),
        pages: _int(json['pages']),
        total: _int(json['total']),
      );
}

class StudioCard {
  const StudioCard({required this.eden, required this.name, this.titles});
  final int eden;
  final String name;
  final int? titles;

  factory StudioCard.fromJson(Map json) => StudioCard(
        eden: _int(json['eden']),
        name: _str(json['name']),
        titles: json['titles'] == null ? null : _int(json['titles']),
      );
}

class Rule {
  const Rule({required this.key, required this.required, required this.value, required this.complete});
  final String key;
  final int required;
  final int value;
  final bool complete;

  String get label => switch (key) {
        'media' => 'Titles published',
        'views' => 'Views',
        'followers' => 'Followers',
        'mini_series' => 'Mini-series',
        _ => key,
      };

  /// mini_series is a "more than" rule on the server.
  String get target => key == 'mini_series' ? 'more than $required' : '$required';

  double get progress => required <= 0 ? 1 : (value / required).clamp(0, 1).toDouble();
}

class StudioProfile {
  const StudioProfile({
    required this.monetized,
    required this.rules,
    required this.balance,
    required this.payoutPhone,
    required this.minWithdrawal,
    required this.withdrawals,
  });

  final bool monetized;
  final List<Rule> rules;
  final int balance;
  final String payoutPhone;
  final int minWithdrawal;
  final List<Withdrawal> withdrawals;

  factory StudioProfile.fromJson(Map<String, dynamic> json) {
    final q = (json['qualification'] as Map? ?? const {});
    return StudioProfile(
      monetized: json['monetized'] == true,
      rules: [
        for (final e in q.entries)
          Rule(
            key: '${e.key}',
            required: _int((e.value as Map)['required']),
            value: _int((e.value as Map)['value']),
            complete: (e.value as Map)['complete'] == true,
          ),
      ],
      balance: _int(json['balance']),
      payoutPhone: _str(json['payout_phone']),
      minWithdrawal: _int(json['min_withdrawal']),
      withdrawals: [
        for (final w in (json['withdrawals'] as List? ?? const []))
          Withdrawal.fromJson((w as Map).cast<String, dynamic>()),
      ],
    );
  }
}

class Withdrawal {
  const Withdrawal({
    required this.id,
    required this.ref,
    required this.amount,
    required this.status,
    required this.phone,
    required this.receipt,
    required this.error,
    required this.time,
  });

  final int id;
  final String ref;
  final int amount;
  final String status; // pending | completed | failed
  final String phone;
  final String receipt;
  final String error;
  final DateTime? time;

  bool get pending => status == 'pending';

  factory Withdrawal.fromJson(Map<String, dynamic> json) => Withdrawal(
        id: _int(json['id']),
        ref: _str(json['ref']),
        amount: _int(json['amount']),
        status: _str(json['status']),
        phone: _str(json['phone']),
        receipt: _str(json['receipt']),
        error: _str(json['error']),
        time: DateTime.tryParse(_str(json['time'])),
      );
}

class PersonProfile {
  const PersonProfile({
    required this.name,
    required this.email,
    required this.telephone,
    required this.emailVerified,
    required this.telephoneVerified,
    required this.followers,
    required this.credits,
    required this.studios,
  });

  final String name;
  final String email;
  final String telephone;
  final bool emailVerified;
  final bool telephoneVerified;
  final int followers;
  final int credits;
  final int studios;

  factory PersonProfile.fromJson(Map<String, dynamic> json) {
    final p = (json['person'] as Map? ?? const {});
    return PersonProfile(
      name: _str(p['name'] ?? p['original_name']),
      email: _str(p['email']),
      telephone: _str(p['telephone']),
      emailVerified: p['email_verified'] == true,
      telephoneVerified: p['telephone_verified'] == true,
      followers: _int(json['followers']),
      credits: _int(json['credits']),
      studios: _int(json['studios']),
    );
  }
}
