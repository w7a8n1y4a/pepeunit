# Some plugins (shared_preferences_android, path_provider_android, ...) call
# their Kotlin classes from Dart through JNI by name and signature. R8 does
# not see those calls, so it renames or removes the methods and the release
# build fails with NoSuchMethodError.
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.dart_lang.** { *; }
# Their signatures also name Kotlin types (Continuation, Unit, Result).
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
