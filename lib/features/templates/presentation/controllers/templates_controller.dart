/// Riverpod controllers and providers for the Templates feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage/hive_local_storage.dart';
import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';
import '../../data/repositories/templates_repository_impl.dart';

// ── Dependency Injection ──────────────────────────────────────────────────────

final _templatesStorageProvider = Provider<ILocalStorage>((ref) => HiveLocalStorage());

final templatesRepositoryProvider = Provider<TemplatesRepositoryImpl>((ref) {
  final storage = ref.watch(_templatesStorageProvider);
  return TemplatesRepositoryImpl(storage);
});

// ── State Notifier ────────────────────────────────────────────────────────────

class TemplatesController extends StateNotifier<List<NoteTemplateModel>> {
  TemplatesController(this._repository) : super([]) {
    loadTemplates();
  }

  final TemplatesRepositoryImpl _repository;

  void loadTemplates() {
    state = _repository.getTemplates();
  }

  Future<void> addTemplate(NoteTemplateModel template) async {
    await _repository.saveTemplate(template);
    loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _repository.deleteTemplate(id);
    loadTemplates();
  }
}

/// Provides the complete list of note templates.
final templatesProvider =
    StateNotifierProvider<TemplatesController, List<NoteTemplateModel>>((ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return TemplatesController(repository);
});
