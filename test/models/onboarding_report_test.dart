import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/onboarding_report.dart';
import 'package:lilia_admin/models/restaurant.dart';

void main() {
  group('OnboardingReport', () {
    test('lit la checklist envoyée par le serveur', () {
      final report = OnboardingReport.fromJson({
        'restaurantId': 'r1',
        'onboardingStatus': 'DRAFT',
        'isReady': false,
        'progress': 62,
        'checks': [
          {
            'key': 'logo',
            'label': 'Logo',
            'status': 'MISSING',
            'blocking': true,
            'detail': 'Le logo apparaît sur chaque carte.',
          },
          {
            'key': 'cover',
            'label': 'Couverture',
            'status': 'MISSING',
            'blocking': false,
          },
        ],
        'blockingIssues': ['Le logo apparaît sur chaque carte.'],
      });

      expect(report.isReady, isFalse);
      expect(report.progress, 62);
      expect(report.checks, hasLength(2));
      expect(report.checkFor('logo')!.blocking, isTrue);
      expect(report.checkFor('cover')!.blocking, isFalse);
      expect(report.checkFor('inconnu'), isNull);
    });

    test('tolère un payload minimal sans planter', () {
      // Le backend peut évoluer ; un champ absent ne doit pas casser l'écran
      // d'onboarding, qui est le seul moyen de configurer un vendeur.
      final report = OnboardingReport.fromJson({});
      expect(report.onboardingStatus, 'DRAFT');
      expect(report.isReady, isFalse);
      expect(report.progress, 0);
      expect(report.checks, isEmpty);
    });

    test('isActivated distingue la boutique publiée du brouillon', () {
      expect(
        OnboardingReport.fromJson({'onboardingStatus': 'ACTIVATED'}).isActivated,
        isTrue,
      );
      expect(
        OnboardingReport.fromJson({'onboardingStatus': 'READY'}).isActivated,
        isFalse,
      );
    });
  });

  group('VendorInvitationResult', () {
    test("expose le lien de repli quand l'e-mail n'est pas parti", () {
      final result = VendorInvitationResult.fromJson({
        'emailSent': false,
        'smsSent': true,
        'activationLink': 'https://auth.example/reset?oobCode=abc',
        'detail': "L'e-mail n'a pas pu être envoyé.",
      });
      expect(result.emailSent, isFalse);
      expect(result.activationLink, isNotNull);
    });

    test('ne porte aucun lien quand tout est parti normalement', () {
      final result = VendorInvitationResult.fromJson({
        'emailSent': true,
        'smsSent': true,
        'detail': 'Invitation envoyée.',
      });
      expect(result.activationLink, isNull);
    });
  });

  group('Restaurant — visibilité client', () {
    Restaurant build({
      String onboarding = 'ACTIVATED',
      bool approved = true,
      bool active = true,
    }) =>
        Restaurant.fromJson({
          'id': 'r1',
          'nom': 'Chez Lilia',
          'adresse': 'Bacongo',
          'ownerId': 'u1',
          'onboardingStatus': onboarding,
          'adminApproved': approved,
          'isActive': active,
        });

    test('visible seulement si les trois conditions sont réunies', () {
      expect(build().isVisibleToClients, isTrue);
      expect(build(onboarding: 'DRAFT').isVisibleToClients, isFalse);
      expect(build(onboarding: 'READY').isVisibleToClients, isFalse);
      expect(build(approved: false).isVisibleToClients, isFalse);
      expect(build(active: false).isVisibleToClients, isFalse);
    });

    test('isDraft signale une boutique encore en configuration', () {
      expect(build(onboarding: 'DRAFT').isDraft, isTrue);
      expect(build(onboarding: 'READY').isDraft, isTrue);
      expect(build().isDraft, isFalse);
    });

    test(
      'un payload sans onboardingStatus reste considéré comme publié',
      () {
        // Les vendeurs créés avant l'onboarding sont en production : les faire
        // passer pour des brouillons les ferait disparaître de l'interface.
        final legacy = Restaurant.fromJson({
          'id': 'r-legacy',
          'nom': 'Ancien resto',
          'adresse': 'Poto-Poto',
          'ownerId': 'u9',
        });
        expect(legacy.onboardingStatus, 'ACTIVATED');
        expect(legacy.isVisibleToClients, isTrue);
      },
    );
  });
}
