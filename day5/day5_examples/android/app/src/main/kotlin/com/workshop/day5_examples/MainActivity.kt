// ============================================================
// الدرس 4 (Native): الجهة الأخرى من Platform Channel — Kotlin على Android
// (والدرس 7: فحص الروت يستخدم نفس القناة)
// في Dart: lib/lessons/04_platform_channels.dart
// ============================================================
package com.workshop.day5_examples

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    // نفس الاسم تماماً في Dart: MethodChannel('workshop/device')
    private val channelName = "workshop/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 1) MethodChannel يدوي: نفحص اسم الدالة كنص ونرد بـ result
        MethodChannel(messenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val level = batteryLevel(this)
                    if (level >= 0) {
                        result.success(level)
                    } else {
                        result.error("UNAVAILABLE", "مستوى البطارية غير متاح", null)
                    }
                }
                // الدرس 7: فحص الروت (Root) — نعيد Map تصل إلى Dart كـ Map
                "isDeviceCompromised" -> result.success(rootCheck())
                else -> result.notImplemented()
            }
        }

        // 2) Pigeon: نفس الفكرة لكن بواجهة مولَّدة وآمنة الأنواع (DeviceApi.g.kt)
        DeviceHostApi.setUp(messenger, DeviceApiImpl(this))
    }

    // ------------------------------------------------------------
    // فحص الروت: علامات شائعة (ليست مضمونة 100% — المهاجم يستطيع إخفاءها)
    // للإنتاج: مكتبة متخصصة مثل freeRASP أو Play Integrity API من Google
    // ------------------------------------------------------------
    private fun rootCheck(): Map<String, Any> {
        val reasons = mutableListOf<String>()
        if (Build.TAGS?.contains("test-keys") == true) reasons.add("test-keys build")
        val suPaths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/system/app/Superuser.apk", "/data/local/xbin/su",
        )
        suPaths.filter { File(it).exists() }.forEach { reasons.add(it) }
        return mapOf("compromised" to reasons.isNotEmpty(), "reasons" to reasons)
    }
}

// قراءة البطارية من خدمة النظام (0–100) أو -1 إذا لم تكن متاحة
fun batteryLevel(context: Context): Int {
    val manager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    val level = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    return if (level in 0..100) level else -1
}

// تنفيذ واجهة Pigeon: المترجم يجبرنا على كتابة كل الدوال بالأنواع الصحيحة
private class DeviceApiImpl(private val context: Context) : DeviceHostApi {
    override fun getDeviceInfo(): DeviceInfo = DeviceInfo(
        model = "${Build.MANUFACTURER} ${Build.MODEL}",
        osVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
        batteryLevel = batteryLevel(context).toLong(), // int في Dart = Long هنا
    )

    // @async في تعريف Pigeon ← suspend هنا (يمكن انتظار عمل طويل)
    override suspend fun greet(name: String): String = "أهلاً $name من Kotlin 👋"
}
