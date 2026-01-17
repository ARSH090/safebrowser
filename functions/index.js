const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// This function is scheduled to run once every 24 hours.
exports.cleanupOldLogs = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  console.log('Running daily log cleanup job.');

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const timestampLimit = admin.firestore.Timestamp.fromDate(sevenDaysAgo);

  // Get all users
  const usersSnapshot = await db.collection('users').get();

  if (usersSnapshot.empty) {
    console.log('No users found. Exiting cleanup.');
    return null;
  }

  let totalDeleted = 0;
  const promises = [];

  // Iterate over each user to clean up their logs
  usersSnapshot.forEach(userDoc => {
    const userId = userDoc.id;
    const logsRef = db.collection('users').doc(userId).collection('logs');
    const query = logsRef.where('timestamp', '<=', timestampLimit);

    const deletePromise = query.get().then(snapshot => {
      if (snapshot.empty) {
        return;
      }

      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
        totalDeleted++;
      });
      return batch.commit();
    });
    promises.push(deletePromise);
  });

  await Promise.all(promises);
  console.log(`Successfully deleted ${totalDeleted} old log entries.`);
  return null;
});
