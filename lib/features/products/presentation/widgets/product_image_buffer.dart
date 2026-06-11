import 'package:flutter/foundation.dart';

/// Une image uploadée vers Cloudinary mais pas encore rattachée à un produit
/// (cas création). Contient déjà url + publicId issus de l'upload.
class DraftImage {
  DraftImage({required this.url, required this.publicId, this.isCover = false});

  final String url;
  final String publicId;
  bool isCover;
}

/// Buffer local d'images pour la création de produit. Tient la liste ordonnée,
/// garantit au plus une couverture, et fournit l'URL de couverture pour le
/// payload `imageUrl` du produit. Limite : 5 images (alignée backend).
class ProductImageBuffer extends ChangeNotifier {
  static const int maxImages = 5;

  final List<DraftImage> _drafts = [];

  List<DraftImage> get drafts => List.unmodifiable(_drafts);
  bool get isFull => _drafts.length >= maxImages;
  bool get isEmpty => _drafts.isEmpty;

  String? get coverUrl {
    for (final d in _drafts) {
      if (d.isCover) return d.url;
    }
    return _drafts.isEmpty ? null : _drafts.first.url;
  }

  void add({required String url, required String publicId}) {
    if (isFull) return;
    final isFirst = _drafts.isEmpty;
    _drafts.add(DraftImage(url: url, publicId: publicId, isCover: isFirst));
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _drafts.length) return;
    final wasCover = _drafts[index].isCover;
    _drafts.removeAt(index);
    if (wasCover && _drafts.isNotEmpty) {
      _drafts.first.isCover = true;
    }
    notifyListeners();
  }

  void setCover(int index) {
    if (index < 0 || index >= _drafts.length) return;
    for (var i = 0; i < _drafts.length; i++) {
      _drafts[i].isCover = i == index;
    }
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _drafts.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target > _drafts.length) target = _drafts.length;
    final moved = _drafts.removeAt(oldIndex);
    _drafts.insert(target, moved);
    notifyListeners();
  }
}
