import 'package:ntp/ntp.dart';

class TimeHelper {
  static int _offset = 0;

  static Future<void> init() async {
    try {
      _offset = await NTP.getNtpOffset(localTime: DateTime.now());
    } catch (e) {
      _offset = 0;
    }
  }

  static DateTime get now => DateTime.now().add(Duration(milliseconds: _offset));
}
