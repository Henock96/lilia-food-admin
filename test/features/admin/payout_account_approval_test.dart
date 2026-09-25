import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/admin/data/vendor_onboarding_service.dart';
import 'package:lilia_admin/features/admin/domain/approval_response.dart';

/// F3-08 — remplacer un numéro de versement existant ouvre une demande
/// d'approbation : rien n'a changé, l'app ne doit pas dire « enregistré ».
void main() {
  group('isApprovalRequested', () {
    test('enveloppe { data: { approvalRequired: true } }', () {
      expect(
        isApprovalRequested({
          'data': {'approvalRequired': true, 'approval': <String, dynamic>{}},
        }),
        isTrue,
      );
    });

    test('compte enregistré directement (première saisie)', () {
      expect(
        isApprovalRequested({
          'data': {'id': 'r1', 'payoutPhoneNumber': '24206****67'},
        }),
        isFalse,
      );
      expect(isApprovalRequested(null), isFalse);
    });
  });

  group('VendorOnboardingService.updatePayoutAccount', () {
    ({VendorOnboardingService service, DioAdapter adapter}) build() {
      final client = ApiClient.test(
        baseUrl: 'https://test.local',
        tokenProvider: () async => 'tok',
        forceRefreshToken: () async => 'tok2',
      );
      return (
        service: VendorOnboardingService(client),
        adapter: DioAdapter(dio: client.dio),
      );
    }

    const body = {'payoutPhoneNumber': '066123456', 'payoutProvider': 'MTN_MOMO'};

    test('changement : rend true (demande en attente)', () async {
      final t = build();
      t.adapter.onPatch(
        '/admin/vendors/r1/payout-account',
        (s) => s.reply(202, {
          'success': true,
          'data': {'approvalRequired': true, 'approval': {'id': 'ap1'}},
        }),
        data: body,
      );
      expect(
        await t.service.updatePayoutAccount(
          'r1',
          payoutPhoneNumber: '066123456',
          payoutProvider: 'MTN_MOMO',
        ),
        isTrue,
      );
    });

    test('première saisie : rend false (appliqué)', () async {
      final t = build();
      t.adapter.onPatch(
        '/admin/vendors/r1/payout-account',
        (s) => s.reply(200, {
          'success': true,
          'data': {'id': 'r1', 'payoutPhoneNumber': '24206****56'},
        }),
        data: body,
      );
      expect(
        await t.service.updatePayoutAccount(
          'r1',
          payoutPhoneNumber: '066123456',
          payoutProvider: 'MTN_MOMO',
        ),
        isFalse,
      );
    });
  });
}
