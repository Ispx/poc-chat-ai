import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:poc_gemini_ia/models.dart';

abstract interface class IARepository {
  Future<Generator> chat({
    required List<Content> contents,
    List<Part>? systemInstructions,
  });
  Stream<Generator> chatStream({
    required List<Content> contents,
    List<Part>? systemInstructions,
  });
}

class IARepositoryImpl implements IARepository {
  final apiKey = const String.fromEnvironment("API_KEY");
  late final _url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");
  late final _urlStream = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent?alt=sse&key=$apiKey");

  @override
  Future<Generator> chat({
    required List<Content> contents,
    List<Part>? systemInstructions,
  }) async {
    try {
      var body = {
        "tools": [
          {
            "code_execution": {},
          }
        ],
        "system_instruction": {
          "parts": [
            ...systemInstructions?.map((e) => e.toJson()).toList() ?? [],
          ]
        },
        "contents": [
          ...contents.map((e) => e.toJson()),
        ],
        "generationConfig": {
          "stopSequences": [],
          "thinkingConfig": {
            "thinkingBudget": 1024,
          },
          "temperature": 0.5,
          "maxOutputTokens": 800,
          "topP": 0.8,
          "topK": 10
        }
      };
      var response = await http.post(
        _url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      return Generator.fromJson(jsonDecode(response.body));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Generator> chatStream(
      {required List<Content> contents,
      List<Part>? systemInstructions}) async* {
    try {
      var body = {
        "tools": [
          {
            "code_execution": {},
          }
        ],
        "system_instruction": {
          "parts": [
            ...systemInstructions?.map((e) => e.toJson()).toList() ?? [],
          ]
        },
        "contents": [
          ...contents.map((e) => e.toJson()),
        ],
        "generationConfig": {
          "stopSequences": [],
          "temperature": 0.5,
          "maxOutputTokens": 800,
          "topP": 0.8,
          "topK": 10
        }
      };
      var response = await http.post(
        _urlStream,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      final utf8Body = utf8.decode(response.bodyBytes);

      final rows = utf8Body.split('\n');
      for (final row in rows) {
        if (row.trim().startsWith('data: ')) {
          final jsonStr = row.trim().substring(6);
          try {
            final data = jsonDecode(jsonStr);
            yield Generator.fromJson(data);
          } catch (e) {
            print('Erro ao decodificar JSON: $e');
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
