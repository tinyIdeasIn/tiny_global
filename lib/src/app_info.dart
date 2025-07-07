import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    if (kIsWeb) {
      WebBrowserInfo info = await deviceInfo.webBrowserInfo;
      _mode = info.browserName.name;
      _systemVersion = info.appVersion ?? "";
    } else {
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _mode = DeviceMode.transform(iosInfo.utsname.machine);
        _systemVersion = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _mode = androidInfo.model;
        _systemVersion = androidInfo.version.release;
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
      _imei = imeiNewBuilder();
      const FlutterSecureStorage().write(key: _imeiKey, value: imei);
    }
  }

  /// 设置app类型Imei
  Future<void> setAppImei() async {
    _appImei = await _getKeychainImei(_appImeiKey);
    if (_appImei.length <= 10) {
      _appImei = imeiNewBuilder();
      const FlutterSecureStorage().write(key: _imeiKey, value: imei);
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
  static String transform(String model) {
    if (!Platform.isIOS) return model;

    const Map<String, String> iosMap = {
      /* 旧机型（节选） */
      "iPhone4,1": "iPhone 4S",
      "iPhone5,1": "iPhone 5",
      "iPhone5,2": "iPhone 5",
      "iPhone5,3": "iPhone 5c",
      "iPhone5,4": "iPhone 5c",
      "iPhone6,1": "iPhone 5s",
      "iPhone6,2": "iPhone 5s",
      "iPhone7,1": "iPhone 6 Plus",
      "iPhone7,2": "iPhone 6",
      "iPhone8,1": "iPhone 6s",
      "iPhone8,2": "iPhone 6s Plus",
      "iPhone8,4": "iPhone SE",
      "iPhone9,1": "iPhone 7",
      "iPhone9,2": "iPhone 7 Plus",
      "iPhone9,3": "iPhone 7",
      "iPhone9,4": "iPhone 7 Plus",
      "iPhone10,1": "iPhone 8",
      "iPhone10,2": "iPhone 8 Plus",
      "iPhone10,3": "iPhone X",
      "iPhone10,4": "iPhone 8",
      "iPhone10,5": "iPhone 8 Plus",
      "iPhone10,6": "iPhone X",
      "iPhone11,2": "iPhone XS",
      "iPhone11,4": "iPhone XS Max",
      "iPhone11,6": "iPhone XS Max",
      "iPhone11,8": "iPhone XR",
      "iPhone12,1": "iPhone 11",
      "iPhone12,3": "iPhone 11 Pro",
      "iPhone12,5": "iPhone 11 Pro Max",
      "iPhone12,8": "iPhone SE (2nd Gen)",
      "iPhone13,1": "iPhone 12 mini",
      "iPhone13,2": "iPhone 12",
      "iPhone13,3": "iPhone 12 Pro",
      "iPhone13,4": "iPhone 12 Pro Max",
      "iPhone14,2": "iPhone 13 Pro",
      "iPhone14,3": "iPhone 13 Pro Max",
      "iPhone14,4": "iPhone 13 mini",
      "iPhone14,5": "iPhone 13",
      "iPhone14,6": "iPhone SE (3rd Gen)",
      "iPhone14,7": "iPhone 14",
      "iPhone14,8": "iPhone 14 Plus",
      "iPhone15,2": "iPhone 14 Pro",
      "iPhone15,3": "iPhone 14 Pro Max",
      "iPhone15,4": "iPhone 15",
      "iPhone15,5": "iPhone 15 Plus",
      "iPhone16,1": "iPhone 15 Pro",
      "iPhone16,2": "iPhone 15 Pro Max",
      "iPhone17,3": "iPhone 16",
      "iPhone17,4": "iPhone 16 Plus",
      "iPhone17,1": "iPhone 16 Pro",
      "iPhone17,2": "iPhone 16 Pro Max",
    };

    return iosMap[model] ?? model;
  }
}
