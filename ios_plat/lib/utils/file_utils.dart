import 'dart:io';
import '../models/question.dart';
import 'package:file_picker/file_picker.dart';

Future<String?> pickTxtFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['txt'],
  );

  if (result != null) {
    return result.files.single.path;
  }
  return null;
}

Future<List<Question>> parseTxtFile(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();

  List<Question> questions = [];
  String? currentQuestion;
  List<String> options = [];
  int correctAnswerIndex = -1;

  for (var line in lines) {
    if (line.startsWith('<question>')) {
      if (currentQuestion != null) {
        questions.add(Question(
          questionText: currentQuestion,
          options: options,
          correctAnswerIndex: correctAnswerIndex,
        ));
      }
      currentQuestion = line.replaceFirst('<question>', '').trim();
      options = [];
      correctAnswerIndex = -1;
    } else if (line.startsWith('<variant>')) {
      final option = line.replaceFirst('<variant>', '').trim();
      if (correctAnswerIndex == -1) {
        correctAnswerIndex = options.length;
      }
      options.add(option);
    }
  }

  if (currentQuestion != null) {
    questions.add(Question(
      questionText: currentQuestion,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
    ));
  }

  return questions;
}
