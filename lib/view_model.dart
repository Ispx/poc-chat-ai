import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poc_gemini_ia/models.dart';
import 'package:poc_gemini_ia/repository.dart';
import 'package:share_plus/share_plus.dart';

class ViewModel with ChangeNotifier {
  final IARepository repository;
  ViewModel({required this.repository});

  List<Content> contents = [];
  List<Part> systemInstructions = [];
  var isloadingFile = false;
  var isloading = false;

  File? file;
  Future<void> chat(String text) async {
    contents.add(
      Content(
        parts: [TextPart(text: text)],
        role: "user",
      ),
    );
    isloading = true;
    notifyListeners();

    final generateContent = await repository.chat(
      contents: [...contents],
      systemInstructions: systemInstructions,
    );

    for (var candidates in generateContent.candidates) {
      if (candidates.content != null) {
        addContent(candidates.content!);
      }
    }
    isloading = false;
    notifyListeners();
  }

  Future<void> chatStream(String text) async {
    contents.add(
      Content(
        parts: [TextPart(text: text)],
        role: "user",
      ),
    );
    isloading = true;
    notifyListeners();
    repository.chatStream(
      contents: [...contents],
      systemInstructions: systemInstructions,
    ).listen(
      (generateContent) {
        for (var candidates in generateContent.candidates) {
          if (candidates.content != null) {
            addContent(candidates.content!);
          }
        }
      },
      onDone: () {
        isloading = false;
        notifyListeners();
      },
    );
  }

  Future<void> downloadFile(File file) async {
    XFile xFile = XFile(
      file.path,
      bytes: await file.readAsBytes(),
    );
    Share.shareXFiles(
      [xFile],
    );
  }

  void addContent(Content content) {
    contents.add(content);
    notifyListeners();
  }

  void addSystemInstructions(List<Part> parts) {
    systemInstructions.addAll(parts);
    notifyListeners();
  }
}
