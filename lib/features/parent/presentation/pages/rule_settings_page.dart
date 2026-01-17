import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:safebrowser/features/parent/presentation/notifiers/child_profile_notifier.dart';

class RuleSettingsPage extends StatefulWidget {
  final ChildProfile childProfile;

  const RuleSettingsPage({Key? key, required this.childProfile}) : super(key: key);

  @override
  State<RuleSettingsPage> createState() => _RuleSettingsPageState();
}

class _RuleSettingsPageState extends State<RuleSettingsPage> {
  late bool _contentProtection;
  late bool _phishingProtection;
  late bool _imageSafety;
  late double _confidenceThreshold;
  late List<String> _whitelist;
  late List<String> _blacklist;
  
  final _whitelistController = TextEditingController();
  final _blacklistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contentProtection = true;
    _phishingProtection = true;
    _imageSafety = true;
    _whitelist = List.from(widget.childProfile.whitelistedDomains);
    _blacklist = List.from(widget.childProfile.blockedDomains);
    _confidenceThreshold = 85; // Default threshold
  }

  @override
  void dispose() {
    _whitelistController.dispose();
    _blacklistController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final userId = authNotifier.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated'), backgroundColor: Colors.red),
      );
      return;
    }

    final updatedProfile = widget.childProfile.copyWith(
      whitelistedDomains: _whitelist,
      blockedDomains: _blacklist,
      phishingProtectionLevel: _phishingProtection ? 2 : 1, // Simplified mapping
    );

    Provider.of<ChildProfileNotifier>(context, listen: false).updateChildProfile(
      userId,
      updatedProfile,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rules: ${widget.childProfile.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline), 
            onPressed: _saveSettings, 
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Protection Layers'),
          SwitchListTile(
            title: const Text('AI Content Protection'),
            subtitle: const Text('Block explicit text & media'),
            value: _contentProtection,
            onChanged: (val) => setState(() => _contentProtection = val),
            secondary: const Icon(Icons.text_fields),
          ),
          SwitchListTile(
            title: const Text('AI Phishing Protection'),
            subtitle: const Text('Block fake login pages & scams'),
            value: _phishingProtection,
            onChanged: (val) => setState(() => _phishingProtection = val),
            secondary: const Icon(Icons.security),
          ),
          SwitchListTile(
            title: const Text('AI Image Safety'),
            subtitle: const Text('Block inappropriate images'),
            value: _imageSafety,
            onChanged: (val) => setState(() => _imageSafety = val),
            secondary: const Icon(Icons.image),
          ),
          const Divider(height: 32),
          _buildSectionHeader('Advanced Settings'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Filtering Intensity', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Intensity: ${_confidenceThreshold.toInt()}%', style: Theme.of(context).textTheme.bodySmall),
                Slider(
                  value: _confidenceThreshold,
                  min: 60,
                  max: 95,
                  divisions: 7,
                  onChanged: (val) => setState(() => _confidenceThreshold = val),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          _buildDomainManager(
            'Whitelist Domains', 
            'Enter domain to allow (e.g. kiddle.co)', 
            _whitelistController, 
            _whitelist,
            (domain) => setState(() => _whitelist.add(domain)),
            (index) => setState(() => _whitelist.removeAt(index)),
          ),
          const SizedBox(height: 24),
          _buildDomainManager(
            'Block Domains', 
            'Enter domain to block (e.g. social.com)', 
            _blacklistController, 
            _blacklist,
            (domain) => setState(() => _blacklist.add(domain)),
            (index) => setState(() => _blacklist.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  Widget _buildDomainManager(
    String title, 
    String hint, 
    TextEditingController controller, 
    List<String> domains,
    Function(String) onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: domains.asMap().entries.map((entry) => Chip(
            label: Text(entry.value), 
            onDeleted: () => onRemove(entry.key),
            backgroundColor: Colors.blue[50],
          )).toList(),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle), 
              onPressed: () {
                if (controller.text.isNotEmpty) {
                   onAdd(controller.text.trim().toLowerCase());
                   controller.clear();
                }
              },
            )
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              onAdd(value.trim().toLowerCase());
              controller.clear();
            }
          },
        ),
      ],
    );
  }
}
