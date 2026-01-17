import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/logs/data/models/log_model.dart';
import 'package:safebrowser/features/logs/data/services/log_service.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class LogsPage extends StatefulWidget {
  final ChildProfile childProfile;

  const LogsPage({Key? key, required this.childProfile}) : super(key: key);

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final LogService _logService = LogService();
  late Stream<List<LogModel>> _logsStream;

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthNotifier>(context, listen: false).user!.uid;
    _logsStream = _logService.getLogs(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Log for ${widget.childProfile.name}'),
      ),
      body: StreamBuilder<List<LogModel>>(
        stream: _logsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!.where((log) => log.childId == widget.childProfile.id).toList();

          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No activity recorded yet.', 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
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
                  subtitle: Text(timeago.format(log.timestamp.toDate())),
                  trailing: _getSeverityBadge(log.type),
                ),
              );
            },
          );
        },
      ),
    );
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

  Widget _getSeverityBadge(LogType type) {
    final Color color;
    final String text;
    switch (type) {
      case LogType.phishing:
        color = Colors.red;
        text = 'High';
        break;
      case LogType.text:
        color = Colors.orange;
        text = 'Medium';
        break;
      case LogType.image:
        color = Colors.purple;
        text = 'Medium';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
