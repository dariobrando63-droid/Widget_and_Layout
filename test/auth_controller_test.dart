import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_belajar/data/auth_storage.dart';
import 'package:pomodoro_belajar/data/pomodoro_storage.dart';
import 'package:pomodoro_belajar/features/auth/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'accounts authenticate, lock out repeated failures, and recover',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var now = DateTime(2026, 1, 1);
      final auth = AuthController(
        storage: AuthStorage(preferences),
        clock: () => now,
      );
      await auth.initialize();

      expect(
        await auth.register(
          nama: 'Pelajar',
          email: 'PELAJAR@example.com',
          kataSandi: 'belajar123',
          pertanyaan: pertanyaanKeamanan.first,
          jawaban: 'Kucing',
        ),
        isNull,
      );
      expect(auth.securityQuestionFor('pelajar@example.com'), isNotNull);
      for (var attempt = 0; attempt < 5; attempt++) {
        expect(
          await auth.login(
            email: 'pelajar@example.com',
            kataSandi: 'salah1234',
            ingatSaya: false,
          ),
          'Email atau kata sandi salah.',
        );
      }
      expect(
        await auth.login(
          email: 'pelajar@example.com',
          kataSandi: 'belajar123',
          ingatSaya: false,
        ),
        startsWith('Terlalu banyak percobaan.'),
      );

      now = now.add(const Duration(seconds: 31));
      expect(
        await auth.resetPassword(
          email: 'pelajar@example.com',
          jawaban: 'kUCING',
          kataSandiBaru: 'fokusBelajar123',
        ),
        isNull,
      );
      expect(
        await auth.login(
          email: 'pelajar@example.com',
          kataSandi: 'fokusBelajar123',
          ingatSaya: true,
        ),
        isNull,
      );
      expect(auth.currentAccount?.email, 'pelajar@example.com');

      auth.dispose();
    },
  );

  test('guest sessions persist without creating an account', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = AuthStorage(preferences);
    final auth = AuthController(storage: storage);
    await auth.initialize();

    await auth.enterGuest();

    expect(auth.isGuest, isTrue);
    expect(auth.currentAccount, isNull);
    expect(preferences.getString('pomodoro_local_session_v1'), 'guest');
    auth.dispose();

    final restoredAuth = AuthController(storage: storage);
    await restoredAuth.initialize();
    expect(restoredAuth.isGuest, isTrue);
    expect(restoredAuth.currentAccount, isNull);
    await restoredAuth.logout();
    expect(restoredAuth.currentSessionId, isNull);
    restoredAuth.dispose();
  });

  test('timer storage keys isolate account data', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = PomodoroStorage(preferences, accountId: 'account-a');
    final second = PomodoroStorage(preferences, accountId: 'account-b');

    await first.save(first.load(now: DateTime(2026, 1, 1)));
    await second.save(second.load(now: DateTime(2026, 1, 1)));
    expect(preferences.getKeys(), contains('pomodoro_account-a_state_v2'));
    expect(preferences.getKeys(), contains('pomodoro_account-b_state_v2'));

    final authStorage = AuthStorage(preferences);
    await authStorage.deleteAccountData('account-a');
    expect(
      preferences.getKeys(),
      isNot(contains('pomodoro_account-a_state_v2')),
    );
    expect(preferences.getKeys(), contains('pomodoro_account-b_state_v2'));
  });
}
