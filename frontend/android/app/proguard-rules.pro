## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver

## Sub-dependencies
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

## === REGLAS CRÍTICAS PARA DIO Y HTTP/HTTPS ===
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }

## Gson (serialización JSON vital para Dio)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

## BouncyCastle / Conscrypt / Seguridad (vital para HTTPS en Android)
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-keep class org.bouncycastle.** { *; }
-keep class org.conscrypt.** { *; }
-keep class org.openjsse.** { *; }
-keep class java.security.** { *; }
-keep class javax.crypto.** { *; }
-keep class javax.net.ssl.** { *; }

## === REGLAS PARA SQFLITE Y BASE DE DATOS ===
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**
-keep class android.database.sqlite.** { *; }

## === REGLAS PARA PROVIDERS / CONNECTIVITY ===
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

## Java annotations y utilidades
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-keep class java.util.concurrent.** { *; }

## Modificadores para Reflection y Data Classes en Dart/Flutter
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable
