# Reglas ProGuard / R8 para Google ML Kit Document Scanner y Firebase Components
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep interface com.google.firebase.components.ComponentRegistrar { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
    *;
}
-keepnames class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
