/// 订阅者回调签名
typedef void NotificationCallback(arg);

/// 广播管理
class NotificationManager {
  factory NotificationManager() => _getInstance();
  static NotificationManager? _instance;

  NotificationManager._internal();

  static NotificationManager _getInstance() {
    _instance ??= NotificationManager._internal();
    return _instance!;
  }

  /// 保存事件订阅者队列，key:事件名(id)，value: 对应事件的订阅者队列
  final _notificationQueue = <dynamic, List<NotificationObject>>{};

  /// 添加订阅者
  void add({Object? name, Object? bindObj, NotificationCallback? callback}) {
    if (name == null || callback == null || bindObj == null) return;
    if (_containsObj(name, bindObj) == -1) {
      // 不存在 添加(防止重复添加)
      NotificationObject object =
          NotificationObject(object: bindObj, callback: callback);
      _notificationQueue[name.toString()] ??= [];
      _notificationQueue[name.toString()]!.add(object);
    }
  }

  /// 移除订阅者
  void remove({Object? name, Object? bindObj}) {
    if (bindObj == null || name == null) return;
    var list = _notificationQueue[name.toString()];
    if (list == null) return;
    int index = _containsObj(name, bindObj);
    if (index != -1) list.removeAt(index);
    _notificationQueue[name.toString()] = list;
  }

  /// 删除通知
  void delete(Object name) {
    if (name.toString().isEmpty) return;
    if (_notificationQueue.containsKey(name.toString())) {
      _notificationQueue.remove(name.toString());
    }
  }

  /// 触发事件，事件触发后该事件所有订阅者会被调用
  void send({Object? name, arg}) {
    var list = _notificationQueue[name.toString()];
    if (list == null) return;
    list.forEach((element) {
      element.callback?.call(arg);
    });
  }

  /// 是否已经存在通知绑定对象
  int _containsObj(Object name, Object obj) {
    var list = _notificationQueue[name.toString()];
    if (list == null) return -1;
    int index = -1;
    for (int i = 0; i < list.length; i++) {
      NotificationObject notification = list[i];
      if (identical(notification.object, obj)) {
        index = i;
        break;
      }
    }
    return index;
  }
}

class NotificationObject {
  Object? object;
  NotificationCallback? callback;

  NotificationObject({this.object, this.callback});
}
