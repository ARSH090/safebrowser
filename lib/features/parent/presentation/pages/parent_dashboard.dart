import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/child/presentation/pages/browser_page.dart';
import 'package:safebrowser/features/child/presentation/widgets/pin_lock_screen.dart';
import 'package:safebrowser/features/logs/presentation/pages/logs_page.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:safebrowser/features/parent/presentation/notifiers/child_profile_notifier.dart';
import 'package:safebrowser/features/parent/presentation/pages/add_child_profile_page.dart';
import 'package:safebrowser/features/parent/presentation/pages/alerts_page.dart';
import 'package:safebrowser/features/parent/presentation/pages/profile_page.dart';
import 'package:safebrowser/features/parent/presentation/pages/rule_settings_page.dart';
import 'package:safebrowser/features/parent/presentation/pages/settings_page.dart';
import 'package:safebrowser/features/parent/presentation/widgets/gamification_widgets.dart';
import 'package:safebrowser/features/logs/data/models/log_model.dart';
import 'package:safebrowser/features/logs/data/services/log_service.dart';
import 'package:timeago/timeago.dart' as timeago;

String _formatAgeGroup(AgeGroup group) {
  switch (group) {
    case AgeGroup.fiveToEight: return '5-8 Years';
    case AgeGroup.nineToTwelve: return '9-12 Years';
    case AgeGroup.thirteenPlus: return '13+ Years';
  }
}

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
        if (authNotifier.user != null) {
          Provider.of<ChildProfileNotifier>(context, listen: false)
              .fetchChildProfiles(authNotifier.user!.uid);
        }
      } catch (e) {
        debugPrint('Error initializing dashboard: $e');
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 18) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const _HomeView();
      case 1:
        return Consumer<AuthNotifier>(
          builder: (context, auth, _) {
            if (auth.user == null) return const Center(child: Text('Please login'));
            return StreamBuilder<List<LogModel>>(
              stream: logService.getLogs(auth.user!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading logs'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(child: Text('No activity logs found.'));
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: _getIconForLogType(log.type),
                        title: Text(log.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('URL: ${log.url}\n${timeago.format(log.timestamp.toDate())}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      case 2:
        return const AlertsPage();
      case 3:
        return const ProfilePage();
      default:
        return const _HomeView();
    }
  }

  Widget _getIconForLogType(LogType type) {
    switch (type) {
      case LogType.phishing:
        return const Icon(Icons.security, color: Colors.red);
      case LogType.text:
        return const Icon(Icons.text_fields, color: Colors.orange);
      case LogType.image:
        return const Icon(Icons.image, color: Colors.purple);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting(), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            activeIcon: Icon(Icons.notifications_active_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            activeIcon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddChildProfilePage()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Child'),
      ) : null,
    );
  }
}

// The main home view with the list of child profiles
class _HomeView extends StatelessWidget {
  const _HomeView({Key? key}) : super(key: key);

  void _switchToChildMode(BuildContext context, ChildProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinLockScreen(
          requiredPin: profile.pin,
          onPinVerified: (pin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BrowserPage(childProfile: profile),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final childProfileNotifier = Provider.of<ChildProfileNotifier>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: const SafetyScoreCard(score: 95, streakDays: 12),
        ),
        const BadgesWidget(),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Child Profiles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: childProfileNotifier.profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.family_restroom_rounded, size: 100, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No Child Profiles Yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add a profile to start protecting your family.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddChildProfilePage()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Your First Child'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: childProfileNotifier.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = childProfileNotifier.profiles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatAgeGroup(profile.ageGroup),
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Profile?'),
                                        content: Text('Are you sure you want to delete ${profile.name}\'s profile and all their activity data?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      childProfileNotifier.deleteChildProfile(authNotifier.user!.uid, profile.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text('Edit Rules'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RuleSettingsPage(childProfile: profile),
                                      ),
                                    );
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.shield),
                                  label: const Text('Child Mode'),
                                  onPressed: () => _switchToChildMode(context, profile),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.timeline),
                                  label: const Text('View Activity'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LogsPage(childProfile: profile),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
