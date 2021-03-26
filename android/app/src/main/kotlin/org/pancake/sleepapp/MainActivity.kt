package org.pancake.slap

import android.util.Log
import androidx.annotation.NonNull
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.AssetPackStateUpdateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result


class MainActivity: FlutterActivity(), MethodChannel.MethodCallHandler {
	private val CHANNEL = "slap.pancake.org/assetpack"
	private val PACK = "SlapMainActivity"
	lateinit var methodChannel: MethodChannel
	lateinit var assetPackManager: AssetPackManager
	lateinit var methodResult: Result

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
		methodChannel.setMethodCallHandler(::onMethodCall)
		assetPackManager = AssetPackManagerFactory.getInstance(this.applicationContext)
		assetPackManager.registerListener(assetPackStateUpdateListener)
	}

	override fun onDestroy() {
		super.onDestroy()
		assetPackManager.unregisterListener(assetPackStateUpdateListener)
	}

	override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {	
		if (call.method == "getAssetPackDirectory") {
			methodResult = result

			val assetPack = call.arguments.toString()

			val assetPath = getAbsoluteAssetPath(assetPack);
			if (assetPath != null) {
				result.success(assetPath)
			} else {
				assetPackManager.fetch(listOf(assetPack))
			}
		} else {
			Log.e(PACK, "Method not implemented")
			result.notImplemented()
		}
	}

	private fun getAbsoluteAssetPath(assetPack: String): String? {
		val assetPackPath = assetPackManager.getPackLocation(assetPack)
		if (assetPackPath == null) {
			return null;
		}
		return assetPackPath.assetsPath()
	}

	val assetPackStateUpdateListener = AssetPackStateUpdateListener { state ->
		if (state.status() == AssetPackStatus.COMPLETED) {
			val assetPack = state.name()
			val assetPath = getAbsoluteAssetPath(assetPack)
			if (assetPath != null) {				
//				methodChannel.invokeMethod("assetPackLoaded", assetPath);
				methodResult.success(assetPath)
			} else {
				Log.e(PACK, "After fetch success, still no assetpath:"+assetPack)
				methodResult.error(PACK, "After fetch success, still cannot get assetpath?", null)
			}					
		} else if (state.status() == AssetPackStatus.FAILED) {
			Log.e(PACK, state.errorCode().toString())
			methodResult.error(PACK, "AssetPack failed to load: "+state.errorCode().toString(), null)
		}
	}
}

/* // from docs
	assetPackStateUpdateListener = new AssetPackStateUpdateListener() {
		@Override
		public void onStateUpdate(AssetPackState assetPackState) {
			switch (assetPackState.status()) {
			case AssetPackStatus.PENDING:
				Log.i(PACK, "Pending");
				break;

			case AssetPackStatus.DOWNLOADING:
				long downloaded = assetPackState.bytesDownloaded();
				long totalSize = assetPackState.totalBytesToDownload();
				double percent = 100.0 * downloaded / totalSize;

				Log.i(PACK, "PercentDone=" + String.format("%.2f", percent));
				break;

			case AssetPackStatus.TRANSFERRING:
				// 100% downloaded and assets are being transferred.
				// Notify user to wait until transfer is complete.
				break;

			case AssetPackStatus.COMPLETED:
			Log.i(PACK, "---------- COMPLETED!------------------");
				// Asset pack is ready to use. Start the game.
				break;

			case AssetPackStatus.FAILED:
				// Request failed. Notify user.
				Log.e(PACK, assetPackState.errorCode());
				break;

			case AssetPackStatus.CANCELED:
				// Request canceled. Notify user.
				break;

			case AssetPackStatus.WAITING_FOR_WIFI:
				if (!waitForWifiConfirmationShown) {
					assetPackManager.showCellularDataConfirmation(MainActivity.this)
					.addOnSuccessListener(new OnSuccessListener<Integer> () {
						@Override
						public void onSuccess(Integer resultCode) {
							if (resultCode == RESULT_OK) {
							Log.d(PACK, "Confirmation dialog has been accepted.");
							} else if (resultCode == RESULT_CANCELED) {
							Log.d(PACK, "Confirmation dialog has been denied by the user.");
							}
						}
					});
					waitForWifiConfirmationShown = true;
				}
				break;

			case AssetPackStatus.NOT_INSTALLED:
				// Asset pack is not downloaded yet.
				break;
			}
		}
	}
*/