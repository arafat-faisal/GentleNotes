import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFontOption {
  final String name;
  final String displayName;

  const AppFontOption(this.name, this.displayName);
}

const List<AppFontOption> kAppEditorFonts = [
  AppFontOption('System',           'Default'),
  AppFontOption('Inter',            'Inter'),
  AppFontOption('Outfit',           'Outfit'),
  AppFontOption('Poppins',          'Poppins'),
  AppFontOption('Nunito',           'Nunito'),
  AppFontOption('Roboto',           'Roboto'),
  AppFontOption('Lato',             'Lato'),
  AppFontOption('Open Sans',        'Open Sans'),
  AppFontOption('Lexend',           'Lexend'),
  AppFontOption('DM Sans',          'DM Sans'),
  AppFontOption('Lora',             'Lora'),
  AppFontOption('Merriweather',     'Merriweather'),
  AppFontOption('Playfair Display', 'Playfair Display'),
  AppFontOption('Libre Baskerville','Libre Baskerville'),
  AppFontOption('EB Garamond',      'EB Garamond'),
  AppFontOption('Roboto Mono',      'Roboto Mono'),
  AppFontOption('Fira Code',        'Fira Code'),
  AppFontOption('JetBrains Mono',   'JetBrains Mono'),
  AppFontOption('Source Code Pro',  'Source Code Pro'),
  AppFontOption('Caveat',           'Caveat'),
  AppFontOption('Pacifico',         'Pacifico'),
  AppFontOption('Comfortaa',        'Comfortaa'),
  AppFontOption('Dancing Script',   'Dancing Script'),
];

class FontHelper {
  static TextStyle getTextStyle(String fontName, {TextStyle? baseStyle}) {
    final base = baseStyle ?? const TextStyle();
    if (fontName == 'System' || fontName == 'Sys') {
      return base;
    }
    try {
      return GoogleFonts.getFont(fontName, textStyle: base);
    } catch (_) {
      if (fontName == 'Georgia') {
        return base.copyWith(fontFamily: 'Georgia');
      }
      if (fontName == 'Courier' || fontName == 'Courier New') {
        return base.copyWith(fontFamily: 'Courier');
      }
      return base.copyWith(fontFamily: fontName);
    }
  }

  static String? resolveFontFamily(String? fontFamily) {
    if (fontFamily == null || fontFamily == 'System' || fontFamily == 'Sys' || fontFamily == 'Georgia' || fontFamily == 'Courier') {
      return fontFamily;
    }
    try {
      return GoogleFonts.getFont(fontFamily).fontFamily;
    } catch (_) {
      return fontFamily;
    }
  }
}
