import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'guest_book_message.dart';
import 'firebase_options.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;
  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;
  int _attendees = 0;
  int get attendees => _attendees;

  StreamSubscription<DocumentSnapshot>? _attendingSubscription;
  int? _myGuestCount;
  int? get myGuestCount => _myGuestCount;

  Future<void> setGuestCount(int count) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }
    return FirebaseFirestore.instance
        .collection('attendees')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set(<String, dynamic>{'count': count});
  }

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

    FirebaseFirestore.instance.collection('attendees').snapshots().listen((
      snapshot,
    ) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['count'] as num?)?.toInt() ?? 0;
      }
      _attendees = total;
      notifyListeners();
    });

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('guestbook')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
              _guestBookMessages = [];
              for (final document in snapshot.docs) {
                _guestBookMessages.add(
                  GuestBookMessage(
                    name: document.data()['name'] as String,
                    message: document.data()['text'] as String,
                  ),
                );
              }
              notifyListeners();
            });
        _attendingSubscription = FirebaseFirestore.instance
            .collection('attendees')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
              _myGuestCount = (snapshot.data()?['count'] as num?)?.toInt();
              notifyListeners();
            });
      } else {
        _loggedIn = false;
        _guestBookMessages = [];
        _myGuestCount = null;
        _guestBookSubscription?.cancel();
        _attendingSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  Future<DocumentReference> addMessageToGuestBook(String message) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }

    return FirebaseFirestore.instance.collection('guestbook').add(
      <String, dynamic>{
        'text': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'name': FirebaseAuth.instance.currentUser!.displayName,
        'userId': FirebaseAuth.instance.currentUser!.uid,
      },
    );
  }
}
