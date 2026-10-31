import 'dart:convert';

import 'package:device_info_plus_harmonyos/device_info_plus_harmonyos.dart';
import 'package:flutter/services.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';

export 'package:vibration_platform_interface/vibration_platform_interface.dart';

/// HarmonyOS implementation of [VibrationPlatform].
class VibrationHarmonyOS extends VibrationPlatform {
  /// Registers this class as the default instance of [VibrationHarmonyOS].
  static void registerWith() {
    VibrationPlatform.instance = VibrationHarmonyOS();
  }

  final _deviceInfoPlugin = DeviceInfoPlusPlugin();

  /// Method channel to communicate with native code.
  final _channel = const MethodChannel('vibration');

  @override
  Future<bool> hasVibrator() => _isPhysicalDevice();

  @override
  Future<bool> hasAmplitudeControl() => _isPhysicalDevice();

  @override
  Future<bool> hasCustomVibrationsSupport() async => true;

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
    // ohos only
    VibrateEffect? vibrateEffect,
    // ohos only
    VibrateAttribute vibrateAttribute = const VibrateAttribute(),
  }) {
    final effect =
        vibrateEffect ??
        (repeat > 0
            ? VibratePreset(count: repeat)
            : VibrateTime(duration: duration));
    return _channel.invokeMethod('vibrate', {
      'vibrateEffect': effect.toMap(),
      'vibrateAttribute': vibrateAttribute.toString(),
    });
  }

  @override
  Future<void> cancel() => _channel.invokeMethod('cancel');

  Future<bool> _isPhysicalDevice() async {
    try {
      final info = await _deviceInfoPlugin.harmonyOSInfo;
      return info.isPhysicalDevice;
    } on PlatformException {
      return false;
    }
  }
}

/// 马达振动效果。
mixin VibrateEffect {
  Map<String, dynamic> toMap();

  @override
  String toString() => jsonEncode(toMap());
}

/// 按持续时间振动。
class VibrateTime with VibrateEffect {
  /// 马达持续振动时长，单位 ms。
  final int duration;

  const VibrateTime({required this.duration});

  @override
  Map<String, dynamic> toMap() => {'type': 'time', 'duration': duration};
}

/// 按预置效果振动。
class VibratePreset with VibrateEffect {
  /// 预置的振动效果 ID。
  final String effectId;

  /// 重复振动的次数。
  final int count;

  const VibratePreset({
    this.effectId = 'haptic.clock.timer',
    required this.count,
  });

  @override
  Map<String, dynamic> toMap() => {
    'type': 'preset',
    'effectId': effectId,
    'count': count,
  };
}

/// 从振动配置文件振动。
class VibrateFromFile with VibrateEffect {
  final HapticFileDescriptor hapticFd;

  const VibrateFromFile({required this.hapticFd});

  @override
  Map<String, dynamic> toMap() => {
    'type': 'file',
    'hapticFd': hapticFd.toMap(),
  };
}

/// 自定义振动配置文件的描述符，仅部分设备支持。
class HapticFileDescriptor {
  final int? offset;
  final int? length;
  final Uint8List data;

  const HapticFileDescriptor({this.offset, this.length, required this.data});

  Map<String, dynamic> toMap() => {
    if (offset != null) 'offset': offset,
    if (length != null) 'length': length,
    'data': data,
  };
}

/// 马达振动属性。
class VibrateAttribute {
  final int? id;

  /// 'unknown' | 'alarm' | 'ring' | 'notification' | 'communication' |
  /// 'touch' | 'media' | 'physicalFeedback' | 'simulateReality'
  final String usage;

  const VibrateAttribute({this.id, this.usage = 'unknown'});

  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'usage': usage};

  @override
  String toString() => jsonEncode(toMap());
}
