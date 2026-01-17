import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:safebrowser/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:safebrowser/features/parent/data/models/child_profile_model.dart';
import 'package:safebrowser/features/parent/presentation/notifiers/child_profile_notifier.dart';

class AddChildProfilePage extends StatefulWidget {
  const AddChildProfilePage({Key? key}) : super(key: key);

  @override
  State<AddChildProfilePage> createState() => _AddChildProfilePageState();
}

class _AddChildProfilePageState extends State<AddChildProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController(text: '1234');
  AgeGroup _selectedAgeGroup = AgeGroup.fiveToEight;
  int _phishingProtectionLevel = 1;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
      final childProfileNotifier = Provider.of<ChildProfileNotifier>(context, listen: false);

      if (authNotifier.user == null) throw Exception('User not authenticated');

      final newProfile = ChildProfile(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        ageGroup: _selectedAgeGroup,
        blockedDomains: [],
        whitelistedDomains: [],
        phishingProtectionLevel: _phishingProtectionLevel,
        pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text.trim(),
      );

      await childProfileNotifier.addChildProfile(authNotifier.user!.uid, newProfile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Child Profile'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                   const Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Child Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.face),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Age Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AgeGroup>(
                    value: _selectedAgeGroup,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: AgeGroup.values.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(_formatAgeGroup(group)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedAgeGroup = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'Child PIN (4 digits)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      hintText: '1234',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a PIN';
                      }
                      if (value.length != 4) {
                        return 'PIN must be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Phishing Protection Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _phishingProtectionLevel.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: _getProtectionLevelLabel(_phishingProtectionLevel),
                    onChanged: (value) {
                      setState(() => _phishingProtectionLevel = value.toInt());
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Standard'),
                        Text('Enhanced'),
                        Text('Strict'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Profile', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatAgeGroup(AgeGroup group) {
    switch (group) {
      case AgeGroup.fiveToEight: return '5 - 8 Years';
      case AgeGroup.nineToTwelve: return '9 - 12 Years';
      case AgeGroup.thirteenPlus: return '13+ Years';
    }
  }

  String _getProtectionLevelLabel(int level) {
    switch (level) {
      case 0: return 'Standard';
      case 1: return 'Enhanced';
      case 2: return 'Strict';
      default: return '';
    }
  }
}
