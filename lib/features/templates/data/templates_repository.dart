import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/local_storage.dart';
import '../../../models/models.dart';

class TemplatesNotifier extends StateNotifier<List<NoteTemplateModel>> {
  final LocalStorage _storage;

  TemplatesNotifier(this._storage) : super([]) {
    loadTemplates();
  }

  void loadTemplates() {
    state = _storage.getTemplates();
  }

  Future<void> addTemplate(NoteTemplateModel template) async {
    await _storage.saveTemplate(template);
    loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _storage.deleteTemplate(id);
    loadTemplates();
  }
}

final templatesStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final templatesProvider = StateNotifierProvider<TemplatesNotifier, List<NoteTemplateModel>>((ref) {
  final storage = ref.watch(templatesStorageProvider);
  return TemplatesNotifier(storage);
});
