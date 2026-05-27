/// Concrete implementation of the templates repository backed by local storage.
library templates_repository_impl;

import '../../../../core/services/storage/i_local_storage.dart';
import '../../../../models/models.dart';

class TemplatesRepositoryImpl {
  const TemplatesRepositoryImpl(this._storage);

  final ILocalStorage _storage;

  List<NoteTemplateModel> getTemplates() => _storage.getTemplates();
  Future<void> saveTemplate(NoteTemplateModel template) => _storage.saveTemplate(template);
  Future<void> deleteTemplate(String id) => _storage.deleteTemplate(id);
}
