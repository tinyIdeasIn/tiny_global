import 'package:url_launcher/url_launcher.dart';

class OpenManager {
  static void browser(String url) {

  }

  static Future call(String number) {
    return launch("tel:$number");
  }
}
