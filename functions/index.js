const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Notification policy: failed fingerprint #3 within 60 seconds => warning.
// Routine successful access/door close is stored in Firestore, not pushed.
exports.notifyLockerActivity = onDocumentCreated(
  { document: 'locker-activity/{activityId}', region: 'asia-southeast2' },
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    const result = String(d.hasilAkses || '').toUpperCase();
    const locker = String(d.idLocker || d.lockerId || 'Locker');
    const name = String(d.namaSantri || d.nama || 'Pengguna tidak dikenal');
    const isDenied = result.includes('TOLAK') || result.includes('GAGAL');

    let level = 'info';
    let title = `Akses ${locker}`;
    let body = `${name} berhasil mengakses ${locker}.`;
    let shouldPush = false;

    if (isDenied) {
      // Count denied events for this locker over the last minute.
      const since = admin.firestore.Timestamp.fromMillis(Date.now() - 60 * 1000);
      const recent = await db.collection('locker-activity')
        .where('idLocker', '==', locker)
        .where('hasilAkses', '==', d.hasilAkses)
        .where('waktu', '>=', since)
        .get();
      if (recent.size >= 3) {
        level = 'warning';
        title = `Waspada: ${locker}`;
        body = `${recent.size} percobaan fingerprint tidak berhasil dalam 60 detik.`;
        shouldPush = true;
      }
    }

    // Explicit high severity events only; don't infer forced entry from a denied fingerprint.
    const eventType = String(d.eventType || d.jenisAktivitas || '').toLowerCase();
    if (['tamper', 'forced_open', 'solenoid_failure', 'door_unsafe'].includes(eventType)) {
      level = 'danger';
      title = `BAHAYA: ${locker}`;
      body = String(d.pesan || 'Kondisi locker memerlukan pemeriksaan segera.');
      shouldPush = true;
    }

    if (!shouldPush) return;

    const devices = await db.collection('notification-devices').where('enabled', '==', true).get();
    const tokens = [...new Set(devices.docs.map(x => x.get('token')).filter(Boolean))];
    if (!tokens.length) {
      logger.info('No enabled notification devices');
      return;
    }

    const message = {
      notification: { title, body },
      data: { level, type: 'locker_activity', idLocker: locker, activityId: event.params.activityId },
      android: { priority: level === 'danger' ? 'high' : 'normal', notification: {
        channelId: level === 'danger' ? 'locker_danger_channel' : 'locker_warning_channel',
        sound: level === 'danger' ? 'default' : undefined
      }},
      webpush: { notification: { title, body, icon: '/icons/Icon-192.png', tag: `${locker}-${level}` } }
    };
    const response = await admin.messaging().sendEachForMulticast({ ...message, tokens });
    logger.info(`FCM sent ${response.successCount}/${tokens.length}`);

    // Remove invalid/expired device tokens.
    const batch = db.batch();
    response.responses.forEach((r, i) => {
      if (!r.success && ['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(r.error?.code)) {
        const doc = devices.docs.find(x => x.get('token') === tokens[i]);
        if (doc) batch.delete(doc.ref);
      }
    });
    await batch.commit();
  }
);
