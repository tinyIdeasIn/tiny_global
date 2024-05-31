import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_fingerprint/flutter_fingerprint.dart';
// import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// app信息管理类
class AppInfoManager {
  /// 设备类型
  String get mode => _mode;

  /// 版本
  String get version => _version;

  /// 版本号
  String get versionCode => _versionCode;

  /// 设备系统版本
  String get systemVersion => _systemVersion;

  /// 唯一标识(硬件指纹或随机生成，相同厂商相同机型可能存在重复)
  /// 卸载重装后基本不会变化 (还未完全验证)
  String get imei => _imei;

  /// 唯一标识(随机生成)，卸载重装后会变化
  String get appImei => _appImei;

  String _mode = "";
  String _imei = "";
  String _version = "";
  String _versionCode = "";
  String _systemVersion = "";
  String _appImei = "";

  factory AppInfoManager() => _getInstance();
  static AppInfoManager? _instance;
  static String _imeiKey = "designUUID";
  static String _appImeiKey = "appDesignUUID";

  AppInfoManager._internal();

  static AppInfoManager _getInstance() {
    _instance ??= AppInfoManager._internal();
    return _instance!;
  }

  /// imei存储的key，可由外面设置，不设置则用默认
  Future initInfo({String? imeiKey, String? appImeiKey}) async {
    if (imeiKey != null && imeiKey.isNotEmpty) _imeiKey = imeiKey;
    if (appImeiKey != null && appImeiKey.isNotEmpty) _appImeiKey = appImeiKey;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if(kIsWeb){
      WebBrowserInfo info = await deviceInfo.webBrowserInfo;
      _mode = info.browserName.name ?? "";
      _systemVersion = info.appVersion ?? "";
    } else {
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _mode = DeviceMode.transform(iosInfo.utsname.machine ?? "") ?? "";
        _systemVersion = iosInfo.systemVersion ?? "";
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _mode = androidInfo.model ?? "";
        _systemVersion = androidInfo.version.release ?? "";
      }
    }
    _versionCode = packageInfo.buildNumber;
    _version = packageInfo.version;
    await setFingerImei();
    await setAppImei();
  }

  /// 设置finger类型Imei (原旧的存储的imei不受影响)
  Future<void> setFingerImei() async {
    _imei = await _getKeychainImei(_imeiKey);
    if (_imei.length <= 10) {
      // _imei = await FlutterFingerprint.getDeviceId() ?? imeiNewBuilder();
      // if (_imei.length <= 10) _imei = imeiNewBuilder();
      _imei = imeiNewBuilder();
      const FlutterSecureStorage().write(key: _imeiKey, value: imei);
      // FlutterKeychain.put(key: _imeiKey, value: imei);
    }
  }

  /// 设置app类型Imei
  Future<void> setAppImei() async {
    _appImei = await _getKeychainImei(_appImeiKey);
    if (_appImei.length <= 10) {
      _appImei = imeiNewBuilder();
      const FlutterSecureStorage().write(key: _imeiKey, value: imei);

      // FlutterKeychain.put(key: _appImeiKey, value: _appImei);
    }
  }

  /// 获取存在keychain中的imei
  Future<String> _getKeychainImei(String key) async {
    try {
      var content = await const FlutterSecureStorage().read(key: _imeiKey);
      if (content != null && content.isNotEmpty) {
        content = content.replaceAll("\n", "");
        return content.toLowerCase();
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  /// 随机生成imei (32位)
  String imeiNewBuilder() {
    List<String> sbList = [];
    sbList.add(_builderRandom(8));
    sbList.add(_builderRandom(4));
    sbList.add(_builderRandom(4));
    sbList.add(_builderRandom(4));
    sbList.add(_builderTimeStamp());
    return sbList.join("-");
  }

  String _builderRandom(int length) {
    const _chars = "a01b47c25d83e69f";
    _chars.codeUnitAt(Random().nextInt(_chars.length));
    var randImei = String.fromCharCodes(
      Iterable.generate(length, (_) {
        return _chars.codeUnitAt(Random().nextInt(_chars.length));
      }),
    );
    if (randImei.length == length) {
      return randImei;
    } else {
      return _chars.substring(0, length);
    }
  }

  /// 生成时间戳16进制+t 共12位
  String _builderTimeStamp() {
    final nowTime = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    if (nowTime.length == 11) {
      return "${nowTime}t";
    } else if (nowTime.length > 11) {
      return "${nowTime.substring(0, 11)}t";
    } else {
      return "$nowTime${_builderRandom(11 - nowTime.length)}t";
    }
  }
}

class DeviceMode {
  static String? transform(String mode) {
    if (Platform.isIOS) {
      switch (mode) {
        case "iPhone4,1":
          return "iPhone 4S";
        case "iPhone5,1":
          return "iPhone 5";
        case "iPhone5,2":
          return "iPhone 5";
        case "iPhone5,3":
          return "iPhone 5c";
        case "iPhone5,4":
          return "iPhone 5c";
        case "iPhone6,1":
          return "iPhone 5s";
        case "iPhone6,2":
          return "iPhone 5s";
        case "iPhone7,1":
          return "iPhone 6 Plus";
        case "iPhone7,2":
          return "iPhone 6";
        case "iPhone8,1":
          return "iPhone 6s";
        case "iPhone8,2":
          return "iPhone 6s Plus";
        case "iPhone8,4":
          return "iPhone SE";
        case "iPhone9,1":
          return "iPhone 7";
        case "iPhone9,2":
          return "iPhone 7 Plus";
        case "iPhone9,3":
          return "iPhone 7";
        case "iPhone9,4":
          return "iPhone 7 Plus";
        case "iPhone10,1":
          return "iPhone 8";
        case "iPhone10,4":
          return "iPhone 8";
        case "iPhone10,2":
          return "iPhone 8 Plus";
        case "iPhone10,5":
          return "iPhone 8 Plus";
        case "iPhone10,3":
          return "iPhone X";
        case "iPhone10,6":
          return "iiPhone X";
        case "iPhone11,8":
          return "iPhone XR";
        case "iPhone11,2":
          return "iPhone XS";
        case "iPhone11,6":
          return "iPhone XS Max";
        case "iPhone11,4":
          return "iPhone XS Max";
        case "iPhone12,1":
          return "iPhone 11";
        case "iPhone12,3":
          return "iPhone 11 Pro";
        case "iPhone12,5":
          return "iPhone 11 Pro Max";
        case "iPhone12,8":
          return "iPhone SE";
        case "iPhone13,1":
          return "iPhone 12 mini";
        case "iPhone13,2":
          return "iPhone 12";
        case "iPhone13,3":
          return "iPhone 12 Pro";
        case "iPhone13,4":
          return "iPhone 12 Pro Max";
        case "iPhone14,4":
          return "iPhone 13 mini";
        case "iPhone14,5":
          return "iPhone 13";
        case "iPhone14,2":
          return "iPhone 13 Pro";
        case "iPhone14,3":
          return "iPhone 13 Pro Max";
        default:
          return mode;
      }
    } else {
      return mode;
    }
  }
}
