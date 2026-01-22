# Suppress warnings for Stripe SDK missing classes
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Keep all Stripe SDK classes
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-keep interface com.reactnativestripesdk.** { *; }

# Preserve all members in Stripe classes
-keepclassmembers class com.stripe.android.** {
    *** *;
}

-keepclassmembers class com.reactnativestripesdk.** {
    *** *;
}
