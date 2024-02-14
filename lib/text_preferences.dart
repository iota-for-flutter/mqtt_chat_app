import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TextPreferences {
  static const _keyTag = "TAG";
  static const _keyNodeUrl = "NODE_URL";
  static const _keyUserId = "USER_ID";
  static const _keyUserFirstname = "USER_FIRST_NAME";
  static const _keyUserLastname = "USER_LAST_NAME";

  static Future setTag(String tag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTag, tag);
  }

  static Future<String> getTag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(_keyTag) ?? '#WELCOME';
    return result;
  }

  static Future setNodeUrl(String nodeUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNodeUrl, nodeUrl);
  }

  static Future<String> getNodeUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(_keyNodeUrl) ??
        "https://api.testnet.shimmer.network"; //'https://api.testnet.shimmer.network';
    return result;
  }

  static Future setUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(_keyUserId) ?? const Uuid().v4();
    return result;
  }

  static Future setUserFirstname(String userFirstname) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserFirstname, userFirstname);
  }

  static Future<String> getUserFirstname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(_keyUserFirstname) ?? 'Alice';
    return result;
  }

  static Future setUserLastname(String userLastname) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserLastname, userLastname);
  }

  static Future<String> getUserLastname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(_keyUserLastname) ?? 'Bob';
    return result;
  }
}
