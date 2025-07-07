import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum AuthType {
  /// 日历
  /// iOS: 支持
  /// Android: 支持
  calendar,

  /// 相机
  /// iOS: 支持
  /// Android: 支持
  camera,

  /// 相册
  /// iOS: 支持
  /// Android: 支持
  photos,

  /// 通讯录
  /// iOS: 支持
  /// Android: 支持
  contacts,

  /// 定位
  /// iOS: 支持
  /// Android: 支持
  location,

  /// 麦克风
  /// iOS: 支持
  /// Android: 支持
  microphone,

  /// 电话
  /// iOS: -
  /// Android: 支持
  phone,

  /// 短信
  /// iOS: -
  /// Android: 支持
  sms,

  /// 通知
  /// iOS: 支持
  /// Android: 支持
  notification,

  /// 外部存储
  /// iOS: -
  /// Android: 支持
  storage
}

typedef AuthStateCallback = void Function(PermissionStatus status);
typedef AuthErrorCallback = void Function(PermissionStatus status);
typedef AuthCheckCallback = void Function(bool status);

class Auth {
  static Future<PermissionStatus> request({
    required AuthType type,
    AuthStateCallback? callback,
    AuthErrorCallback? errorCallback,
  }) async {
    PermissionStatus status;
    switch (type) {
      case AuthType.calendar:
        status = await Permission.calendar.request();
        break;
      case AuthType.camera:
        status = await Permission.camera.request();
        break;
      case AuthType.photos:
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if ((androidInfo.version.sdkInt) <= 32) {
            status = await Permission.storage.request();
          }  else {
            status = await Permission.photos.request();
          }
        } else {
          status = await Permission.photos.request();
        }
        break;
      case AuthType.contacts:
        status = await Permission.contacts.request();
        break;
      case AuthType.location:
        status = await Permission.location.request();
        break;
      case AuthType.microphone:
        status = await Permission.microphone.request();
        break;
      case AuthType.phone:
        status = await Permission.phone.request();
        break;
      case AuthType.sms:
        status = await Permission.sms.request();
        break;
      case AuthType.notification:
        status = await Permission.notification.request();
        break;
      case AuthType.storage:
        status = await Permission.storage.request();
        break;
    }
    if (status.isGranted || status.isLimited) {
      if (callback != null) callback(status);
    } else {
      if (errorCallback != null) errorCallback(status);
    }
    return status;
  }

  static Future<bool> check({
    required AuthType type,
    AuthCheckCallback? callback,
  }) async {
    PermissionStatus status;
    switch (type) {
      case AuthType.calendar:
        status = await Permission.calendar.status;
        break;
      case AuthType.camera:
        status = await Permission.camera.status;
        break;
      case AuthType.photos:
        status = await Permission.photos.status;
        break;
      case AuthType.contacts:
        status = await Permission.contacts.status;
        break;
      case AuthType.location:
        status = await Permission.location.status;
        break;
      case AuthType.microphone:
        status = await Permission.microphone.status;
        break;
      case AuthType.phone:
        status = await Permission.phone.status;
        break;
      case AuthType.sms:
        status = await Permission.sms.status;
        break;
      case AuthType.notification:
        status = await Permission.notification.status;
        break;
      case AuthType.storage:
        status = await Permission.storage.status;
        break;
    }

    final state = status.isGranted || status.isLimited;
    if (callback != null) callback(state);
    return state;
  }

  static Future use({
    required AuthType type,
    AuthStateCallback? callback,
    AuthErrorCallback? errorCallback,
  }) async {
    PermissionStatus status = await request(type: type);
    if (status.isGranted || status.isLimited) {
      if (callback != null) callback(status);
    } else {
      if (errorCallback != null) errorCallback(status);
    }
  }
}
