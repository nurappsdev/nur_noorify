const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

function asDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

exports.sendAnnouncementPush = onDocumentWritten(
  "announcements/{announcementId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;

    const after = afterSnap.data() || {};
    if (after.active !== true) return;
    if (after.send_push !== true) return;

    const status = (after.push_status || "").toString().toLowerCase().trim();
    if (status === "sent" || status === "processing") return;

    const ref = afterSnap.ref;
    const fieldValue = admin.firestore.FieldValue;

    await ref.set(
      {
        push_status: "processing",
        push_started_at: fieldValue.serverTimestamp(),
        updated_at: fieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    const latestSnap = await ref.get();
    const latest = latestSnap.data() || {};

    if (latest.active !== true || latest.send_push !== true) {
      logger.info("Push skipped: no longer active/send_push", event.params);
      await ref.set(
        {
          push_status: "idle",
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    const now = new Date();
    const startAt = asDate(latest.start_at);
    const endAt = asDate(latest.end_at);

    if (startAt && now < startAt) {
      logger.info("Push deferred: before start_at", {
        id: event.params.announcementId,
      });
      await ref.set(
        {
          push_status: "pending",
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    if (endAt && now > endAt) {
      logger.info("Push failed: after end_at", {
        id: event.params.announcementId,
      });
      await ref.set(
        {
          push_status: "failed",
          push_error: "Announcement window expired before send.",
          push_failed_at: fieldValue.serverTimestamp(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    const topic = (latest.push_topic || "noorify_all").toString().trim();
    const title = (
      latest.title_bn ||
      latest.title_en ||
      "Noorify"
    ).toString();
    const body = (
      latest.message_bn ||
      latest.message_en ||
      "You have a new Noorify update."
    ).toString();

    try {
      const messageId = await admin.messaging().send({
        topic,
        notification: {title, body},
        data: {
          announcement_id: event.params.announcementId.toString(),
          source: "announcement",
          push_topic: topic,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "noorify_general",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      });

      logger.info("Announcement push sent", {
        id: event.params.announcementId,
        topic,
        messageId,
      });

      await ref.set(
        {
          send_push: false,
          push_status: "sent",
          push_sent_at: fieldValue.serverTimestamp(),
          push_error: fieldValue.delete(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    } catch (error) {
      logger.error("Announcement push send failed", error);
      await ref.set(
        {
          push_status: "failed",
          push_error: String(error),
          push_failed_at: fieldValue.serverTimestamp(),
          updated_at: fieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
  },
);

/**
 * Sends a push to every device token stored on users/{uid}.fcm_tokens and
 * prunes any tokens FCM reports as no longer valid.
 * @param {string} uid Recipient user id.
 * @param {{title: string, body: string, data?: Object}} payload Message.
 * @return {Promise<void>}
 */
async function sendToUser(uid, payload) {
  if (!uid) return;
  const db = admin.firestore();
  const snap = await db.collection("users").doc(uid).get();
  const tokens = ((snap.data() || {}).fcm_tokens || []).filter(Boolean);
  if (!tokens.length) return;

  const data = Object.fromEntries(
    Object.entries(payload.data || {}).map(([k, v]) => [k, String(v)]),
  );

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title: payload.title, body: payload.body},
    data,
    android: {priority: "high", notification: {channelId: "noorify_general"}},
    apns: {headers: {"apns-priority": "10"}},
  });

  const stale = [];
  response.responses.forEach((r, i) => {
    if (r.success) return;
    const code = (r.error && r.error.code) || "";
    if (
      code.includes("registration-token-not-registered") ||
      code.includes("invalid-argument")
    ) {
      stale.push(tokens[i]);
    }
  });
  if (stale.length) {
    await db.collection("users").doc(uid).set(
      {fcm_tokens: admin.firestore.FieldValue.arrayRemove(...stale)},
      {merge: true},
    );
  }
}

/**
 * Drives the family-request lifecycle:
 *  - a new pending request notifies the recipient;
 *  - acceptance adds the recipient to the requester's family_members (the only
 *    place this array is ever written) and notifies the requester;
 *  - a decline notifies the requester.
 */
exports.onFamilyRequestWrite = onDocumentWritten(
  "family_requests/{reqId}",
  async (event) => {
    const before = event.data && event.data.before && event.data.before.data();
    const after = event.data && event.data.after && event.data.after.data();
    if (!after) return; // deleted/cancelled

    const beforeStatus = before ? before.status : null;
    const afterStatus = after.status;

    // New pending request -> notify the recipient.
    if (!before && afterStatus === "pending") {
      await sendToUser(after.to_uid, {
        title: "New family request",
        body: `${after.from_name || "Someone"} wants to add you as family.`,
        data: {
          type: "family_request",
          request_id: event.params.reqId,
          from_uid: after.from_uid,
        },
      });
      return;
    }

    // Accepted -> add to requester's family list + notify them.
    if (beforeStatus !== "accepted" && afterStatus === "accepted") {
      const member = {
        uid: after.to_uid,
        name: after.to_name || "",
        photo_url: after.to_photo || null,
        // serverTimestamp() is not allowed inside an array, so use a concrete
        // timestamp for the accepted-at moment.
        since: admin.firestore.Timestamp.now(),
      };
      await admin.firestore().collection("users").doc(after.from_uid).set(
        {family_members: admin.firestore.FieldValue.arrayUnion(member)},
        {merge: true},
      );
      await sendToUser(after.from_uid, {
        title: "Family request accepted",
        body: `${after.to_name || "Your request"} is now in your family list.`,
        data: {type: "family_accepted", request_id: event.params.reqId},
      });
      logger.info("Family request accepted", {
        id: event.params.reqId,
        from: after.from_uid,
        to: after.to_uid,
      });
      return;
    }

    // Declined -> let the requester know.
    if (beforeStatus !== "declined" && afterStatus === "declined") {
      await sendToUser(after.from_uid, {
        title: "Family request declined",
        body: `${after.to_name || "Your request"} declined your request.`,
        data: {type: "family_declined", request_id: event.params.reqId},
      });
    }
  },
);
