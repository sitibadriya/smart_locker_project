# Smart Locker Push Notification (FCM)

## What is included
- Flutter stores enabled FCM device tokens in `notification-devices`.
- Cloud Function triggers when `locker-activity/{activityId}` is created.
- 3 failed fingerprint events for a locker in 60 seconds => one warning push for each new activity after threshold (use cooldown/dedup extension before production if repeated events are possible).
- Explicit event types `tamper`, `forced_open`, `solenoid_failure`, `door_unsafe` => danger push.
- Routine successful access is retained in Firestore history and does not push (quiet by default).
- Web service worker displays background Web Push.

## Android
1. `flutter pub get`
2. Build/install app; tap **Aktifkan Notifikasi** and allow notifications.
3. Check Firestore `notification-devices` for a document with `token`, `platform`, `enabled: true`.
4. Test using Cloud Functions after deployment.

Android 13+ requires notification permission. Android force-stop from system Settings may suppress delivery until the user launches app again; this is OS behavior, not an app bug.

## Cloud Functions deployment
1. Install Firebase CLI and sign in: `firebase login`
2. In project root run `firebase use smart-locker-iot-10a0e` (or select the correct project).
3. Ensure billing/Blaze plan is enabled for Cloud Functions.
4. `cd functions && npm install && cd ..`
5. `firebase deploy --only functions:notifyLockerActivity`

## Web
1. `web/firebase-messaging-sw.js` is included and uses this project's Firebase web config.
2. In Firebase Console > Project settings > Cloud Messaging, create Web Push certificate and copy the VAPID public key.
3. Add the VAPID key to the Flutter web token call (`NotificationService.enableAndRegisterDevice(vapidKey: 'YOUR_PUBLIC_VAPID_KEY')`).
4. Serve web over HTTPS (localhost is allowed for development), deploy hosting, grant browser notification permission.

## Severity policy
- INFO: successful access/normal close is history-only by default (quiet).
- WARNING: >=3 denied fingerprint attempts within 60 seconds.
- DANGER: only explicit `eventType` values above. A failed fingerprint alone is NOT proof of forced entry.

## Important production hardening
- Configure Firebase Authentication and Firestore rules so only authenticated admin devices can write/read `notification-devices`.
- Current project has no user identity binding in this implementation; token registration is a starter implementation, not a multi-tenant secure design.
- Add dedupe/cooldown state in Firestore before enabling frequent sensor events. Function currently triggers once per activity document.
- ESP32 offline events can only be delivered after ESP32 reconnects and writes them to Firestore; FCM cannot notify from a disconnected device.
