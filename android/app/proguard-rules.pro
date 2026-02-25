## Google Play Core (referenced by Flutter embedding for deferred components, not used in this app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Flutter embedding
-keep class io.flutter.embedding.** { *; }

## Gson (used by Firebase and other plugins)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## Firestore model classes (prevent field name obfuscation)
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

## Firebase Auth
-keep class com.google.firebase.auth.** { *; }

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

## Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

## Retain generic type information for use by reflection by converters and adapters.
-keepattributes Signature
## Retain service method parameters when optimizing.
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

## Ignore annotation used for build tooling.
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

## Ignore JSR 305 annotations for embedding nullability information.
-dontwarn javax.annotation.**

## Guarded by a NoClassDefFoundError try/catch and only used when on the classpath.
-dontwarn kotlin.Unit

## Top-level functions that can only be used by Kotlin.
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*

## With R8 full mode, it sees no subtypes of Retrofit interfaces since they are created with a Proxy
## and replaces all potential values with null. Explicitly keeping the interfaces prevents this.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>

## Platform calls Class.forName on types which do not exist on Android to determine platform.
-dontnote retrofit2.Platform

## Platform used when running on Java 8 VMs. Will not be used at runtime.
-dontwarn retrofit2.Platform$Java8

## Retain declared checked exceptions for use by a Proxy instance.
-keepattributes Exceptions

## Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-keep class com.google.android.gms.internal.ads.** { *; }

## audioplayers plugin
-keep class xyz.luan.audioplayers.** { *; }

## shared_preferences plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## flutter_secure_storage plugin
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## vibration plugin
-keep class com.benjamindonnachie.vibration.** { *; }

## Keep custom application classes
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

## If you keep the line number information, uncomment this to hide the original source file name
# -renamesourcefileattribute SourceFile
