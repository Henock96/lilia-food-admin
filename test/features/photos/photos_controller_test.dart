import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/photos/application/photos_controller.dart';
import 'package:lilia_admin/features/photos/data/photo_models.dart';
import 'package:lilia_admin/features/photos/data/photos_facade.dart';

class _FakeFacade implements PhotosFacade {
  _FakeFacade(this.initial);

  final List<Photo> initial;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;
  bool throwOnReorder = false;
  List<String>? lastReorderIds;

  @override
  Future<List<Photo>> list(EntityType type, String parentId) async =>
      List.of(initial);

  @override
  Future<Photo> create(
    EntityType type,
    String parentId, {
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) async {
    return Photo(
      id: 'new-${initial.length + 1}',
      url: url,
      publicId: publicId,
      alt: alt,
      displayOrder: initial.length,
      isCover: isCover,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Photo> update(
    EntityType type,
    String photoId, {
    String? alt,
    bool? isCover,
    int? displayOrder,
  }) async {
    if (throwOnUpdate) throw Exception('boom');
    final existing = initial.firstWhere((p) => p.id == photoId);
    return existing.copyWith(alt: alt, isCover: isCover);
  }

  @override
  Future<void> delete(EntityType type, String photoId) async {
    if (throwOnDelete) throw Exception('boom');
  }

  @override
  Future<void> reorder(
    EntityType type,
    String parentId,
    List<String> ids,
  ) async {
    lastReorderIds = ids;
    if (throwOnReorder) throw Exception('boom');
  }
}

Photo _photo(String id, {int order = 0, bool cover = false}) => Photo(
      id: id,
      url: 'https://x/$id.jpg',
      publicId: 'lilia/$id',
      alt: null,
      displayOrder: order,
      isCover: cover,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('PhotosController', () {
    test('setCover demote local + persiste', () async {
      final initial = [
        _photo('a', order: 0, cover: true),
        _photo('b', order: 1),
      ];
      final fake = _FakeFacade(initial);
      final container = ProviderContainer(
        overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        photosControllerProvider(EntityType.vendor, 'r1').notifier,
      );
      await container.read(
        photosControllerProvider(EntityType.vendor, 'r1').future,
      );

      await notifier.setCover('b');

      final state = container
          .read(photosControllerProvider(EntityType.vendor, 'r1'))
          .value!;
      expect(state.firstWhere((p) => p.id == 'a').isCover, isFalse);
      expect(state.firstWhere((p) => p.id == 'b').isCover, isTrue);
    });

    test('setCover rollback si API throw', () async {
      final initial = [
        _photo('a', order: 0, cover: true),
        _photo('b', order: 1),
      ];
      final fake = _FakeFacade(initial)..throwOnUpdate = true;
      final container = ProviderContainer(
        overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        photosControllerProvider(EntityType.vendor, 'r1').notifier,
      );
      await container.read(
        photosControllerProvider(EntityType.vendor, 'r1').future,
      );

      await expectLater(
        () => notifier.setCover('b'),
        throwsException,
      );

      final state = container
          .read(photosControllerProvider(EntityType.vendor, 'r1'))
          .value!;
      expect(state.firstWhere((p) => p.id == 'a').isCover, isTrue);
      expect(state.firstWhere((p) => p.id == 'b').isCover, isFalse);
    });

    test('delete optimistic remove puis rollback si throw', () async {
      final initial = [
        _photo('a', order: 0),
        _photo('b', order: 1),
      ];
      final fake = _FakeFacade(initial)..throwOnDelete = true;
      final container = ProviderContainer(
        overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        photosControllerProvider(EntityType.vendor, 'r1').notifier,
      );
      await container.read(
        photosControllerProvider(EntityType.vendor, 'r1').future,
      );

      await expectLater(
        () => notifier.delete('a'),
        throwsException,
      );

      final state = container
          .read(photosControllerProvider(EntityType.vendor, 'r1'))
          .value!;
      expect(state.map((p) => p.id).toList(), ['a', 'b']);
    });

    test('reorder réordonne localement et envoie les ids', () async {
      final initial = [
        _photo('a', order: 0),
        _photo('b', order: 1),
        _photo('c', order: 2),
      ];
      final fake = _FakeFacade(initial);
      final container = ProviderContainer(
        overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        photosControllerProvider(EntityType.vendor, 'r1').notifier,
      );
      await container.read(
        photosControllerProvider(EntityType.vendor, 'r1').future,
      );

      await notifier.reorder(['c', 'a', 'b']);

      expect(fake.lastReorderIds, ['c', 'a', 'b']);
      final state = container
          .read(photosControllerProvider(EntityType.vendor, 'r1'))
          .value!;
      expect(state.map((p) => p.id).toList(), ['c', 'a', 'b']);
      expect(state[0].displayOrder, 0);
      expect(state[2].displayOrder, 2);
    });
  });
}
