import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Generator {
  Generator({
    required this.candidates,
    required this.usageMetadata,
    required this.modelVersion,
  });

  final List<Candidate> candidates;
  final UsageMetadata? usageMetadata;
  final String? modelVersion;

  factory Generator.fromJson(Map<String, dynamic> json) {
    return Generator(
      candidates: json["candidates"] == null
          ? []
          : List<Candidate>.from(
              json["candidates"]!.map((x) => Candidate.fromJson(x))),
      usageMetadata: json["usageMetadata"] == null
          ? null
          : UsageMetadata.fromJson(json["usageMetadata"]),
      modelVersion: json["modelVersion"],
    );
  }
}

class Candidate {
  Candidate({
    required this.content,
    required this.finishReason,
  });

  final Content? content;
  final String? finishReason;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      content:
          json["content"] == null ? null : Content.fromJson(json["content"]),
      finishReason: json["finishReason"],
    );
  }
}

class Content {
  Content({
    required this.parts,
    required this.role,
  });

  final List<Part> parts;
  final String? role;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      parts: json["parts"] == null
          ? []
          : List<Part>.from(
              json["parts"]!.map(
                (x) {
                  if (x['executableCode'] != null) {
                    return ExecutableCodePart.fromJson(x['executableCode']);
                  }

                  if (x['codeExecutionResult'] != null) {
                    return CodeExecutionResultPart.fromJson(
                        x['codeExecutionResult']);
                  }

                  if (x['inlineData'] != null) {
                    return InlinePart.fromJson(x['inlineData']);
                  }
                  return TextPart.fromJson(x);
                },
              ),
            ),
      role: json["role"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "parts": parts.map((x) => x.toJson()).toList(),
      "role": role,
    };
  }
}

abstract class Part {
  Map<String, dynamic> toJson();
  @override
  String toString();
}

class TextPart extends Part {
  TextPart({
    required this.text,
  });

  final String? text;
  factory TextPart.fromJson(Map<String, dynamic> json) {
    return TextPart(
      text: json["text"],
    );
  }

  @override
  Map<String, String> toJson() {
    return {
      "text": text!,
    };
  }

  @override
  String toString() {
    return text ?? '';
  }
}

class EmpityPart extends Part {
  @override
  Map<String, String> toJson() {
    return {};
  }
}

class CodeExecutionResultPart extends Part {
  CodeExecutionResultPart({
    required this.outcome,
    required this.output,
  });

  final String outcome;
  final String output;

  factory CodeExecutionResultPart.fromJson(Map<String, dynamic> json) {
    return CodeExecutionResultPart(
      outcome: json["outcome"],
      output: json["output"],
    );
  }

  Future<File> generateFile() async {
    var type = 'txt';
    type = type.contains(RegExp('sheet')) ? 'xlsx' : type;
    final Directory? downloadsDir = await getDownloadsDirectory();
    final File file = File('${downloadsDir!.path}/file.$type');
    final bytes = output.codeUnits;
    return await file.writeAsBytes(bytes);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "codeExecutionResult": {
        "outcome": outcome,
        "output": output,
      }
    };
  }

  @override
  String toString() {
    return '';
  }
}

class ExecutableCodePart extends Part {
  ExecutableCodePart({
    required this.language,
    required this.code,
  });

  final String language;
  final String code;

  factory ExecutableCodePart.fromJson(Map<String, dynamic> json) {
    return ExecutableCodePart(
      language: json["language"],
      code: json["code"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "executableCode": {
        "language": language,
        "code": code,
      }
    };
  }

  @override
  String toString() {
    return '';
  }
}

class InlinePart extends Part {
  InlinePart({
    required this.mimeType,
    required this.data,
  });

  final String mimeType;
  final String data;

  factory InlinePart.fromJson(Map<String, dynamic> json) {
    return InlinePart(
      mimeType: json["mimeType"],
      data: json["data"],
    );
  }
  Future<File> generateFile() async {
    var type = mimeType.split('/').last;
    type = type.contains(RegExp('sheet')) ? 'xlsx' : type;
    final Directory? downloadsDir = await getDownloadsDirectory();
    final File file = File('${downloadsDir!.path}/file.$type');
    final bytes = base64Decode(data);
    return await file.writeAsBytes(bytes);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "inline_data": {
        "mime_type": mimeType,
        "data": data,
      }
    };
  }

  @override
  String toString() {
    return '';
  }
}

class UsageMetadata {
  UsageMetadata({
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.totalTokenCount,
    required this.promptTokensDetails,
    required this.candidatesTokensDetails,
    required this.toolUsePromptTokensDetails,
  });

  final int? promptTokenCount;
  final int? candidatesTokenCount;
  final int? totalTokenCount;
  final List<TokensDetail> promptTokensDetails;
  final List<TokensDetail> candidatesTokensDetails;
  final List<ToolUsePromptTokensDetail> toolUsePromptTokensDetails;

  factory UsageMetadata.fromJson(Map<String, dynamic> json) {
    return UsageMetadata(
      promptTokenCount: json["promptTokenCount"],
      candidatesTokenCount: json["candidatesTokenCount"],
      totalTokenCount: json["totalTokenCount"],
      promptTokensDetails: json["promptTokensDetails"] == null
          ? []
          : List<TokensDetail>.from(json["promptTokensDetails"]!
              .map((x) => TokensDetail.fromJson(x))),
      candidatesTokensDetails: json["candidatesTokensDetails"] == null
          ? []
          : List<TokensDetail>.from(json["candidatesTokensDetails"]!
              .map((x) => TokensDetail.fromJson(x))),
      toolUsePromptTokensDetails: json["toolUsePromptTokensDetails"] == null
          ? []
          : List<ToolUsePromptTokensDetail>.from(
              json["toolUsePromptTokensDetails"]!
                  .map((x) => ToolUsePromptTokensDetail.fromJson(x))),
    );
  }
}

class TokensDetail {
  TokensDetail({
    required this.modality,
    required this.tokenCount,
  });

  final String? modality;
  final int? tokenCount;

  factory TokensDetail.fromJson(Map<String, dynamic> json) {
    return TokensDetail(
      modality: json["modality"],
      tokenCount: json["tokenCount"],
    );
  }
}

class ToolUsePromptTokensDetail {
  ToolUsePromptTokensDetail({
    required this.modality,
  });

  final String? modality;

  factory ToolUsePromptTokensDetail.fromJson(Map<String, dynamic> json) {
    return ToolUsePromptTokensDetail(
      modality: json["modality"],
    );
  }
}
