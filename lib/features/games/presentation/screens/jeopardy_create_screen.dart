import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/jeopardy_game.dart';
import '../../../../shared/widgets/common/adaptive_layout.dart';
import '../providers/jeopardy_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class JeopardyCreateScreen extends StatefulWidget {
  final String? gameId;
  
  const JeopardyCreateScreen({
    super.key,
    this.gameId,
  });

  @override
  State<JeopardyCreateScreen> createState() => _JeopardyCreateScreenState();
}

class _JeopardyCreateScreenState extends State<JeopardyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late JeopardyGame _game;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.gameId != null;
    _loadOrCreateGame();
  }

  void _loadOrCreateGame() async {
    final authProvider = context.read<AuthProvider>();
    final jeopardyProvider = context.read<JeopardyProvider>();
    final currentUserId = authProvider.userModel?.uid ?? '';
    
    if (_isEditing) {
      // Load existing game from Firebase
      final loadedGame = await jeopardyProvider.loadGame(widget.gameId!);
      if (loadedGame != null) {
        setState(() {
          _game = loadedGame;
          _titleController.text = _game.title;
        });
      } else {
        // Handle error - game not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game not found')),
          );
          context.pop();
        }
      }
    } else {
      // Create new game with default structure
      _game = JeopardyGame(
        id: '',
        title: '',
        teacherId: currentUserId,
        categories: [
          JeopardyCategory(
            name: 'Category 1',
            questions: List.generate(5, (index) => JeopardyQuestion(
              question: '',
              answer: '',
              points: (index + 1) * 100,
            )),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveLayout(
      title: _isEditing ? 'Edit Jeopardy Game' : 'Create Jeopardy Game',
      showBackButton: true,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveGame,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Game Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Game Title',
                hintText: 'Enter a title for your Jeopardy game',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a game title';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: theme.textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Category List
            ..._game.categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return _buildCategorySection(index, category);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(int categoryIndex, JeopardyCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: category.name,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _game.categories.length > 1
                            ? () => _removeCategory(categoryIndex)
                            : null,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _game.categories[categoryIndex] = JeopardyCategory(
                          name: value,
                          questions: category.questions,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Questions
            ...category.questions.asMap().entries.map((entry) {
              final questionIndex = entry.key;
              final question = entry.value;
              return _buildQuestionRow(categoryIndex, questionIndex, question);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionRow(int categoryIndex, int questionIndex, JeopardyQuestion question) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$${question.points}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Question field
          TextFormField(
            initialValue: question.question,
            decoration: const InputDecoration(
              labelText: 'Question/Clue',
              hintText: 'Enter the question or clue',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) => _updateQuestion(
              categoryIndex,
              questionIndex,
              question.copyWith(question: value),
            ),
          ),
          const SizedBox(height: 8),
          
          // Answer field
          TextFormField(
            initialValue: question.answer,
            decoration: const InputDecoration(
              labelText: 'Answer',
              hintText: 'Enter the answer (in Jeopardy format)',
              border: OutlineInputBorder(),
              helperText: 'Format: "Who is..." or "What is..."',
            ),
            onChanged: (value) => _updateQuestion(
              categoryIndex,
              questionIndex,
              question.copyWith(answer: value),
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuestion(int categoryIndex, int questionIndex, JeopardyQuestion newQuestion) {
    setState(() {
      final category = _game.categories[categoryIndex];
      final updatedQuestions = List<JeopardyQuestion>.from(category.questions);
      updatedQuestions[questionIndex] = newQuestion;
      
      _game.categories[categoryIndex] = JeopardyCategory(
        name: category.name,
        questions: updatedQuestions,
      );
    });
  }

  void _addCategory() {
    if (_game.categories.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 categories allowed')),
      );
      return;
    }
    
    setState(() {
      _game.categories.add(
        JeopardyCategory(
          name: 'Category ${_game.categories.length + 1}',
          questions: List.generate(5, (index) => JeopardyQuestion(
            question: '',
            answer: '',
            points: (index + 1) * 100,
          )),
        ),
      );
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _game.categories.removeAt(index);
    });
  }

  void _saveGame() async {
    if (_formKey.currentState!.validate()) {
      // Validate all questions have content
      bool hasEmptyQuestions = false;
      for (final category in _game.categories) {
        if (category.name.isEmpty) {
          hasEmptyQuestions = true;
          break;
        }
        for (final question in category.questions) {
          if (question.question.isEmpty || question.answer.isEmpty) {
            hasEmptyQuestions = true;
            break;
          }
        }
      }
      
      if (hasEmptyQuestions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all categories, questions, and answers'),
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      final jeopardyProvider = context.read<JeopardyProvider>();
      
      // Prepare game data
      _game = JeopardyGame(
        id: _game.id,
        title: _titleController.text,
        teacherId: _game.teacherId,
        categories: _game.categories,
        createdAt: _game.createdAt,
        updatedAt: DateTime.now(),
        isPublic: _game.isPublic,
      );
      
      // Save to Firebase
      bool success = false;
      if (_isEditing) {
        success = await jeopardyProvider.updateGame(_game.id, _game);
      } else {
        final gameId = await jeopardyProvider.createGame(_game);
        success = gameId != null;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Game updated!' : 'Game created!'),
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save game. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}