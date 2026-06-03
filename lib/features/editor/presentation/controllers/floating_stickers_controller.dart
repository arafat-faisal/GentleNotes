import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notes/data/models/floating_sticker_model.dart';

class FloatingStickersNotifier extends StateNotifier<List<FloatingStickerModel>> {
  FloatingStickersNotifier() : super(const []);

  void initialize(List<FloatingStickerModel> stickers) {
    state = List.from(stickers);
  }

  void addSticker(FloatingStickerModel sticker) {
    state = [...state, sticker];
  }

  void updateSticker(FloatingStickerModel sticker) {
    state = [
      for (final s in state)
        if (s.id == sticker.id) sticker else s
    ];
  }

  void removeSticker(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

final floatingStickersProvider = StateNotifierProvider.autoDispose<FloatingStickersNotifier, List<FloatingStickerModel>>((ref) {
  return FloatingStickersNotifier();
});

final selectedStickerIdProvider = StateProvider.autoDispose<String?>((ref) => null);

