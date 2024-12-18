import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin StatusMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  String? _enforcerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEnforcerId().then((_) => _updateStatusToOnline());
  }

  @override
  void dispose() {
    _updateStatusToOffline();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updateStatusToOffline();
    } else if (state == AppLifecycleState.resumed) {
      _updateStatusToOnline();
    }
  }

  Future<void> _loadEnforcerId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _enforcerId = prefs.getString('enforcerId');
  }

  Future<void> _updateStatusToOnline() async {
    if (_enforcerId == null || _enforcerId!.isEmpty) return;

    try {
      final QuerySnapshot enforcerQuery = await FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: _enforcerId)
          .get();

      if (enforcerQuery.docs.isNotEmpty) {
        final String docId = enforcerQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection('enforcer_account')
            .doc(docId)
            .update({
          'status': 'Online',
          'last_active': FieldValue.serverTimestamp(),
        });
        debugPrint('Status updated to Online for enforcer: $_enforcerId');
      } else {
        debugPrint('No enforcer document found for ID: $_enforcerId');
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  Future<void> _updateStatusToOffline() async {
    if (_enforcerId == null || _enforcerId!.isEmpty) return;

    try {
      final QuerySnapshot enforcerQuery = await FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: _enforcerId)
          .get();

      if (enforcerQuery.docs.isNotEmpty) {
        final String docId = enforcerQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection('enforcer_account')
            .doc(docId)
            .update({
          'status': 'Offline',
          'last_active': FieldValue.serverTimestamp(),
        });
        debugPrint('Status updated to Offline for enforcer: $_enforcerId');
      } else {
        debugPrint('No enforcer document found for ID: $_enforcerId');
      }
    } catch (e) {
      debugPrint('Error updating offline status: $e');
    }
  }
}
