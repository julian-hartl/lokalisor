import 'dart:convert';

String prettifyJson(String json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(jsonDecode(json));
}
