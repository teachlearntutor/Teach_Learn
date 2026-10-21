# Flutter R8 Proguard Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase & Firestore Serialized Models
-keepclassmembers class * {
    @com.google.firebase.firestore.** *;
}
