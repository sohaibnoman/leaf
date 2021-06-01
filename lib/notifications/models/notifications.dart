import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Notifications{
  final int chat;
  final int follow;

  const Notifications({
    @required this.chat,
    @required this.follow,
  });

  factory Notifications.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data();
    if (data == null) {
      throw 'Error creating Notification from null value';
    }
    final int chat = data['chat'];
    final int follow = data['follow'];

    if (
        chat == null ||
        follow == null 
     ){
      throw 'Error creating Notification from null value';
    }

    return Notifications(
      chat: chat,
      follow: follow
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat':chat,
      'follow': follow,
    };
  }
}