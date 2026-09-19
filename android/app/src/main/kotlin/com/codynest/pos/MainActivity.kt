package com.codynest.pos

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    companion object {
        private const val SIGNING_CHANNEL = "com.codynest.pos/signing"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SIGNING_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSigningSha1" -> result.success(signingSha1())
                else -> result.notImplemented()
            }
        }
    }

    /// SHA-1 of the certificate that actually signed the *installed* build.
    /// This is what Google Sign-In validates against the OAuth Android client,
    /// so it differs between a local debug install (debug keystore) and a
    /// Play-installed build (Play App Signing key).
    private fun signingSha1(): String? {
        return try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES,
                )
                @Suppress("DEPRECATION")
                info.signatures
            }
            val signature = signatures?.firstOrNull() ?: return null
            val digest = MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
            digest.joinToString("") { "%02x".format(it.toInt() and 0xff) }
        } catch (e: Exception) {
            null
        }
    }
}
