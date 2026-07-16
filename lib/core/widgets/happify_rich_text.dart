import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HappifyRichText extends StatelessWidget {
  const HappifyRichText(this.data, {super.key});

  final String data;

  static const allowedTags = {
    'html',
    'body',
    'p',
    'br',
    'strong',
    'b',
    'em',
    'i',
    'u',
    's',
    'del',
    'ul',
    'ol',
    'li',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'code',
    'pre',
    'hr',
  };

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Html(
      data: data,
      shrinkWrap: true,
      onlyRenderTheseTags: allowedTags,
      style: {'body': Style.fromTextStyle(textStyle ?? const TextStyle())},
    );
  }
}
