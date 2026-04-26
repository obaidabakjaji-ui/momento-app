/**
 * Momento — email code verification.
 *
 * Two callable functions:
 *   requestEmailCode  → generates a 6-digit code, stores its hash, queues an
 *                       email via the "Trigger Email" extension. Plain code
 *                       only ever lives in the email body, never in Firestore
 *                       reachable by a client.
 *   verifyEmailCode   → hashes the user's input, compares to the stored hash,
 *                       and on match flips Firebase Auth's `emailVerified`
 *                       flag to true and deletes the verification doc.
 *
 * Required extension: "Trigger Email from Firestore" (`firebase-extensions`),
 * configured to read from the `mail` collection. Configure SMTP credentials
 * during extension install.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const CODE_TTL_MS = 10 * 60 * 1000; // 10 minutes
const RESEND_COOLDOWN_MS = 30 * 1000; // 30 seconds
const MAX_ATTEMPTS = 5;

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function generateCode() {
  // 100000–999999 inclusive, always 6 digits.
  return String(crypto.randomInt(100000, 1000000));
}

function buildEmail(code, displayName) {
  const greeting = displayName ? `Hi ${displayName},` : "Hi,";
  return {
    subject: "Your Momento verification code",
    text: `${greeting}\n\nYour Momento verification code is: ${code}\n\nIt expires in 10 minutes. If you didn't request this, you can ignore this email.\n\n— Momento`,
    html: `
      <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#FFF5EE;padding:32px;color:#2D2337;">
        <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:16px;padding:32px;">
          <h1 style="margin:0 0 8px 0;font-size:22px;color:#FF6B6B;">Momento</h1>
          <p style="margin:0 0 24px 0;color:#2D2337;opacity:0.7;">${greeting}</p>
          <p style="margin:0 0 12px 0;">Your verification code is</p>
          <div style="font-size:34px;font-weight:700;letter-spacing:6px;background:#FFF5EE;border-radius:12px;padding:16px;text-align:center;color:#2D2337;">
            ${code}
          </div>
          <p style="margin:24px 0 0 0;color:#2D2337;opacity:0.6;font-size:13px;">
            It expires in 10 minutes. If you didn't request this, you can safely ignore this email.
          </p>
        </div>
      </div>
    `.trim(),
  };
}

/** Callable: requests a new code be generated and emailed to the caller. */
exports.requestEmailCode = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const userRecord = await auth.getUser(uid);
  const email = userRecord.email;
  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "Account has no email on file."
    );
  }
  if (userRecord.emailVerified) {
    return { alreadyVerified: true };
  }

  // Throttle resends.
  const ref = db.collection("email_verifications").doc(uid);
  const existing = await ref.get();
  if (existing.exists) {
    const last = existing.data().createdAt?.toMillis?.() ?? 0;
    if (Date.now() - last < RESEND_COOLDOWN_MS) {
      const wait = Math.ceil(
        (RESEND_COOLDOWN_MS - (Date.now() - last)) / 1000
      );
      throw new HttpsError(
        "resource-exhausted",
        `Wait ${wait}s before requesting another code.`
      );
    }
  }

  const code = generateCode();
  const hash = sha256(code);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + CODE_TTL_MS
  );

  await ref.set({
    codeHash: hash,
    expiresAt,
    attempts: 0,
    createdAt: now,
  });

  // Hand off to the Trigger Email extension.
  const { subject, text, html } = buildEmail(code, userRecord.displayName);
  await db.collection("mail").add({
    to: email,
    message: { subject, text, html },
  });

  return { sent: true };
});

/** Callable: verifies a 6-digit code submitted by the caller. */
exports.verifyEmailCode = onCall({ region: "us-central1" }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const code = req.data?.code;
  if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Code must be 6 digits.");
  }

  const ref = db.collection("email_verifications").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "No active verification — request a new code."
    );
  }
  const data = snap.data();
  const now = Date.now();
  const expires = data.expiresAt?.toMillis?.() ?? 0;
  if (now > expires) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Code expired.");
  }
  if ((data.attempts ?? 0) >= MAX_ATTEMPTS) {
    await ref.delete();
    throw new HttpsError(
      "resource-exhausted",
      "Too many attempts — request a new code."
    );
  }

  const submittedHash = sha256(code);
  if (submittedHash !== data.codeHash) {
    await ref.update({
      attempts: admin.firestore.FieldValue.increment(1),
    });
    throw new HttpsError("permission-denied", "Wrong code.");
  }

  // Match. Mark verified at the Auth layer + clean up.
  await auth.updateUser(uid, { emailVerified: true });
  await ref.delete();

  return { verified: true };
});
