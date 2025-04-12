const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnAdd = functions.firestore
  .document('accidents/{docId}')
  .onCreate((snap, context) => {
    const newValue = snap.data();

    const payload = {
      notification: {
        title: 'New Value Added!',
        body: `An accident detected`,
      },
    };

    return admin.messaging().sendToTopic('accident-alert', payload);
  });