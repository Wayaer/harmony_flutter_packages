import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/foundation.dart';

export 'package:device_info_plus/device_info_plus.dart';
export 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';

/// 当前运行环境是否为鸿蒙（OpenHarmony / HarmonyOS）。
bool get isOhos => !kIsWeb && defaultTargetPlatform.name == 'ohos';

class DeviceInfoPlusOhosPlugin extends DeviceInfoPlugin {
  DeviceInfoPlusOhosPlugin();

  static DeviceInfoPlatform get _platform => DeviceInfoPlatform.instance;

  OhosDeviceInfo? _cachedOhosDeviceInfo;

  Future<OhosDeviceInfo> get ohosInfo async =>
      _cachedOhosDeviceInfo ??= OhosDeviceInfo.fromMap((await _platform.deviceInfo()).data);

  @override
  Future<BaseDeviceInfo> get deviceInfo async {
    if (isOhos) {
      return ohosInfo;
    }
    return super.deviceInfo;
  }
}

class OhosDeviceInfo extends BaseDeviceInfo {
  OhosDeviceInfo({
    required Map<String, dynamic> data,
    required this.deviceType,
    required this.manufacture,
    required this.brand,
    required this.marketName,
    required this.productSeries,
    required this.productModel,
    required this.softwareModel,
    required this.hardwareModel,
    required this.hardwareProfile,
    required this.bootloaderVersion,
    required this.abiList,
    required this.securityPatchTag,
    required this.displayVersion,
    required this.incrementalVersion,
    required this.osReleaseType,
    required this.osFullName,
    required this.majorVersion,
    required this.seniorVersion,
    required this.featureVersion,
    required this.buildVersion,
    required this.sdkApiVersion,
    required this.firstApiVersion,
    required this.versionId,
    required this.buildType,
    required this.buildUser,
    required this.buildHost,
    required this.buildTime,
    required this.buildRootHash,
    required this.distributionOSName,
    required this.distributionOSVersion,
    required this.distributionOSApiVersion,
    required this.distributionOSReleaseType,
    required this.odId,
    required this.isPhysicalDevice,
    required this.serial,
    required this.udid,
  }) : super(data);

  final String deviceType;

  final String manufacture;

  final String brand;

  final String marketName;

  final String productSeries;

  final String productModel;

  final String softwareModel;

  final String hardwareModel;

  /// 自 API 9 起已废弃。
  final String hardwareProfile;

  final String bootloaderVersion;

  final String abiList;

  final String securityPatchTag;

  final String displayVersion;

  final String incrementalVersion;

  /// 系统发布类型：Canary/Beta 为预览与公测版，不承诺 API 稳定性；Release 为正式版，保证稳定性。
  final String osReleaseType;

  final String osFullName;

  final int majorVersion;

  final int seniorVersion;

  final int featureVersion;

  final int buildVersion;

  final int sdkApiVersion;

  final int firstApiVersion;

  final String versionId;

  final String buildType;

  final String buildUser;

  final String buildHost;

  final String buildTime;

  final String buildRootHash;

  final String odId;

  final String distributionOSName;

  final String distributionOSVersion;

  final int distributionOSApiVersion;

  final String distributionOSReleaseType;

  final bool isPhysicalDevice;

  /// 需要权限 ohos.permission.sec.ACCESS_UDID（系统权限，仅对系统应用开放）。
  final String serial;

  /// 需要权限 ohos.permission.sec.ACCESS_UDID（系统权限，仅对系统应用开放）。
  final String udid;

  static OhosDeviceInfo fromMap(Map<String, dynamic> map) {
    return OhosDeviceInfo(
      data: map,
      deviceType: map['deviceType'] ?? '',
      manufacture: map['manufacture'] ?? '',
      brand: map['brand'] ?? '',
      marketName: map['marketName'] ?? '',
      productSeries: map['productSeries'] ?? '',
      productModel: map['productModel'] ?? '',
      softwareModel: map['softwareModel'] ?? '',
      hardwareModel: map['hardwareModel'] ?? '',
      hardwareProfile: map['hardwareProfile'] ?? '',
      bootloaderVersion: map['bootloaderVersion'] ?? '',
      abiList: map['abiList'] ?? '',
      securityPatchTag: map['securityPatchTag'] ?? '',
      displayVersion: map['displayVersion'] ?? '',
      incrementalVersion: map['incrementalVersion'] ?? '',
      osReleaseType: map['osReleaseType'] ?? '',
      osFullName: map['osFullName'] ?? '',
      majorVersion: map['majorVersion'] ?? 0,
      seniorVersion: map['seniorVersion'] ?? 0,
      featureVersion: map['featureVersion'] ?? 0,
      buildVersion: map['buildVersion'] ?? 0,
      sdkApiVersion: map['sdkApiVersion'] ?? 0,
      firstApiVersion: map['firstApiVersion'] ?? 0,
      versionId: map['versionId'] ?? '',
      buildType: map['buildType'] ?? '',
      buildUser: map['buildUser'] ?? '',
      buildHost: map['buildHost'] ?? '',
      buildTime: map['buildTime'] ?? '',
      buildRootHash: map['buildRootHash'] ?? '',
      odId: map['odId'] ?? '',
      distributionOSName: map['distributionOSName'] ?? '',
      distributionOSVersion: map['distributionOSVersion'] ?? '',
      distributionOSApiVersion: map['distributionOSApiVersion'] ?? 0,
      distributionOSReleaseType: map['distributionOSReleaseType'] ?? '',
      isPhysicalDevice: map['isPhysicalDevice'] == true,
      serial: map['serial'] ?? '',
      udid: map['udid'] ?? '',
    );
  }

  @override
  Map<String, dynamic> get data => toMap();

  @override
  Map<String, dynamic> toMap() => {
    'deviceType': deviceType,
    'manufacture': manufacture,
    'brand': brand,
    'marketName': marketName,
    'productSeries': productSeries,
    'productModel': productModel,
    'softwareModel': softwareModel,
    'hardwareModel': hardwareModel,
    'hardwareProfile': hardwareProfile,
    'bootloaderVersion': bootloaderVersion,
    'abiList': abiList,
    'securityPatchTag': securityPatchTag,
    'displayVersion': displayVersion,
    'incrementalVersion': incrementalVersion,
    'osReleaseType': osReleaseType,
    'osFullName': osFullName,
    'majorVersion': majorVersion,
    'seniorVersion': seniorVersion,
    'featureVersion': featureVersion,
    'buildVersion': buildVersion,
    'sdkApiVersion': sdkApiVersion,
    'firstApiVersion': firstApiVersion,
    'versionId': versionId,
    'buildType': buildType,
    'buildUser': buildUser,
    'buildHost': buildHost,
    'buildTime': buildTime,
    'buildRootHash': buildRootHash,
    'distributionOSName': distributionOSName,
    'distributionOSVersion': distributionOSVersion,
    'distributionOSApiVersion': distributionOSApiVersion,
    'distributionOSReleaseType': distributionOSReleaseType,
    'odId': odId,
    'isPhysicalDevice': isPhysicalDevice,
    'serial': serial,
    'udid': udid,
  };
}
