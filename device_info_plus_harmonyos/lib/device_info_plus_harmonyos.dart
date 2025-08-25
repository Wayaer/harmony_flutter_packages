import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/foundation.dart';

export 'package:device_info_plus/device_info_plus.dart';
export 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';


/// Provides device and operating system information.
class DeviceInfoPlusPlugin extends DeviceInfoPlugin {
  /// No work is done when instantiating the plugin. It's safe to call this
  /// repeatedly or in performance-sensitive blocks.
  DeviceInfoPlusPlugin();

  /// This is to manually endorse the Linux plugin until automatic registration
  /// of dart plugins is implemented.
  /// See https://github.com/flutter/flutter/issues/52267 for more details.
  static DeviceInfoPlatform get _platform => DeviceInfoPlatform.instance;

  /// This information does not change from call to call. Cache it.
  HarmonyOSDeviceInfo? _cachedHarmonyOSDeviceInfo;

  /// Returns device information for ohos. Information sourced from Sysctl.
  Future<HarmonyOSDeviceInfo> get harmonyOSInfo async =>
      _cachedHarmonyOSDeviceInfo ??=
          HarmonyOSDeviceInfo.fromMap((await _platform.deviceInfo()).data);

  /// Returns device information for the current platform.
  @override
  Future<BaseDeviceInfo> get deviceInfo async {
    if (!kIsWeb && defaultTargetPlatform.name == 'ohos') {
      return harmonyOSInfo;
    }
    return super.deviceInfo;
  }
}

/// Object encapsulating Ohos device information.
class HarmonyOSDeviceInfo implements BaseDeviceInfo {
  /// Constructs a HarmonyOSDeviceInfo.
  HarmonyOSDeviceInfo({
    required this.deviceType,
    required this.manufacture,
    required this.brand,
    required this.marketName,
    required this.productSeries,
    required this.productModel,
    required this.softwareModel,
    required this.hardwareModel,
    required this.hardwareProfile,
    required this.serial,
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
    required this.udid,
    required this.distributionOSName,
    required this.distributionOSVersion,
    required this.distributionOSApiVersion,
    required this.distributionOSReleaseType,
    required this.odID,
  });

  final String? deviceType;
  final String? manufacture;
  final String? brand;
  final String? marketName;
  final String? productSeries;
  final String? productModel;
  final String? softwareModel;
  final String? hardwareModel;
  final String? hardwareProfile;
  final String? serial;
  final String? bootloaderVersion;
  final String? abiList;
  final String? securityPatchTag;
  final String? displayVersion;
  final String? incrementalVersion;
  final String? osReleaseType;
  final String? osFullName;
  final int? majorVersion;
  final int? seniorVersion;
  final int? featureVersion;
  final int? buildVersion;
  final int? sdkApiVersion;
  final int? firstApiVersion;
  final String? versionId;
  final String? buildType;
  final String? buildUser;
  final String? buildHost;
  final String? buildTime;
  final String? buildRootHash;
  final String? udid;
  final String? distributionOSName;
  final String? distributionOSVersion;
  final int? distributionOSApiVersion;
  final String? distributionOSReleaseType;
  final String? odID;

  /// Constructs a [HarmonyOSDeviceInfo] from a Map of dynamic.
  static HarmonyOSDeviceInfo fromMap(Map<String, dynamic> map) {
    return HarmonyOSDeviceInfo(
      deviceType: map['deviceType'],
      manufacture: map['manufacture'],
      brand: map['brand'],
      marketName: map['marketName'],
      productSeries: map['productSeries'],
      productModel: map['productModel'],
      softwareModel: map['softwareModel'],
      hardwareModel: map['hardwareModel'],
      hardwareProfile: map['hardwareProfile'],
      serial: map['serial'],
      bootloaderVersion: map['bootloaderVersion'],
      abiList: map['abiList'],
      securityPatchTag: map['securityPatchTag'],
      displayVersion: map['displayVersion'],
      incrementalVersion: map['incrementalVersion'],
      osReleaseType: map['osReleaseType'],
      osFullName: map['osFullName'],
      majorVersion: map['majorVersion'],
      seniorVersion: map['seniorVersion'],
      featureVersion: map['featureVersion'],
      buildVersion: map['buildVersion'],
      sdkApiVersion: map['sdkApiVersion'],
      firstApiVersion: map['firstApiVersion'],
      versionId: map['versionId'],
      buildType: map['buildType'],
      buildUser: map['buildUser'],
      buildHost: map['buildHost'],
      buildTime: map['buildTime'],
      buildRootHash: map['buildRootHash'],
      udid: map['udid'],
      distributionOSName: map['distributionOSName'],
      distributionOSVersion: map['distributionOSVersion'],
      distributionOSApiVersion: map['distributionOSApiVersion'],
      distributionOSReleaseType: map['distributionOSReleaseType'],
      odID: map['ODID'],
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
        'ODID': odID,
        'udid': udid,
        'serial': serial,
      };
}