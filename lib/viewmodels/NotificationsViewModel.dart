import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PermissionRequest {
  final String id;
  final String requesterName;
  final String requestType;
  final String targetName;
  final String status;

  PermissionRequest({
    required this.id,
    required this.requesterName,
    required this.requestType,
    required this.targetName,
    required this.status,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['_id'] ?? '',
      requesterName: json['requesterName'] ?? '',
      requestType: json['requestType'] ?? '',
      targetName: json['targetName'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class NotificationsViewModel extends ChangeNotifier {
  List<PermissionRequest> requests = [];
  bool loading = false;
  String error = '';

  Future<void> fetchRequests(String role, String userId) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/api/permission-requests'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        requests = data.map((e) => PermissionRequest(
          id: e['_id'] ?? '',
          requesterName: e['requesterId'] ?? '', // Map requesterId to requesterName
          requestType: e['requestType'] ?? '',
          targetName: e['targetName'] ?? '',
          status: e['status'] ?? 'pending',
        )).toList();
      } else {
        error = 'Failed to fetch requests';
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> updateRequestStatus(String id, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('http://192.168.1.134:3000/permission-requests/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );
      if (response.statusCode == 200) {
        requests = requests.map((r) =>
          r.id == id ? PermissionRequest(
            id: r.id,
            requesterName: r.requesterName,
            requestType: r.requestType,
            targetName: r.targetName,
            status: newStatus,
          ) : r
        ).toList();
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> sendPermissionRequest(String requesterId, String requestType, String targetName) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.134:3000/permission-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requesterId': requesterId,
          'requestType': requestType,
          'targetName': targetName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendJoinTeamRequest(String requesterId, String teamId, String teamName) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.134:3000/permission-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requesterId': requesterId,
          'requestType': 'join_team',
          'targetId': teamId,
          'targetName': teamName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  int get unreadCount => requests.where((r) => r.status == 'pending').length;
}
