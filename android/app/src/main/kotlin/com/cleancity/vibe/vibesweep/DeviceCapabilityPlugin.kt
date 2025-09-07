package com.cleancity.vibe.vibesweep

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DeviceCapabilityPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "vibesweep/device_capabilities")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkARCoreSupport" -> {
                result.success(checkARCoreSupport())
            }
            "hasHighPerformanceGPU" -> {
                result.success(hasHighPerformanceGPU())
            }
            "getAvailableMemory" -> {
                result.success(getAvailableMemory())
            }
            "getDeviceInfo" -> {
                result.success(getDeviceInfo())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkARCoreSupport(): Boolean {
        // Basic heuristic for ARCore support
        // In production, you would use proper ARCore availability check
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && 
               !isLowEndDevice()
    }

    private fun hasHighPerformanceGPU(): Boolean {
        // Heuristic based on device characteristics
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memoryInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        // Consider high-performance if device has more than 4GB RAM
        return memoryInfo.totalMem > 4L * 1024 * 1024 * 1024
    }

    private fun getAvailableMemory(): Int {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memoryInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        // Return available memory in MB
        return (memoryInfo.availMem / (1024 * 1024)).toInt()
    }

    private fun isLowEndDevice(): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        return activityManager.isLowRamDevice
    }

    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "isLowRamDevice" to isLowEndDevice()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}