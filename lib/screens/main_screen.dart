import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'students/students_screen.dart';
import 'lessons/lessons_screen.dart';
import 'chat/chat_list_screen.dart';
import 'reports/reports_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StudentsScreen(),
    const LessonsScreen(),
    const ReportsScreen(),
    const ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          image: DecorationImage(
            image: const NetworkImage(
              'https://www.transparenttextures.com/patterns/cubes.png',
            ),
            opacity: 0.03,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  scheme.primary,
                                  scheme.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              FontAwesomeIcons.graduationCap,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EduAssess',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Teacher Studio',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        extended: true,
                        backgroundColor: Colors.transparent,
                        unselectedIconTheme: IconThemeData(
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                          size: 20,
                        ),
                        selectedIconTheme: IconThemeData(
                          color: scheme.primary,
                          size: 22,
                        ),
                        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.chartLine),
                            label: Text('Overview'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.users),
                            label: Text('Students'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.book),
                            label: Text('Assessments'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.chartBar),
                            label: Text('Reports'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.commentDots),
                            label: Text('Messages'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                appBar: !isDesktop
                    ? AppBar(
                        title: Text(
                          'EduAssess',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        centerTitle: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : null,
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _screens[_selectedIndex],
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.01, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                ),
                bottomNavigationBar: !isDesktop
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          border: Border(
                            top: BorderSide(color: scheme.outlineVariant),
                          ),
                        ),
                        child: NavigationBar(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _selectedIndex = index),
                          height: 80,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          indicatorColor: scheme.primary.withValues(alpha: 0.1),
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          destinations: [
                            NavigationDestination(
                              icon: Icon(FontAwesomeIcons.chartLine, size: 20),
                              label: 'Overview',
                            ),
                            NavigationDestination(
                              icon: Icon(FontAwesomeIcons.users, size: 20),
                              label: 'Students',
                            ),
                            NavigationDestination(
                              icon: Icon(FontAwesomeIcons.book, size: 20),
                              label: 'Exams',
                            ),
                            NavigationDestination(
                              icon: Icon(FontAwesomeIcons.chartBar, size: 20),
                              label: 'Reports',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.commentDots,
                                size: 20,
                              ),
                              label: 'Chat',
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
