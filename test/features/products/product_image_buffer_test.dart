import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/products/presentation/widgets/product_image_buffer.dart';

void main() {
  group('ProductImageBuffer', () {
    test('1er add devient couverture automatiquement', () {
      final b = ProductImageBuffer();
      b.add(url: 'u1', publicId: 'p1');
      expect(b.drafts.single.isCover, isTrue);
    });

    test('2e add ne devient pas couverture', () {
      final b = ProductImageBuffer();
      b.add(url: 'u1', publicId: 'p1');
      b.add(url: 'u2', publicId: 'p2');
      expect(b.drafts[0].isCover, isTrue);
      expect(b.drafts[1].isCover, isFalse);
    });

    test('setCover démet les autres couvertures', () {
      final b = ProductImageBuffer();
      b.add(url: 'u1', publicId: 'p1');
      b.add(url: 'u2', publicId: 'p2');
      b.setCover(1);
      expect(b.drafts[0].isCover, isFalse);
      expect(b.drafts[1].isCover, isTrue);
    });

    test('removeAt de la couverture repromeut la première restante', () {
      final b = ProductImageBuffer();
      b.add(url: 'u1', publicId: 'p1'); // cover
      b.add(url: 'u2', publicId: 'p2');
      b.removeAt(0);
      expect(b.drafts.single.url, 'u2');
      expect(b.drafts.single.isCover, isTrue);
    });

    test('coverUrl renvoie l\'URL de la couverture ou null si vide', () {
      final b = ProductImageBuffer();
      expect(b.coverUrl, isNull);
      b.add(url: 'u1', publicId: 'p1');
      expect(b.coverUrl, 'u1');
    });

    test('isFull à partir de 5 images', () {
      final b = ProductImageBuffer();
      for (var i = 0; i < 5; i++) {
        b.add(url: 'u$i', publicId: 'p$i');
      }
      expect(b.isFull, isTrue);
      expect(b.drafts.length, 5);
    });

    test('reorder réordonne sans changer la couverture logique', () {
      final b = ProductImageBuffer();
      b.add(url: 'u1', publicId: 'p1'); // cover
      b.add(url: 'u2', publicId: 'p2');
      b.reorder(0, 2); // déplace u1 après u2
      expect(b.drafts.map((d) => d.url).toList(), ['u2', 'u1']);
      // la couverture reste l'image u1
      expect(b.drafts.firstWhere((d) => d.url == 'u1').isCover, isTrue);
    });
  });
}
