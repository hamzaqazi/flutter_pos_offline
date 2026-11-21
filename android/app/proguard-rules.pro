# ─────────────────────────────────────────────────────────────────────────
# ProGuard / R8 rules for the release build (isMinifyEnabled + isShrinkResources)
#
# The bulk of third-party protection comes from each plugin's own
# consumer-proguard rules (auto-merged by AGP). This file adds the pieces
# those don't cover: the Flutter runtime and this app's own native code.
# ─────────────────────────────────────────────────────────────────────────

# ── Flutter engine & embedding ──────────────────────────────────────────────
# Keep the runtime intact so R8 never strips/renames the engine's entry
# points, the FlutterActivity, or the plugin bridge.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── App platform code ───────────────────────────────────────────────────────
# Native MainActivity + any MethodChannel handlers (e.g. "com.codynest.pos/signing").
# Not covered by a plugin's consumer rules, so keep it explicitly.
-keep class com.codynest.pos.** { *; }

# ── Respect @Keep annotations ───────────────────────────────────────────────
# Some plugin code marks classes/members with androidx @Keep to survive R8.
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}

# ── Native libraries ────────────────────────────────────────────────────────
# Don't drop native .so references even if R8 thinks the loader call is dead.
-keepclasseswithmembernames class * {
    native <methods>;
}
