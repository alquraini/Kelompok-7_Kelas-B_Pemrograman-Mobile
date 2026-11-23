import 'package:flutter/foundation.dart';

class SplitBillProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _bills = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get bills => List.unmodifiable(_bills);
  bool get isLoading => _isLoading;

  void addBill(Map<String, dynamic> bill) {
    _bills.add(bill);
    notifyListeners();
  }

  void removeBill(int index) {
    if (index >= 0 && index < _bills.length) {
      _bills.removeAt(index);
      notifyListeners();
    }
  }

  double calculateEqualSplit(double totalAmount, int peopleCount) {
    if (peopleCount <= 0) return 0;
    return totalAmount / peopleCount;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}