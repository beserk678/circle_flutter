import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.groups_rounded,
      title: 'Welcome to Circle',
      description:
          'Create or join circles to collaborate with your team, friends, or community.',
      gradient: DesignTokens.primaryGradient,
    ),
    OnboardingPage(
      icon: Icons.chat_bubble_rounded,
      title: 'Stay Connected',
      description:
          'Chat in real-time, share updates in the feed, and never miss important conversations.',
      gradient: const LinearGradient(
        colors: [DesignTokens.secondaryColor, Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      icon: Icons.task_alt_rounded,
      title: 'Manage Tasks',
      description:
          'Create, assign, and track tasks to keep your circle organized and productive.',
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      icon: Icons.folder_rounded,
      title: 'Share Files',
      description:
          'Upload and share documents, images, and files with your circle members.',
      gradient: const LinearGradient(
        colors: [Color(0xFF06B6D4), DesignTokens.primaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index == _currentPage),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _pages[_currentPage].gradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radius16),
                    boxShadow: DesignTokens.buttonShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radius16,
                        ),
                      ),
                    ),
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(DesignTokens.radius32),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(page.icon, size: 70, color: Colors.white),
          ),
          const SizedBox(height: DesignTokens.spacing48),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacing16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 18,
              color: DesignTokens.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        gradient: isActive ? _pages[_currentPage].gradient : null,
        color: isActive ? null : DesignTokens.textTertiary(context),
        borderRadius: BorderRadius.circular(DesignTokens.spacing4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
