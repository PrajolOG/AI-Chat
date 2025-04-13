// format.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart'; // Using this theme
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

// --- renderInline helper ---
String renderInline(List<md.Node> nodes) {
  try {
    return nodes
        .map(
          (node) =>
              node is md.Text
                  ? node.text
                  : (node is md.Element
                      ? renderInline(node.children ?? [])
                      : ''),
        )
        .join();
  } catch (e, stackTrace) {
    debugPrint(
      '[FormattedText] Error in renderInline: $e\nStackTrace: $stackTrace',
    );
    return nodes.map((n) => n is md.Text ? n.text : '?').join();
  }
}

// --- FormattedText class ---
class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final Color? backgroundColor;

  const FormattedText({
    super.key,
    required this.text,
    this.textStyle,
    this.textAlign,
    this.backgroundColor,
  });

  // --- _isMath ---
  bool get _isMath {
    try {
      final trimmed = text.trim();
      return (trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$')) ||
          (trimmed.startsWith(r'\(') && trimmed.endsWith(r'\)')) ||
          (trimmed.startsWith(r'$') &&
              trimmed.endsWith(r'$') &&
              trimmed.length > 2);
    } catch (e, stackTrace) {
      debugPrint(
        '[FormattedText] Error checking _isMath for text: "$text"\nError: $e\nStackTrace: $stackTrace',
      );
      return false;
    }
  }

  // --- _isMarkdown ---
  bool get _isMarkdown {
    try {
      final trimmed = text.trim();
      // Add URL pattern detection
      final urlPattern = RegExp(
        r'^(https?:\/\/)?([\w\-])+\.{1}([a-zA-Z]{2,63})([\/\w-]*)*\/?\??([^#\n\r]*)?#?([^\n\r]*)',
        multiLine: true,
      );

      bool hasUrl = urlPattern.hasMatch(trimmed);
      bool hasCodeBlock = RegExp(r"```[\s\S]*?```").hasMatch(trimmed);
      bool hasOtherMarkdown = RegExp(
        r"^(#{1,6}\s|\s*[-*+]\s|\s*\d+\.\s|\s*>|\|.*\||\[.+?\]\(.+?\)|`[^`]+`)",
        multiLine: true,
      ).hasMatch(trimmed);
      bool hasIndentedCode = RegExp(
        r"^(?: {4}|\t)",
        multiLine: true,
      ).hasMatch(trimmed);
      return hasUrl || hasCodeBlock || hasOtherMarkdown || hasIndentedCode;
    } catch (e, stackTrace) {
      debugPrint(
        '[FormattedText] Error checking _isMarkdown for text: "$text"\nError: $e\nStackTrace: $stackTrace',
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final defaultTextStyle =
          textStyle ??
          Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 16) ??
          const TextStyle(color: Colors.white, fontSize: 16);

      final inlineCodeStyle = defaultTextStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: const Color.fromARGB(255, 15, 83, 50),
        color: Colors.grey[200],
      );

      final markdownStyleSheet = MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(
        p: defaultTextStyle,
        a: const TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
        ),
        code: inlineCodeStyle,
        codeblockPadding: const EdgeInsets.all(12.0), // Add padding
        codeblockDecoration: BoxDecoration(
          // Add decoration
          color: const Color.fromARGB(
            255,
            15,
            83,
            50,
          ), // Match EnhancedCodeView background
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: const Color.fromARGB(
              255,
              0,
              0,
              0,
            ), // Match EnhancedCodeView border
            width: 0.5,
          ),
        ),
        h1: defaultTextStyle.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        h2: defaultTextStyle.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        h3: defaultTextStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        em: defaultTextStyle.copyWith(fontStyle: FontStyle.italic),
        strong: defaultTextStyle.copyWith(fontWeight: FontWeight.bold),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.5),
          border: Border(
            left: BorderSide(color: Colors.grey.shade600, width: 4),
          ),
        ),
        listBullet: defaultTextStyle,
        tableHead: defaultTextStyle.copyWith(fontWeight: FontWeight.bold),
        tableBody: defaultTextStyle,
        tableBorder: TableBorder.all(
          color: const Color.fromARGB(255, 116, 116, 116),
          width: 1.5,
        ),
        tableCellsPadding: const EdgeInsets.all(6.0),
      );

      return Container(
        color: backgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            try {
              if (_isMath) {
                return EnhancedMathView(
                  mathText: text,
                  textStyle: defaultTextStyle.copyWith(fontSize: 18),
                  backgroundColor: Colors.transparent,
                );
              } else if (_isMarkdown) {
                return MarkdownBody(
                  data: text,
                  styleSheet: markdownStyleSheet,
                  selectable: true,
                  shrinkWrap: false,
                  fitContent: false,
                  onTapLink: (text, href, title) {
                    if (href != null) _launchURL(href, context);
                  },
                  builders: {
                    'table': ScrollableTableBuilder(
                      styleSheet: markdownStyleSheet,
                    ),
                    // Use the updated CustomPreBuilder
                    //'pre': CustomPreBuilder(),
                  },
                  extensionSet: md.ExtensionSet.gitHubWeb,
                );
              } else {
                return SelectableText(
                  text,
                  style: defaultTextStyle,
                  textAlign: textAlign,
                );
              }
            } catch (e, stackTrace) {
              developer.log(
                '[FormattedText] Error during specific content rendering (Math/MD/Plain):\nError: $e\nInput Text: "$text"',
                name: 'FormattedText.build.inner',
                error: e,
                stackTrace: stackTrace,
              );
              return _buildErrorWidget(
                'Error rendering content.',
                defaultTextStyle,
              );
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        '[FormattedText] Error in FormattedText.build setup:\nError: $e\nInput Text: "$text"',
        name: 'FormattedText.build.outer',
        error: e,
        stackTrace: stackTrace,
      );
      final fallbackStyle =
          textStyle ?? const TextStyle(color: Colors.redAccent, fontSize: 14);
      return _buildErrorWidget(
        'Error displaying formatted text.',
        fallbackStyle,
      );
    }
  }

  // --- _buildErrorWidget helper ---
  Widget _buildErrorWidget(String message, TextStyle? style) {
    return Container(
      color: backgroundColor ?? Colors.grey.shade900,
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(
        '$message\nOriginal text:\n$text',
        style:
            style?.copyWith(color: Colors.redAccent[100]) ??
            const TextStyle(color: Colors.redAccent, fontSize: 14),
      ),
    );
  }

  // --- _launchURL helper ---
  Future<void> _launchURL(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        developer.log(
          '[FormattedText] Could not launch $url (launchUrl returned false)',
          name: 'FormattedText.launchUrl',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '[FormattedText] Error launching URL: $url',
        name: 'FormattedText.launchUrl',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening link: $url')));
      }
    }
  }
}

// --- ScrollableTableBuilder ---
// Keep implementation exactly the same as before
class ScrollableTableBuilder extends MarkdownElementBuilder {
  final MarkdownStyleSheet styleSheet;
  ScrollableTableBuilder({required this.styleSheet});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      final rows = _buildTableRows(element);
      if (rows.isEmpty) {
        developer.log(
          '[ScrollableTableBuilder] No valid rows found for table element.',
          name: 'ScrollableTableBuilder.visit',
        );
        return const SizedBox.shrink();
      }

      final columnCount = rows.first.children?.length ?? 0;
      if (columnCount == 0) return const SizedBox.shrink();

      bool uniformColumns = rows.every(
        (row) => (row.children?.length ?? 0) == columnCount,
      );
      if (!uniformColumns) {
        developer.log(
          '[ScrollableTableBuilder] Table rows have inconsistent column counts.',
          name: 'ScrollableTableBuilder.visit',
        );
        return _buildErrorWidget('Malformed table: Inconsistent column counts');
      }

      final table = Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.shade700,
            width: 1,
            style: BorderStyle.solid,
          ),
          verticalInside: BorderSide(
            color: Colors.grey.shade700,
            width: 1,
            style: BorderStyle.solid,
          ),
          top: BorderSide(
            color: Colors.grey.shade600,
            width: 2,
            style: BorderStyle.solid,
          ),
          bottom: BorderSide(
            color: Colors.grey.shade600,
            width: 1,
            style: BorderStyle.solid,
          ),
          left: BorderSide(
            color: Colors.grey.shade600,
            width: 1,
            style: BorderStyle.solid,
          ),
          right: BorderSide(
            color: Colors.grey.shade600,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        columnWidths: {
          for (int i = 0; i < columnCount; i++)
            i: const IntrinsicColumnWidth(flex: 1),
        },
        children: rows,
      );

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Builder(
            builder:
                (context) => ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(2.0),
                    child: table,
                  ),
                ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        '[ScrollableTableBuilder] Error processing table element: ${element.textContent}',
        name: 'ScrollableTableBuilder.visit',
        error: e,
        stackTrace: stackTrace,
      );
      return _buildErrorWidget('Error rendering table');
    }
  }

  List<TableRow> _buildTableRows(md.Element element) {
    final List<TableRow> rows = [];
    try {
      final List<md.Element> children =
          element.children?.whereType<md.Element>().toList() ?? [];

      for (final child in children) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          final List<md.Element> trs =
              child.children?.whereType<md.Element>().toList() ?? [];
          for (final tr in trs) {
            try {
              if (tr.tag == 'tr') {
                rows.add(_buildTableRow(tr, child.tag == 'thead'));
              }
            } catch (e, stackTrace) {
              developer.log(
                '[ScrollableTableBuilder] Error building table row from <tr>: ${tr.textContent}',
                name: 'ScrollableTableBuilder._buildTableRows.inner',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        } else if (child.tag == 'tr') {
          try {
            rows.add(_buildTableRow(child, false));
          } catch (e, stackTrace) {
            developer.log(
              '[ScrollableTableBuilder] Error building table row from <tr>: ${child.textContent}',
              name: 'ScrollableTableBuilder._buildTableRows.outer',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '[ScrollableTableBuilder] Error iterating table children: ${element.textContent}',
        name: 'ScrollableTableBuilder._buildTableRows.outermost',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return rows;
  }

  TableRow _buildTableRow(md.Element trElement, bool isHeader) {
    final List<Widget> cells = [];
    final List<md.Element> children =
        trElement.children?.whereType<md.Element>().toList() ?? [];

    for (final cellElement in children) {
      if (cellElement.tag == 'th' || cellElement.tag == 'td') {
        final cellMarkdownContent = renderInline(cellElement.children ?? []);
        final cellWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          color: Colors.transparent,
          child: Text(
            cellMarkdownContent.isEmpty ? ' ' : cellMarkdownContent,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
              height: 1.3,
            ),
            textAlign: TextAlign.left,
          ),
        );

        cells.add(
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: cellWidget,
          ),
        );
      }
    }
    return TableRow(children: cells);
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.red.shade900.withOpacity(0.5),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        message,
        style: (styleSheet.tableBody ?? const TextStyle()).copyWith(
          color: Colors.white70,
        ),
      ),
    );
  }
}

// =========================================================================
// Enhanced Code View Widget - **MODIFIED TO ACCEPT PARSED DATA**
// =========================================================================
class EnhancedCodeView extends StatelessWidget {
  // Parameters now accept pre-parsed language and content
  final String language;
  final String codeContent;
  final TextStyle? textStyle;
  final Color backgroundColor;

  const EnhancedCodeView({
    super.key,
    required this.language, // Expect language directly
    required this.codeContent, // Expect code content directly
    this.textStyle,
    this.backgroundColor = const Color(0xFF282c34), // Atom One Dark default bg
  });

  @override
  Widget build(BuildContext context) {
    try {
      // --- REMOVED Internal Parsing Logic ---
      // No need to parse ```block``` format here anymore

      // --- Style Definitions --- (Keep as is)
      final syntaxHighlightTheme = atomOneDarkReasonableTheme;
      final baseCodeStyle =
          textStyle ??
          syntaxHighlightTheme['root']?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.4,
          ) ??
          const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.4,
            color: Color(0xffabb2bf), // Default text color from theme
          );

      final copyButtonColor = Colors.grey[400];
      final languageIndicatorColor = Colors.grey[300];
      final languageIndicatorBg = Colors.black.withOpacity(0.3);
      final subtleBorderColor = Colors.grey.shade700;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: subtleBorderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // --- Code Area ---
            Padding(
              padding: const EdgeInsets.only(
                top: 38.0,
                bottom: 12.0,
                left: 12.0,
                right: 12.0,
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Builder(
                    builder: (context) {
                      try {
                        return HighlightView(
                          // Use the passed codeContent directly
                          codeContent,
                          // Use the passed language directly
                          language:
                              language.toLowerCase().isEmpty
                                  ? 'plaintext'
                                  : language.toLowerCase(),
                          theme: syntaxHighlightTheme,
                          textStyle: baseCodeStyle.copyWith(
                            backgroundColor: Colors.transparent,
                          ),
                          padding: EdgeInsets.zero,
                        );
                      } catch (e, stackTrace) {
                        developer.log(
                          '[EnhancedCodeView] Error during HighlightView rendering:\nLanguage: $language\nError: $e',
                          name: 'EnhancedCodeView.HighlightView',
                          error: e,
                          stackTrace: stackTrace,
                          level: 900,
                        );
                        return SelectableText(
                          codeContent, // Display raw content on error
                          style: baseCodeStyle.copyWith(
                            color: Colors.orangeAccent,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            // --- Language Indicator (Top Left) ---
            // Use the passed language directly
            if (language.isNotEmpty)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: languageIndicatorBg,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: TextStyle(
                      color: languageIndicatorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // --- Copy Button (Top Right) ---
            Positioned(
              top: 6.0,
              right: 6.0,
              child: InkWell(
                onTap: () {
                  try {
                    // Copy the passed codeContent directly
                    Clipboard.setData(ClipboardData(text: codeContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        backgroundColor: Colors.black87,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                    );
                  } catch (e, stackTrace) {
                    developer.log(
                      '[EnhancedCodeView] Error copying to clipboard',
                      name: 'EnhancedCodeView.Copy',
                      error: e,
                      stackTrace: stackTrace,
                      level: 1000,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error copying code!'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_copy_rounded,
                        size: 14,
                        color: copyButtonColor,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        'COPY',
                        style: TextStyle(
                          color: copyButtonColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        '[EnhancedCodeView] Error building EnhancedCodeView widget',
        name: 'EnhancedCodeView.build',
        error: e,
        stackTrace: stackTrace,
        level: 1200,
      );
      // Use codeContent in the fallback display
      return Container(
        color: Colors.red.shade900.withOpacity(0.7),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.redAccent.shade100, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: SelectableText(
          '⚠ Error displaying code block.\n--- Raw Content ---\n$codeContent',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      );
    }
  }
}

// --- EnhancedMathView ---
// Keep implementation exactly the same as before
class EnhancedMathView extends StatelessWidget {
  final String mathText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const EnhancedMathView({
    super.key,
    required this.mathText,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // --- Math Parsing Logic ---
      String trimmed = mathText.trim();
      String expression = '';
      bool isBlock = false;

      if (trimmed.startsWith(r'$$') &&
          trimmed.endsWith(r'$$') &&
          trimmed.length >= 4) {
        expression = trimmed.substring(2, trimmed.length - 2).trim();
        isBlock = true;
      } else if (trimmed.startsWith(r'\(') &&
          trimmed.endsWith(r'\)') &&
          trimmed.length >= 4) {
        expression = trimmed.substring(2, trimmed.length - 2).trim();
        isBlock = false;
      } else if (trimmed.startsWith(r'$') &&
          trimmed.endsWith(r'$') &&
          trimmed.length >= 2) {
        expression = trimmed.substring(1, trimmed.length - 1).trim();
        if (expression.contains('\n')) {
          isBlock = true;
        } else {
          isBlock =
              expression.contains(r'\frac') ||
              expression.contains(r'\sum') ||
              expression.contains(r'\int') ||
              expression.contains(r'\lim') ||
              expression.contains(r'\begin{');
        }
      } else {
        developer.log(
          '[EnhancedMathView] Input does not match expected math format: "$mathText"',
          name: 'EnhancedMathView.build',
          level: 700,
        );
        return _buildErrorWidget('Invalid math format', textStyle);
      }

      if (expression.isEmpty) {
        developer.log(
          '[EnhancedMathView] Extracted math expression is empty for: "$mathText"',
          name: 'EnhancedMathView.build',
          level: 700,
        );
        return const SizedBox.shrink();
      }
      // --- End Extraction ---

      final defaultStyle =
          Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 18) ??
          const TextStyle(fontSize: 18, color: Colors.white);
      final effectiveTextStyle = textStyle ?? defaultStyle;

      return Container(
        color: backgroundColor ?? Colors.transparent,
        padding: padding,
        width: double.infinity,
        alignment: isBlock ? Alignment.center : Alignment.centerLeft,
        child: Math.tex(
          expression,
          mathStyle: isBlock ? MathStyle.display : MathStyle.text,
          textStyle: effectiveTextStyle,
          onErrorFallback: (FlutterMathException e) {
            developer.log(
              '[EnhancedMathView] flutter_math_fork Error: ${e.message}\nExpression: "$expression"\nOriginal Input: "$mathText"',
              name: 'EnhancedMathView.onErrorFallback',
              error: e,
              level: 1000,
            );
            return SelectableText(
              'Error rendering math: ${e.message}\nExpression: $expression',
              style: effectiveTextStyle.copyWith(
                color: Colors.redAccent[100],
                fontSize: 14,
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        '[EnhancedMathView] Error building EnhancedMathView',
        name: 'EnhancedMathView.build.outer',
        error: e,
        stackTrace: stackTrace,
        level: 1200,
      );
      return _buildErrorWidget('Error displaying math', textStyle);
    }
  }

  Widget _buildErrorWidget(String message, TextStyle? style) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      padding: padding,
      alignment: Alignment.centerLeft,
      child: SelectableText(
        '$message\nOriginal: $mathText',
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.redAccent[100],
          fontSize: 14,
        ),
      ),
    );
  }
}

// Add this class after the other formatting widgets

class EnhancedUrlView extends StatelessWidget {
  final String url;
  final TextStyle? textStyle;
  final bool showIcon;

  const EnhancedUrlView({
    super.key,
    required this.url,
    this.textStyle,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        textStyle ??
        const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          decoration: TextDecoration.underline,
        );

    return InkWell(
      onTap: () => _launchURL(url, context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(Icons.link, size: 16, color: defaultStyle.color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                url,
                style: defaultStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open URL: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '[EnhancedUrlView] Error launching URL',
        name: 'EnhancedUrlView.launchUrl',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid URL format'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Copy URL',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
              },
            ),
          ),
        );
      }
    }
  }
}
