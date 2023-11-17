# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in E:\AndroidSoft\sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

-dontwarn com.tencent.bugly.**
-keep public class com.tencent.bugly.**{*;}

-dontshrink
-keep class org.webrtc.**  { *; }
-keep class com.bumptech.**  { *; }
-keep class com.serenegiant.**  { *; }
-keepclasseswithmembernames class * { native <methods>; }

-keep class okhttp3.** {*;}
-keepclassmembers class okhttp3.** {
  *;
}

-keep class com.tencent.**{*;}
-keepclassmembers class com.tenncent.mars.** {
  *;
}

#-keep class !cn.wildfire.chat.moment.**,!cn.wildfirechat.moment.**, **{ *; }
-keep class cn.wildfirechat.moment.MomentClient {
    public void init(***);
}

-keep class cn.wildfire.chat.app.login.model.** {*;}
-keepclassmembers class cn.wildfire.chat.app.login.model.** {
  *;
}

-keep class cn.wildfire.chat.kit.net.base.** {*;}
-keepclassmembers class cn.wildfire.chat.kit.net.base.** {
  *;
}

-keep class  cn.wildfire.chat.kit.voip.conference.model.** {*;}
-keepclassmembers class  cn.wildfire.chat.kit.voip.conference.model.** {
  *;
}

-keep class cn.wildfire.chat.kit.group.GroupAnnouncement {*;}
-keepclassmembers class cn.wildfire.chat.kit.group.GroupAnnouncement {
  *;
}

-keep class cn.wildfirechat.model.** {*;}
-keepclassmembers class cn.wildfirechat.model.** {
  *;
}

-keepclassmembers class cn.wildfirechat.** {
    <init>(...);
}

-keepclassmembers class cn.wildfire.** {
    <init>(...);
}

-keepclassmembers class cn.wildfirechat.message.MessageContent {
    encode();
}

-keep class net.sourceforge.pinyin4j.** { *;}


-keep class cn.wildfirechat.imclient.** {*;}
-keepclassmembers class cn.wildfirechat.imclient.** {
  *;
}

-keepclassmembers class cn.wildfirechat.remote.** {
   public *;
}

-keep class cn.wildfirechat.rtckit.** {*;}
-keepclassmembers class cn.wildfirechat.rtckit.** {
  *;
}

#huawei push
-ignorewarnings
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep class com.hianalytics.android.**{*;}
-keep class com.huawei.updatesdk.**{*;}
-keep class com.huawei.hms.**{*;}
