import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/favorites_provider.dart';
import 'package:ctisims/evaluate_page.dart';
import 'themes/Theme_provider.dart';

class FavoriteListPage extends StatelessWidget {
  const FavoriteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Students'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: favoritesProvider.favoriteStudents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.pink),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite students yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add students to your favorites from the search page',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoritesProvider.favoriteStudents.length,
              itemBuilder: (context, index) {
                final entry = favoritesProvider.favoriteStudents.entries.elementAt(index);
                final student = entry.value;
                final bilkentId = student['bilkentId'] ?? '';
                final name = student['name'] ?? '';
                final course = student['course'] ?? {};
                final code = course['code'] ?? '';
                final year = course['year'] ?? '';
                final semester = course['semester'] ?? '';
                final courseId = course['courseId'] ?? '';
                final companyEvaluationUploaded = student['companyEvaluationUploaded'] ?? false;
                
                return Card(
                  elevation: 2,
                  color: cardBgColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Use direct removal since we're in the favorites page
                                favoritesProvider.removeFromFavorites(bilkentId);
                                // No need for conditional message as we're always removing when in favorites list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Removed from favorites'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.favorite, color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Bilkent ID: $bilkentId', style: TextStyle(color: textColor)),
                        const SizedBox(height: 4),
                        Text('Year: $year', style: TextStyle(color: textColor)),
                        const SizedBox(height: 4),
                        Text('Semester: $semester', style: TextStyle(color: textColor)),
                        const SizedBox(height: 4),
                        Text('Course: CTIS $code', style: TextStyle(color: textColor)),
                        const SizedBox(height: 4),
                        Text(
                          'Company Evaluation: ${companyEvaluationUploaded ? "Uploaded" : "Not Uploaded"}',
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final submissionMap = {
                              'bilkentId': bilkentId,
                              'courseId': courseId,
                              'studentName': name,
                              'email': student['email'] ?? '',
                              'course': 'CTIS$code',
                              'companyEvaluation': companyEvaluationUploaded ? 'Uploaded' : 'Not Uploaded'
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EvaluatePage(
                                  submission: submissionMap.map((k, v) => MapEntry(k, v.toString())),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.blueGrey[700] : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}