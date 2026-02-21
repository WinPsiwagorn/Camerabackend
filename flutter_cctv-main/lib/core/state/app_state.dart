import 'package:flutter/material.dart';

/// Application-level state managed via Provider (ChangeNotifier).
///
/// Usage:
///   context.read<AppState>().cameraSearchText = 'query';
///   context.watch<AppState>().licenseList;
class AppState extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────
  static AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  static void reset() {
    _instance = AppState._internal();
  }

  Future<void> initializePersistedState() async {
    // TODO: Load any persisted state from SharedPreferences here.
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  // ── Search state ───────────────────────────────────────────
  bool _searchText = false;
  bool get searchText => _searchText;
  set searchText(bool value) {
    _searchText = value;
  }

  String _cameraSearchText = '';
  String get cameraSearchText => _cameraSearchText;
  set cameraSearchText(String value) {
    _cameraSearchText = value;
  }

  // ── License-plate list ─────────────────────────────────────
  List<dynamic> _licenseList = [];
  List<dynamic> get licenseList => _licenseList;
  set licenseList(List<dynamic> value) {
    _licenseList = value;
  }

  void addToLicenseList(dynamic value) {
    licenseList.add(value);
  }

  void removeFromLicenseList(dynamic value) {
    licenseList.remove(value);
  }

  void removeAtIndexFromLicenseList(int index) {
    licenseList.removeAt(index);
  }

  void updateLicenseListAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    licenseList[index] = updateFn(_licenseList[index]);
  }

  void insertAtIndexInLicenseList(int index, dynamic value) {
    licenseList.insert(index, value);
  }

  // ── Auth token ─────────────────────────────────────────────
  String _authToken = '';
  String get authToken => _authToken;
  set authToken(String value) {
    _authToken = value;
  }

  bool get isLoggedIn => _authToken.isNotEmpty;

  void clearAuth() {
    _authToken = '';
    notifyListeners();
  }
}
