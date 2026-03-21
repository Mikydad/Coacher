import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase/auth_initializer.dart';
import '../../../core/firebase/firebase_initializer.dart';
import '../../../core/firebase/firestore_paths.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  static const routeName = '/firebase-test';

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  bool _loading = false;
  String _result = 'Tap the button to test Firestore write/read.';

  Future<void> _runTest() async {
    setState(() {
      _loading = true;
      _result = 'Running Firebase test...';
    });
    try {
      if (Firebase.apps.isEmpty) {
        await FirebaseInitializer.initialize();
      }
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is still not initialized after retry.');
      }
      final signedIn = await AuthInitializer.ensureSignedIn();
      if (!signedIn || FirebaseAuth.instance.currentUser == null) {
        throw Exception(
          'Firestore needs a signed-in user. Anonymous sign-in failed.\n'
          'In Firebase Console: Authentication → Sign-in method → enable Anonymous.\n'
          'Then confirm Firestore rules allow reads/writes for authenticated users '
          '(e.g. under users/{userId} when request.auth.uid == userId).',
        );
      }
      final firestore = FirebaseFirestore.instance;
      final ref = firestore.doc('${FirestorePaths.userRoot}/diagnostics/firebase_test');
      final now = DateTime.now().toIso8601String();

      await ref.set({
        'lastRunAt': now,
        'source': 'ios_simulator_button_test',
      }, SetOptions(merge: true));

      final snap = await ref.get();
      if (!snap.exists) {
        setState(() => _result = 'Write succeeded but read document not found.');
      } else {
        setState(() => _result = 'Success: Firestore write/read OK.\nData: ${snap.data()}');
      }
    } catch (e) {
      setState(() => _result = 'Firebase test failed:\n$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _loading ? null : _runTest,
              child: Text(_loading ? 'Testing...' : 'Run Firestore Test'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111317),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: Text(_result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
