package org.pancake.slap

import androidx.annotation.NonNull
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result


class MainActivity: FlutterActivity(), MethodChannel.MethodCallHandler {
    private val CHANNEL = "slap.pancake.org/assetpack"
    lateinit var methodChannel: MethodChannel
    lateinit var assetPackManager: AssetPackManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(::onMethodCall)
        assetPackManager = AssetPackManagerFactory.getInstance(this.applicationContext)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
       if (call.method == "getAssetPackDirectory") {
            val assetPack = call.arguments.toString()

            val assetPath = getAbsoluteAssetPath(assetPack);
            if (assetPath != null) {
                result.success(assetPath)
            } else {
                assetPackManager.fetch(listOf(assetPack)).addOnSuccessListener {
                    val assetPath = getAbsoluteAssetPath(assetPack)
                    if (assetPath != null) {
                        result.success(assetPath)
                    } else {
                        result.error("doh", "After fetch success, still cannot get assetpath?", null)
                    }
                }.addOnFailureListener {
                    result.error("doh", "assetPackManager.fetch failed", null)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    private fun getAbsoluteAssetPath(assetPack: String): String? {
        val assetPackPath = assetPackManager.getPackLocation(assetPack)
        if (assetPackPath == null) {
            // asset pack is not ready
            return null;
        }
        return assetPackPath.assetsPath()
    }
}