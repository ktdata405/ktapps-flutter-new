# Flutter Wrapper - Keep Flutter framework classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Kotlin - Keep Kotlin metadata and generated mappings
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# AndroidX and Google Material - Keep all AndroidX and Material Design classes
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-keep class com.google.android.material.** { *; }
-keep interface com.google.android.material.** { *; }

# Preserve line numbers and source file names for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep class * extends android.app.Activity
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
-keep class * extends android.preference.Preference

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
