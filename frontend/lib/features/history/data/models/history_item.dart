import 'package:flutter/material.dart';

enum HistoryActionType { create, update, delete, status, session, unknown }

class HistoryItem {
  final String id;
  final String title;
  final String description;
  final String user;
  final DateTime timestamp;
  final String module;
  final HistoryActionType actionType;
  final IconData icon;
  final Color color;
  final String? originalId;
  final String? reference;

  HistoryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.user,
    required this.timestamp,
    required this.module,
    required this.actionType,
    required this.icon,
    required this.color,
    this.originalId,
    this.reference,
  });
}
