const { onAuthUserCreate } = require("firebase-functions/v2/identity");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createUserDoc = onAuthUserCreate(async (event) => {
  const user = event.data; // ข้อมูลผู้ใช้จาก Auth
  const db = getFirestore();
  const ref = db.collection("users").doc(user.uid);

  const snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      email: user.email || "",
      displayName: user.displayName || "",
      createdAt: FieldValue.serverTimestamp(),
    });
  }
});
