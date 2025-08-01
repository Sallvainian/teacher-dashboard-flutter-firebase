import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/common/common_widgets.dart';
import '../../../../../shared/widgets/preview/preview_example_wrapper.dart';
import '../../../../../shared/widgets/preview/example_badge.dart';
import '../../../../../shared/example/example_repository.dart';
import '../../../../../shared/theme/app_theme.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  String _searchQuery = '';
  String _selectedClassId = '1';

  // Data state - will be replaced with preview examples when empty
  List<Assignment>? _assignments;
  List<GradebookStudent>? _students;

  List<GradebookStudent> get _filteredStudents {
    final students = _students ?? [];
    if (_searchQuery.isEmpty) return students;
    return students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Helper methods to convert example data to local models
  List<Assignment> _convertExampleAssignments(
      List<dynamic> exampleAssignments) {
    return exampleAssignments.map((data) {
      return Assignment(
        id: data['id'],
        name: data['name'],
        type: _parseAssignmentType(data['type']),
        dueDate: data['dueDate'],
        maxPoints: data['maxPoints'],
        weight: data['weight'],
      );
    }).toList();
  }

  AssignmentType _parseAssignmentType(String type) {
    switch (type) {
      case 'homework':
        return AssignmentType.homework;
      case 'quiz':
        return AssignmentType.quiz;
      case 'test':
        return AssignmentType.test;
      case 'project':
        return AssignmentType.project;
      default:
        return AssignmentType.homework;
    }
  }

  List<GradebookStudent> _convertExampleStudents(List<dynamic> exampleGrades) {
    // Group grades by student ID
    final Map<String, List<StudentGrade>> gradesByStudent = {};

    for (final gradeData in exampleGrades) {
      final studentId = gradeData['studentId'];
      final grade = StudentGrade(
        studentId,
        gradeData['assignmentId'],
        gradeData['points'],
        _parseGradeStatus(gradeData['status']),
      );

      gradesByStudent[studentId] ??= [];
      gradesByStudent[studentId]!.add(grade);
    }

    // Create GradebookStudent objects
    final studentNames = {
      'example_student_1': 'Emma Example',
      'example_student_2': 'Marcus Sample',
      'example_student_3': 'Aisha Demo',
      'example_student_4': 'David Preview',
      'example_student_5': 'Sophie Test',
    };

    final studentEmails = {
      'example_student_1': 'emma.example@preview.edu',
      'example_student_2': 'marcus.sample@preview.edu',
      'example_student_3': 'aisha.demo@preview.edu',
      'example_student_4': 'david.preview@preview.edu',
      'example_student_5': 'sophie.test@preview.edu',
    };

    return gradesByStudent.entries.map((entry) {
      return GradebookStudent(
        id: entry.key,
        name: studentNames[entry.key] ?? 'Unknown Student',
        email: studentEmails[entry.key] ?? 'unknown@preview.edu',
        grades: entry.value,
      );
    }).toList();
  }

  GradeStatus _parseGradeStatus(String status) {
    switch (status) {
      case 'graded':
        return GradeStatus.graded;
      case 'missing':
        return GradeStatus.missing;
      case 'late':
        return GradeStatus.late;
      case 'not_submitted':
        return GradeStatus.notSubmitted;
      default:
        return GradeStatus.notSubmitted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get example data from repository
    final exampleAssignments =
        ExampleRepository.of<dynamic>(ExampleDomain.assignments);
    final exampleGrades = ExampleRepository.of<dynamic>(ExampleDomain.grades);

    // For now, simulate that we have no real data (empty state)
    // In a real app, this would come from a provider or service
    final List<Assignment> realAssignments = []; // Simulating empty real data
    final List<GradebookStudent> realStudents =
        []; // Simulating empty real data

    return PreviewExampleWrapper<Assignment>(
      realData: realAssignments,
      exampleData: _convertExampleAssignments(exampleAssignments),
      isLoading: false, // Set to true if loading from service
      builder: (context, assignments, isExample) {
        // Set the current data state
        _assignments = assignments;

        // Convert example grades to students if using examples
        if (isExample) {
          _students = _convertExampleStudents(exampleGrades);
        } else {
          _students = realStudents;
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/dashboard'),
              tooltip: 'Back to Dashboard',
            ),
            title: Row(
              children: [
                const Text('Gradebook'),
                if (isExample) ...[
                  const SizedBox(width: 8),
                  const ExampleBadge.compact(),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _showExportDialog,
                tooltip: 'Export Grades',
              ),
            ],
          ),
          body: _buildGradebookBody(isExample),
          floatingActionButton: FloatingActionButton(
            onPressed: isExample
                ? () => _showExampleDialog(context)
                : _showAddAssignmentDialog,
            child: const Icon(Icons.assignment_add),
          ),
        );
      },
      onExampleTap: () => _showExampleDialog(context),
    );
  }

  Widget _buildGradebookBody(bool isExample) {
    return Column(
      children: [
        // Statistics Header
        _buildStatsHeader(isExample),

        // Class Selector and Search
        _buildControlsSection(isExample),

        // Students List
        Expanded(
          child: _filteredStudents.isEmpty
              ? _searchQuery.isNotEmpty
                  ? EmptyState.noSearchResults(searchTerm: _searchQuery)
                  : isExample
                      ? const EmptyState.noStudents()
                      : const EmptyState.noStudents()
              : _buildStudentsList(isExample),
        ),
      ],
    );
  }

  void _showExampleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Example Gradebook'),
        content: const Text(
          'This is example gradebook data to show you how the app works. '
          'Add your own assignments and students to replace these examples.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddAssignmentDialog();
            },
            child: const Text('Add Assignment'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(bool isExample) {
    final classAverage = _calculateClassAverage();
    final completionRate = _calculateCompletionRate();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatCard(
              title: 'Class Avg',
              value: '${classAverage.toStringAsFixed(1)}%',
              subtitle: _getLetterGrade(classAverage),
              icon: Icons.trending_up,
              valueColor: AppTheme.getGradeColor(_getLetterGrade(classAverage)),
              isExample: isExample,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactStatCard(
              title: 'Completion',
              value: '${completionRate.toStringAsFixed(0)}%',
              subtitle:
                  '${_students?.where((s) => s.grades.any((g) => g.status == GradeStatus.graded)).length ?? 0}/${_students?.length ?? 0} done',
              icon: Icons.assignment_turned_in,
              isExample: isExample,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactStatCard(
              title: 'Students',
              value: '${_students?.length ?? 0}',
              subtitle: 'Enrolled',
              icon: Icons.people,
              isExample: isExample,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color? valueColor,
    bool isExample = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (isExample)
            const Positioned(
              top: 0,
              right: 0,
              child: ExampleBadge.compact(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(bool isExample) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Class Selector
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedClassId,
                isExpanded: true,
                underline: const SizedBox(),
                items: isExample
                    ? [
                        const DropdownMenuItem(
                            value: '1', child: Text('Advanced Mathematics')),
                        const DropdownMenuItem(
                            value: '2', child: Text('Environmental Science')),
                        const DropdownMenuItem(
                            value: '3', child: Text('Creative Writing')),
                        const DropdownMenuItem(
                            value: '4', child: Text('Physics Honors')),
                      ]
                    : [
                        const DropdownMenuItem(
                            value: '1', child: Text('Advanced Mathematics')),
                        const DropdownMenuItem(
                            value: '2', child: Text('Biology Lab')),
                        const DropdownMenuItem(
                            value: '3', child: Text('Creative Writing')),
                      ],
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search Bar
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: isExample
                    ? 'Search example students...'
                    : 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentGradeDetail(GradebookStudent student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentGradeDetailSheet(
        student: student,
        assignments: _assignments ?? [],
        onGradeUpdate: (assignmentId, newPoints, newStatus) {
          setState(() {
            final grade = student.grades
                .firstWhere((g) => g.assignmentId == assignmentId);
            grade.points = newPoints;
            grade.status = newStatus;
          });
        },
      ),
    );
  }

  Widget _buildStudentsList(bool isExample) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student, isExample: isExample);
      },
    );
  }

  Widget _buildStudentCard(GradebookStudent student, {bool isExample = false}) {
    final overallGrade = _calculateStudentOverallGrade(student);
    final completedAssignments =
        student.grades.where((g) => g.status == GradeStatus.graded).length;
    final totalAssignments = _assignments?.length ?? 0;

    return AppCard(
      onTap: isExample
          ? () => _showExampleDialog(context)
          : () => _showStudentGradeDetail(student),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      student.name.split(' ').map((n) => n[0]).join(''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          student.email,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge.grade(grade: _getLetterGrade(overallGrade)),
                      const SizedBox(height: 4),
                      Text(
                        '${overallGrade.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Summary
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assignments Completed',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: totalAssignments > 0
                                    ? completedAssignments / totalAssignments
                                    : 0.0,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$completedAssignments/$totalAssignments',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickStatusChips(student),
                ],
              ),

              const SizedBox(height: 8),

              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isExample ? Icons.info_outline : Icons.touch_app,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isExample
                        ? 'Tap to learn about examples'
                        : 'Tap to view detailed grades',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (isExample)
            const Positioned(
              top: 8,
              right: 8,
              child: ExampleBadge.compact(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusChips(GradebookStudent student) {
    final missingCount =
        student.grades.where((g) => g.status == GradeStatus.missing).length;
    final lateCount =
        student.grades.where((g) => g.status == GradeStatus.late).length;

    return Row(
      children: [
        if (missingCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$missingCount Missing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (lateCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$lateCount Late',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  double _calculateClassAverage() {
    if (_students?.isEmpty ?? true) return 0.0;

    double totalPercentage = 0;
    int studentCount = 0;

    for (final student in _students!) {
      final grade = _calculateStudentOverallGrade(student);
      if (grade > 0) {
        totalPercentage += grade;
        studentCount++;
      }
    }

    return studentCount > 0 ? totalPercentage / studentCount : 0.0;
  }

  double _calculateCompletionRate() {
    if ((_students?.isEmpty ?? true) || (_assignments?.isEmpty ?? true)) {
      return 0.0;
    }

    int totalAssignments = _students!.length * _assignments!.length;
    int completedAssignments = 0;

    for (final student in _students!) {
      for (final grade in student.grades) {
        if (grade.status == GradeStatus.graded) {
          completedAssignments++;
        }
      }
    }

    return (completedAssignments / totalAssignments) * 100;
  }

  double _calculateStudentOverallGrade(GradebookStudent student) {
    if (_assignments?.isEmpty ?? true) return 0.0;

    double totalPoints = 0;
    double maxPoints = 0;

    for (final grade in student.grades) {
      final assignment =
          _assignments!.firstWhere((a) => a.id == grade.assignmentId);
      if (grade.status == GradeStatus.graded && grade.points != null) {
        totalPoints += grade.points!;
        maxPoints += assignment.maxPoints;
      }
    }

    return maxPoints > 0 ? (totalPoints / maxPoints) * 100 : 0.0;
  }

  String _getLetterGrade(double percentage) {
    if (percentage >= 97) return 'A+';
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 65) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }

  void _showAddAssignmentDialog() {
    // Navigate to the assignment creation screen
    context.go('/teacher/assignments/create');
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Grades'),
        content:
            const Text('Export options would appear here (CSV, PDF, etc.).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}

// Student Grade Detail Bottom Sheet
class StudentGradeDetailSheet extends StatelessWidget {
  final GradebookStudent student;
  final List<Assignment> assignments;
  final Function(String assignmentId, double?, GradeStatus) onGradeUpdate;

  const StudentGradeDetailSheet({
    super.key,
    required this.student,
    required this.assignments,
    required this.onGradeUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final overallGrade = _calculateStudentOverallGrade();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  student.name.split(' ').map((n) => n[0]).join(''),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      student.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall Grade Summary
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Grade',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusBadge.grade(
                              grade: _getLetterGrade(overallGrade)),
                          const SizedBox(width: 8),
                          Text(
                            '${overallGrade.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '${student.grades.where((g) => g.status == GradeStatus.graded).length}/${assignments.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Assignment Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          // Assignments List
          Expanded(
            child: ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final grade = student.grades
                    .firstWhere((g) => g.assignmentId == assignment.id);
                return _buildAssignmentGradeCard(context, assignment, grade);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentGradeCard(
      BuildContext context, Assignment assignment, StudentGrade grade) {
    final isOverdue = assignment.dueDate.isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    String scoreText;

    switch (grade.status) {
      case GradeStatus.graded:
        final percentage = (grade.points! / assignment.maxPoints) * 100;
        statusColor = AppTheme.getGradeColor(_getLetterGrade(percentage));
        statusText = _getLetterGrade(percentage);
        scoreText =
            '${grade.points!.toInt()}/${assignment.maxPoints} (${percentage.toStringAsFixed(1)}%)';
        break;
      case GradeStatus.missing:
        statusColor = Theme.of(context).colorScheme.error;
        statusText = 'Missing';
        scoreText = '0/${assignment.maxPoints} (0%)';
        break;
      case GradeStatus.late:
        statusColor = AppTheme.warningColor;
        statusText = 'Late';
        scoreText = grade.points != null
            ? '${grade.points!.toInt()}/${assignment.maxPoints}'
            : 'Not graded';
        break;
      case GradeStatus.notSubmitted:
        statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
        statusText = 'Not Submitted';
        scoreText = '-';
        break;
    }

    return AppCard(
      onTap: () => _showGradeEntryDialog(context, assignment, grade),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge.assignmentType(type: assignment.type.name),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${assignment.dueDate.month}/${assignment.dueDate.day}/${assignment.dueDate.year}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isOverdue
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: statusText,
                    type: StatusType.custom,
                    customColor: statusColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar for graded assignments
          if (grade.status == GradeStatus.graded) ...[
            LinearProgressIndicator(
              value: grade.points! / assignment.maxPoints,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
          ],

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to edit grade',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGradeEntryDialog(
      BuildContext context, Assignment assignment, StudentGrade grade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GradeEntrySheet(
          student: student,
          assignment: assignment,
          grade: grade,
          onSave: (newPoints, newStatus) {
            onGradeUpdate(assignment.id, newPoints, newStatus);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  double _calculateStudentOverallGrade() {
    double totalPoints = 0;
    double maxPoints = 0;

    for (final grade in student.grades) {
      final assignment =
          assignments.firstWhere((a) => a.id == grade.assignmentId);
      if (grade.status == GradeStatus.graded && grade.points != null) {
        totalPoints += grade.points!;
        maxPoints += assignment.maxPoints;
      }
    }

    return maxPoints > 0 ? (totalPoints / maxPoints) * 100 : 0.0;
  }

  String _getLetterGrade(double percentage) {
    if (percentage >= 97) return 'A+';
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 65) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }
}

// Grade Entry Bottom Sheet
class GradeEntrySheet extends StatefulWidget {
  final GradebookStudent student;
  final Assignment assignment;
  final StudentGrade grade;
  final Function(double?, GradeStatus) onSave;

  const GradeEntrySheet({
    super.key,
    required this.student,
    required this.assignment,
    required this.grade,
    required this.onSave,
  });

  @override
  State<GradeEntrySheet> createState() => _GradeEntrySheetState();
}

class _GradeEntrySheetState extends State<GradeEntrySheet> {
  late TextEditingController _pointsController;
  late GradeStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _pointsController = TextEditingController(
      text: widget.grade.points?.toString() ?? '',
    );
    _selectedStatus = widget.grade.status;
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _pointsController.text.isNotEmpty
        ? (double.tryParse(_pointsController.text) ?? 0) /
            widget.assignment.maxPoints *
            100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grade Entry',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student and Assignment Info
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.assignment.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge.assignmentType(
                        type: widget.assignment.type.name),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${widget.assignment.dueDate.month}/${widget.assignment.dueDate.day}/${widget.assignment.dueDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Points Entry
          TextField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Points Earned',
              hintText: 'Enter points (0-${widget.assignment.maxPoints})',
              border: const OutlineInputBorder(),
              suffix: Text('/ ${widget.assignment.maxPoints}'),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Grade Preview
          if (_pointsController.text.isNotEmpty) ...[
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.grade),
                  const SizedBox(width: 8),
                  Text('Grade: ${percentage.toStringAsFixed(1)}%'),
                  const SizedBox(width: 8),
                  StatusBadge.grade(grade: _getLetterGrade(percentage)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Status Selection
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GradeStatus.values.map((status) {
              return ChoiceChip(
                label: Text(_getStatusLabel(status)),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSave() ? _saveGrade : null,
              child: const Text('Save Grade'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    if (_selectedStatus == GradeStatus.graded) {
      final points = double.tryParse(_pointsController.text);
      return points != null &&
          points >= 0 &&
          points <= widget.assignment.maxPoints;
    }
    return true;
  }

  void _saveGrade() {
    final points = _selectedStatus == GradeStatus.graded
        ? double.tryParse(_pointsController.text)
        : null;

    widget.onSave(points, _selectedStatus);
  }

  String _getStatusLabel(GradeStatus status) {
    switch (status) {
      case GradeStatus.graded:
        return 'Graded';
      case GradeStatus.missing:
        return 'Missing';
      case GradeStatus.late:
        return 'Late';
      case GradeStatus.notSubmitted:
        return 'Not Submitted';
    }
  }

  String _getLetterGrade(double percentage) {
    if (percentage >= 97) return 'A+';
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 65) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }
}

// Data Models
class Assignment {
  final String id;
  final String name;
  final AssignmentType type;
  final DateTime dueDate;
  final int maxPoints;
  final double weight;

  Assignment({
    required this.id,
    required this.name,
    required this.type,
    required this.dueDate,
    required this.maxPoints,
    required this.weight,
  });
}

enum AssignmentType {
  homework,
  quiz,
  test,
  project,
}

class StudentGrade {
  final String studentId;
  final String assignmentId;
  double? points;
  GradeStatus status;

  StudentGrade(this.studentId, this.assignmentId, this.points, this.status);
}

enum GradeStatus {
  graded,
  missing,
  late,
  notSubmitted,
}

class GradebookStudent {
  final String id;
  final String name;
  final String email;
  final List<StudentGrade> grades;

  GradebookStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.grades,
  });
}
