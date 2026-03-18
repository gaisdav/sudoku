# Flutter
-keep class io.flutter.app.** { *; }

# Google Mobile Ads (правила обычно подтягиваются из AAR, на всякий случай)
-keep class com.google.android.gms.ads.** { *; }

# flutter_local_notifications + Gson: без этого в release R8 даёт
# java.lang.RuntimeException: Missing type parameter при cancel / loadScheduledNotifications
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
