import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../utils/file_utils.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  List<Question> _selectedQuestions = [];
  List<List<String>> _shuffledOptions = [];
  int _currentQuestionIndex = 0;
  bool _answered = false;
  int _selectedOptionIndex = -1;
  int _totalQuestions = 5;
  int _correctAnswers = 0;
  final TextEditingController _questionCountController = TextEditingController();
  bool _isQuizStarted = false;

  @override
  void initState() {
    super.initState();
    _questionCountController.text = _totalQuestions.toString();
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final filePath = await pickTxtFile();
      if (filePath != null) {
        final questions = await parseTxtFile(filePath);

        int requestedCount = int.tryParse(_questionCountController.text) ?? _totalQuestions;
        requestedCount = min(requestedCount, questions.length);

        final selectedQuestions = _selectRandomQuestions(questions, requestedCount);
        final shuffledOptions = List<List<String>>.generate(
          selectedQuestions.length,
              (index) => List<String>.from(selectedQuestions[index].options)..shuffle(),
        );

        setState(() {
          _questions = questions;
          _selectedQuestions = selectedQuestions;
          _shuffledOptions = shuffledOptions;
          _currentQuestionIndex = 0;
          _answered = false;
          _selectedOptionIndex = -1;
          _correctAnswers = 0;
          _isQuizStarted = true;
          _totalQuestions = requestedCount;
        });
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text('Не удалось загрузить вопросы: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  List<Question> _selectRandomQuestions(List<Question> questions, int count) {
    if (questions.isEmpty) {
      return [];
    }
    final random = Random();
    final shuffledQuestions = List.of(questions)..shuffle(random);
    return shuffledQuestions.take(min(count, questions.length)).toList();
  }

  void _checkAnswer() {
    final currentQuestion = _selectedQuestions[_currentQuestionIndex];
    final selectedOptionText = _shuffledOptions[_currentQuestionIndex][_selectedOptionIndex];
    if (selectedOptionText == currentQuestion.options[currentQuestion.correctAnswerIndex]) {
      _correctAnswers++;
    }
    setState(() {
      _answered = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _selectedQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOptionIndex = -1;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Тест завершен'),
          content: Text(
              'Вы завершили тест!\nПравильных ответов: $_correctAnswers из $_totalQuestions'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isQuizStarted = false;
                  _questions = [];
                  _selectedQuestions = [];
                  _shuffledOptions = [];
                  _currentQuestionIndex = 0;
                  _answered = false;
                  _selectedOptionIndex = -1;
                  _correctAnswers = 0;
                });
              },
              child: const Text('Начать новый тест'),
            ),
          ],
        ),
      );
    }
  }

  Color _getOptionColor(int optionIndex, bool isCorrect) {
    if (!_answered) {
      return _selectedOptionIndex == optionIndex ? Colors.blue.shade100 : Colors.white;
    }
    if (isCorrect) {
      return Colors.green.shade100;
    }
    return _selectedOptionIndex == optionIndex ? Colors.red.shade100 : Colors.white;
  }

  Color _getOptionBorderColor(int optionIndex, bool isCorrect) {
    if (!_answered) {
      return _selectedOptionIndex == optionIndex ? Colors.blue : Colors.grey;
    }
    if (isCorrect) {
      return Colors.green;
    }
    return _selectedOptionIndex == optionIndex ? Colors.red : Colors.grey;
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Укажите количество вопросов:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _questionCountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Количество вопросов',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestions,
              child: const Text('Загрузить файл с вопросами'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Программу сделал Kenzhebaev Raimbek',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'inst: @rhymebeck',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _selectedQuestions[_currentQuestionIndex];
    final options = _shuffledOptions[_currentQuestionIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _selectedQuestions.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Вопрос ${_currentQuestionIndex + 1}/$_totalQuestions',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: options.asMap().entries.map((entry) {
                      final optionIndex = entry.key;
                      final optionText = entry.value;
                      final isCorrect = optionText == question.options[question.correctAnswerIndex];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: !_answered
                                ? () {
                              setState(() {
                                _selectedOptionIndex = optionIndex;
                              });
                            }
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getOptionColor(optionIndex, isCorrect),
                                border: Border.all(
                                  color: _getOptionBorderColor(optionIndex, isCorrect),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                optionText,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: (_selectedOptionIndex != -1 && !_answered) ? _checkAnswer : null,
                        child: const Text('Проверить'),
                      ),
                      ElevatedButton(
                        onPressed: _answered ? _nextQuestion : null,
                        child: const Text('Далее'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестировщик'),
      ),
      body: !_isQuizStarted ? _buildStartScreen() : _buildQuestionView(),
    );
  }
}
