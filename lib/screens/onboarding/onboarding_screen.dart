import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

/// Three-card swipeable intro shown the first time a user signs in.
/// Sets `hasSeenOnboarding: true` on the user doc when finished or skipped
/// so it never appears again. Always skippable.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _auth = AuthService();
  int _index = 0;
  bool _finishing = false;

  List<_OnboardingPage> _pagesFor(AppLocalizations l) => [
        _OnboardingPage(
          icon: Icons.celebration_outlined,
          title: l.onboardingWelcomeTitle,
          body: l.onboardingWelcomeBody,
        ),
        _OnboardingPage(
          icon: Icons.meeting_room_outlined,
          title: l.onboardingRoomsTitle,
          body: l.onboardingRoomsBody,
        ),
        _OnboardingPage(
          icon: Icons.timer_outlined,
          title: l.onboardingExpireTitle,
          body: l.onboardingExpireBody,
        ),
        _OnboardingPage(
          icon: Icons.widgets_outlined,
          title: l.onboardingWidgetTitle,
          body: l.onboardingWidgetBody,
        ),
        _OnboardingPage(
          icon: Icons.place_outlined,
          title: l.onboardingLocationLockTitle,
          body: l.onboardingLocationLockBody,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final uid = _auth.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'hasSeenOnboarding': true});
    } catch (_) {
      // If the write fails we still proceed — the gate will retry next time.
    }
    // The AuthGate stream will rebuild on the user-doc change and route us forward.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = _pagesFor(l);
    final isLast = _index == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishing ? null : _finish,
                child: Text(l.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardingCard(page: pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? MomentoTheme.coral
                        : MomentoTheme.deepPlum.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishing
                      ? null
                      : () {
                          if (isLast) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                  child: _finishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLast ? l.onboardingGetStarted : l.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(page.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: MomentoTheme.deepPlum,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: MomentoTheme.deepPlum.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
