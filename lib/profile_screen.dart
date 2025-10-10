import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile Id: ${vm.profileId}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Username: ${vm.username}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Contact Number: ${vm.contactNumber}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        if (!vm.showOldPasswordField && !vm.showPasswordFields)
                          ElevatedButton(
                            onPressed: vm.startPasswordChange,
                            child: const Text('Change Password'),
                          ),
                        if (vm.showOldPasswordField) ...[
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Old Password'),
                            obscureText: true,
                            onChanged: (val) => vm.oldPassword = val,
                          ),
                          ElevatedButton(
                            onPressed: vm.submitOldPassword,
                            child: const Text('Next'),
                          ),
                          if (vm.passwordError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(vm.passwordError, style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                        if (vm.showPasswordFields) ...[
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(labelText: 'New Password'),
                            obscureText: true,
                            onChanged: (val) {
                              vm.newPassword = val;
                              vm.notifyListeners();
                            },
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Confirm New Password'),
                            obscureText: true,
                            onChanged: (val) {
                              vm.confirmNewPassword = val;
                              vm.notifyListeners();
                            },
                          ),
                          ElevatedButton(
                            onPressed: vm.canUpdatePassword ? () => vm.changePassword(context) : null,
                            child: const Text('Update Password'),
                          ),
                          if (vm.passwordError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(vm.passwordError, style: const TextStyle(color: Colors.red)),
                            ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => vm.deleteAccount(context),
                          child: const Text('Delete Account'),
                        ),
                        if (vm.deleteError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(vm.deleteError, style: const TextStyle(color: Colors.red)),
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
