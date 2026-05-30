import 'package:flutter/material.dart';

class HotelProvider extends ChangeNotifier {
  String? _hotelId;

  String? get hotelId => _hotelId;

  bool get hasHotel => _hotelId != null;

  void setHotel(String hotelId) {
    _hotelId = hotelId;
    notifyListeners();
  }

  void clearHotel() {
    _hotelId = null;
    notifyListeners();
  }
}
