package sergio.votaa.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Sensitive screens (ID code, share code): no screenshot, no
        // recording, blank in recent apps. See lib/core/security/secure_screen.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "civic/secure_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "isCaptured" -> result.success(false)
                    else -> result.notImplemented()
                }
            }
    }
}
