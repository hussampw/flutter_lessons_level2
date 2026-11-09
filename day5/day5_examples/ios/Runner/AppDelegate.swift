// ============================================================
// الدرس 4 (Native): الجهة الأخرى من Platform Channel — Swift على iOS
// (والدرس 7: فحص الـ Jailbreak يستخدم نفس القناة)
// في Dart: lib/lessons/04_platform_channels.dart
// ============================================================
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    // 1) MethodChannel يدوي — نفس الاسم تماماً في Dart: MethodChannel('workshop/device')
    let channel = FlutterMethodChannel(name: "workshop/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getBatteryLevel":
        let level = AppDelegate.batteryLevel()
        if level < 0 {
          // على المحاكي (Simulator) البطارية غير متاحة
          result(FlutterError(code: "UNAVAILABLE", message: "مستوى البطارية غير متاح", details: nil))
        } else {
          result(level)
        }
      case "isDeviceCompromised":
        // الدرس 7: فحص الـ Jailbreak — نعيد Dictionary تصل إلى Dart كـ Map
        result(AppDelegate.jailbreakCheck())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // 2) Pigeon: نفس الفكرة لكن بواجهة مولَّدة وآمنة الأنواع (DeviceApi.g.swift)
    DeviceHostApiSetup.setUp(binaryMessenger: messenger, api: DeviceApiImpl())
  }

  // قراءة البطارية (0–100) أو -1 إذا لم تكن متاحة
  static func batteryLevel() -> Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel // -1.0 على المحاكي
    return level < 0 ? -1 : Int(level * 100)
  }

  // ------------------------------------------------------------
  // فحص الـ Jailbreak: علامات شائعة (ليست مضمونة 100%)
  // للإنتاج: مكتبة متخصصة مثل freeRASP أو App Attest من Apple
  // ------------------------------------------------------------
  static func jailbreakCheck() -> [String: Any] {
    #if targetEnvironment(simulator)
      return ["compromised": false, "reasons": ["simulator"]]
    #else
      var reasons: [String] = []
      let paths = [
        "/Applications/Cydia.app", "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash", "/usr/sbin/sshd", "/etc/apt",
      ]
      for path in paths where FileManager.default.fileExists(atPath: path) {
        reasons.append(path)
      }
      // التطبيق العادي لا يستطيع الكتابة خارج الـ sandbox الخاص به
      let testPath = "/private/jailbreak_test.txt"
      if (try? "x".write(toFile: testPath, atomically: true, encoding: .utf8)) != nil {
        try? FileManager.default.removeItem(atPath: testPath)
        reasons.append("write outside sandbox")
      }
      return ["compromised": !reasons.isEmpty, "reasons": reasons]
    #endif
  }
}

// تنفيذ واجهة Pigeon: المترجم يجبرنا على كتابة كل الدوال بالأنواع الصحيحة
private class DeviceApiImpl: DeviceHostApi {
  func getDeviceInfo() throws -> DeviceInfo {
    let device = UIDevice.current
    return DeviceInfo(
      model: device.model,
      osVersion: "\(device.systemName) \(device.systemVersion)",
      batteryLevel: Int64(AppDelegate.batteryLevel())  // int في Dart = Int64 هنا
    )
  }

  // @async في تعريف Pigeon ← async هنا
  func greet(name: String) async throws -> String {
    return "أهلاً \(name) من Swift 👋"
  }
}
