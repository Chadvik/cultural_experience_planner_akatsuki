import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EtiquetteQuizPage extends StatefulWidget {
  const EtiquetteQuizPage({super.key});

  @override
  _EtiquetteQuizPageState createState() => _EtiquetteQuizPageState();
}

class _EtiquetteQuizPageState extends State<EtiquetteQuizPage>
    with SingleTickerProviderStateMixin {
  int _score = 0;
  int _currentQuestionIndex = 0;
  String _selectedOption = '';
  bool _isAnswerSelected = false;
  bool _isAnswerCorrect = false;
  List<Map<String, dynamic>> _questions = [];
  late Map<String, dynamic> _currentQuestion;
  late ConfettiController _confettiController;
  bool _isLoading = true;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(_scaleController)..addListener(() {
      setState(() {});
    });
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      QuerySnapshot questionSnapshot =
      await FirebaseFirestore.instance
          .collection('kbc')
          .where('type', isEqualTo: 'etiquette') // Fixed syntax here
          .limit(5)
          .get();

      setState(() {
        _questions =
            questionSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        if (_questions.isEmpty) {
          _questions = [
            {
              'question': 'Default Question',
              'goodEtiquetteURL': 'https://via.placeholder.com/150',
              'badEtiquetteURL': 'https://via.placeholder.com/150',
              'correctOption': 'goodEtiquetteURL',
              'teaching': 'This is a default teaching message.',
            },
          ];
        }
        _currentQuestion = _questions[_currentQuestionIndex];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _questions = [
          {
            'question': 'Error Loading Question',
            'goodEtiquetteURL': 'https://via.placeholder.com/150',
            'badEtiquetteURL': 'https://via.placeholder.com/150',
            'correctOption': 'goodEtiquetteURL',
            'teaching': 'Failed to load teaching message.',
          },
        ];
        _currentQuestion = _questions[_currentQuestionIndex];
        _isLoading = false;
      });
    }
  }

  void _checkAnswer(String selectedOption) {
    setState(() {
      _selectedOption = selectedOption;
      _isAnswerSelected = true;
      _isAnswerCorrect = _selectedOption == _currentQuestion['correctOption'];

      if (_isAnswerCorrect) {
        _score += 10;
        _confettiController.play();
      }
      _scaleController.forward(from: 0.0);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_isAnswerCorrect && _currentQuestionIndex < 4) {
          setState(() {
            _currentQuestionIndex++;
            _selectedOption = '';
            _isAnswerSelected = false;
            _isAnswerCorrect = false;
            _currentQuestion = _questions[_currentQuestionIndex];
            _scaleController.reset();
          });
        } else {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
              title: Text(
                _currentQuestionIndex == 4 ? 'Game Over' : 'Incorrect',
              ),
              content: Text(
                _currentQuestionIndex == 4
                    ? 'Your final score is $_score/50 points!'
                    : 'You selected the wrong etiquette image. Game over!\nYour score: $_score/50',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Etiquette Quiz'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Etiquette Quiz', style: TextStyle(color: Colors.white)),
            Text(
              'Score: $_score/50',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        elevation: 8,
        shadowColor: Colors.black45,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[300]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height:
                  screenHeight -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) / 5,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.deepPurple,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Round ${_currentQuestionIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _currentQuestion['question'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildOptionImage(
                                          'goodEtiquetteURL',
                                          'Option A',
                                          screenWidth,
                                        ),
                                        _buildOptionImage(
                                          'badEtiquetteURL',
                                          'Option B',
                                          screenWidth,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_isAnswerSelected) ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey[100]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _currentQuestion['teaching'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                              .animate()
                              .fadeIn(
                            duration: const Duration(milliseconds: 600),
                          )
                              .slideY(begin: 0.2, end: 0),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  transform: Matrix4.rotationZ(
                                    _isAnswerCorrect ? 0 : 3.14,
                                  ),
                                  child: Icon(
                                    _isAnswerCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                    _isAnswerCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    size: screenWidth * 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isAnswerCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                    _isAnswerCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isAnswerCorrect
                                        ? 'Correct!'
                                        : 'Incorrect!',
                                    style: TextStyle(
                                      color:
                                      _isAnswerCorrect
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.purple,
                Colors.orange,
                Colors.green,
                Colors.red,
                Colors.blue,
              ],
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionImage(String key, String label, double screenWidth) {
    bool isSelected = _selectedOption == key;
    final imageSize = screenWidth * 0.4;

    return Flexible(
      child: GestureDetector(
        onTap: !_isAnswerSelected ? () => _checkAnswer(key) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: imageSize,
          height: imageSize + 40,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color:
              _isAnswerSelected
                  ? (isSelected
                  ? (_isAnswerCorrect ? Colors.green : Colors.red)
                  : Colors.grey)
                  : Colors.deepPurple,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isSelected && _isAnswerSelected ? 0.3 : 0.1,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _currentQuestion[key],
                  fit: BoxFit.cover,
                  width: imageSize - 6,
                  height: imageSize - 6,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Image failed to load'));
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 400));
  }
}