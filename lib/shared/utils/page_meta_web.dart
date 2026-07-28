import 'package:web/web.dart';

import 'page_meta_builder.dart';

void applyPageMeta(PageMetaSnapshot meta) {
  document.title = meta.title;
  _setMetaByName('description', meta.description);
  _setMetaProperty('og:title', meta.ogTitle);
  _setMetaProperty('og:description', meta.description);
  _setMetaProperty('og:url', meta.ogUrl);
  _setMetaProperty('og:type', meta.ogType);
  _setMetaProperty('og:image', meta.ogImage);
  _setMetaByName('twitter:card', 'summary_large_image');
  _setMetaByName('twitter:title', meta.ogTitle);
  _setMetaByName('twitter:description', meta.description);
  _setMetaByName('twitter:image', meta.ogImage);
}

void _setMetaByName(String name, String content) {
  final selector = 'meta[name="$name"]';
  final existing = document.querySelector(selector);
  if (existing == null) {
    final element = HTMLMetaElement()
      ..name = name
      ..content = content;
    document.head?.append(element);
    return;
  }
  (existing as HTMLMetaElement).content = content;
}

void _setMetaProperty(String property, String content) {
  final selector = 'meta[property="$property"]';
  final existing = document.querySelector(selector);
  if (existing == null) {
    final element = HTMLMetaElement()
      ..setAttribute('property', property)
      ..content = content;
    document.head?.append(element);
    return;
  }
  (existing as HTMLMetaElement).content = content;
}
