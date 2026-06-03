import 'package:flutter/material.dart';
import '../../../../../models/models.dart';
import '../panels/pdf_export_dialog.dart';

class EditorRouteActions {
  static void exportToPdf(BuildContext context, NoteModel note) {
    PdfExportDialog.show(context, note);
  }
}
