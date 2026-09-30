import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uko_eden/src/api.dart';
import 'package:uko_eden/src/models.dart';

void main() {
  test('every request goes through the mobile entry', () async {
    late http.Request seen;
    final api = EdenApi(
      client: MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'status': true,
            'data': [
              {
                'movie_id': 7,
                'title': 'Kibera Nights',
                'poster': '3/images/a.jpg',
                'genres': ['Drama'],
                'meta': 'Drama · 2025',
                'studio': {'eden': 3, 'name': 'Savanna Films'},
              }
            ],
            'page': 1,
            'pages': 2,
            'total': 21,
          }),
          200,
        );
      }),
    )..token = 'jwt';

    final page = await api.cinema();

    expect(seen.headers['x-eden-client'], 'mobile');
    expect(seen.headers['authorization'], 'Bearer jwt');
    expect(seen.url.queryParameters['page'], '1');
    expect(page.films.single.studio.name, 'Savanna Films');
    expect(page.pages, 2);
  });

  test('status:false with HTTP 200 is an error', () async {
    final api = EdenApi(
      client: MockClient((_) async =>
          http.Response(jsonEncode({'status': false, 'message': 'incorrect code'}), 200)),
    );
    expect(
      () => api.personConfirm('a@b.c', '123456'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'incorrect code')),
    );
  });

  test('a sign-in without a token means the backend lacks the mobile entry', () {
    expect(
      () => SignedIn.fromJson({'status': true, 'message': 'ok'}, SessionKind.studio),
      throwsFormatException,
    );
  });
}
