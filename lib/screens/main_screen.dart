import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          gradient: LinearGradient(
            colors: [
              scheme.surface,
              scheme.surface.withValues(alpha: 0.8),
              const Color(0xFFF8FAFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                    right: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.graduationCap,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ClassPulse',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Teacher Studio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
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
                        labelType: NavigationRailLabelType.none,
                        backgroundColor: Colors.white,
                        selectedIconTheme: IconThemeData(color: scheme.primary),
                        selectedLabelTextStyle: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
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
                            label: Text('Quizzes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.chartBar),
                            label: Text('Reports'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(FontAwesomeIcons.comment),
                            label: Text('Chat'),
                          ),
                        ],
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
                        title: const Text('ClassPulse Teacher'),
                        centerTitle: false,
                      )
                    : null,
                body: _screens[_selectedIndex],
                bottomNavigationBar: !isDesktop
                    ? Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: NavigationBar(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _selectedIndex = index),
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          height: 70,
                          backgroundColor: Colors.white,
                          indicatorColor: scheme.primary.withValues(alpha: 0.1),
                          destinations: [
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.chartLine,
                                size: 20,
                                color: _selectedIndex == 0
                                    ? scheme.primary
                                    : Colors.grey,
                              ),
                              label: 'Overview',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.users,
                                size: 20,
                                color: _selectedIndex == 1
                                    ? scheme.primary
                                    : Colors.grey,
                              ),
                              label: 'Students',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.book,
                                size: 20,
                                color: _selectedIndex == 2
                                    ? scheme.primary
                                    : Colors.grey,
                              ),
                              label: 'Quizzes',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.chartBar,
                                size: 20,
                                color: _selectedIndex == 3
                                    ? scheme.primary
                                    : Colors.grey,
                              ),
                              label: 'Reports',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                FontAwesomeIcons.comment,
                                size: 20,
                                color: _selectedIndex == 4
                                    ? scheme.primary
                                    : Colors.grey,
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
