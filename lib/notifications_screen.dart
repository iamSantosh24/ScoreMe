import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/NotificationsViewModel.dart';

class NotificationsScreen extends StatelessWidget {
  final String role;
  final String userId;
  const NotificationsScreen({super.key, required this.role, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel()..fetchRequests(role, userId),
      child: Consumer<NotificationsViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (vm.error.isNotEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: Center(child: Text(vm.error, style: const TextStyle(color: Colors.red))),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: vm.requests.isEmpty
              ? const Center(child: Text('No permission requests'))
              : ListView.builder(
                  itemCount: vm.requests.length,
                  itemBuilder: (context, index) {
                    final req = vm.requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text('${req.requesterName} requested ${req.requestType} for ${req.targetName}'),
                        subtitle: Text('Status: ${req.status}'),
                        trailing: req.status == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => vm.updateRequestStatus(req.id, 'approved'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => vm.updateRequestStatus(req.id, 'rejected'),
                                ),
                              ],
                            )
                          : null,
                      ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}
