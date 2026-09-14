/**
 * Notification Service
 *
 * Sends push notifications to user devices via Firebase Cloud Messaging (FCM).
 * Falls back to a logged dev mode when FCM credentials are not configured.
 *
 * Configuration:
 *  - FCM_SERVER_KEY (legacy HTTP API) OR
 *  - FIREBASE_SERVICE_ACCOUNT_JSON (path to service account file for v1 API)
 *
 * In dev/test mode (no FCM credentials), the notification payload is logged
 * and stored in the notification_log table with status='sent' for audit.
 */

const { query } = require('../db');
const fs = require('fs');
const https = require('https');

const FCM_LEGACY_KEY = process.env.FCM_SERVER_KEY;
const FCM_SERVICE_ACCOUNT_PATH = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
const IS_DEV_MODE = !FCM_LEGACY_KEY && !FCM_SERVICE_ACCOUNT_PATH;

/**
 * Send a push notification to a single device token.
 */
async function sendPushNotification({ token, title, body, data = {}, userId, notificationType }) {
  if (!token) {
    return { success: false, error: 'No token' };
  }

  // Log the notification first (idempotent in case FCM retries)
  const logResult = await query(
    `INSERT INTO notification_log
     (user_id, notification_type, title, body, data_payload, status)
     VALUES ($1, $2, $3, $4, $5, 'pending')
     RETURNING id`,
    [userId, notificationType, title, body, JSON.stringify(data)]
  );
  const logId = logResult.rows[0].id;

  try {
    if (IS_DEV_MODE) {
      // Dev mode: just log the payload
      console.log(`[FCM-DEV] -> ${token.substring(0, 20)}... | ${title} | ${body}`);
      console.log(`[FCM-DEV]    data: ${JSON.stringify(data)}`);
      await query(
        `UPDATE notification_log SET status = 'sent' WHERE id = $1`,
        [logId]
      );
      return { success: true, devMode: true };
    }

    if (FCM_LEGACY_KEY) {
      await sendViaLegacyHttp(FCM_LEGACY_KEY, { token, title, body, data });
    } else {
      await sendViaV1Api(FCM_SERVICE_ACCOUNT_PATH, token, { title, body, data });
    }

    await query(
      `UPDATE notification_log SET status = 'sent' WHERE id = $1`,
      [logId]
    );
    return { success: true };
  } catch (err) {
    console.error(`[FCM] send error: ${err.message}`);
    await query(
      `UPDATE notification_log SET status = 'failed' WHERE id = $1`,
      [logId]
    );
    return { success: false, error: err.message };
  }
}

/**
 * FCM Legacy HTTP API (deprecated but still works as a fallback).
 */
function sendViaLegacyHttp(serverKey, { token, title, body, data }) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      to: token,
      notification: { title, body, sound: 'default' },
      data,
      priority: 'high',
    });
    const req = https.request({
      hostname: 'fcm.googleapis.com',
      path: '/fcm/send',
      method: 'POST',
      headers: {
        'Authorization': `key=${serverKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let responseData = '';
      res.on('data', (chunk) => { responseData += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseData);
        } else {
          reject(new Error(`FCM HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

/**
 * FCM HTTP v1 API (modern). Requires a service account JSON.
 * Uses a minimal OAuth2 token + REST call to avoid adding the firebase-admin
 * SDK as a dependency. If you need richer features, install firebase-admin.
 */
async function sendViaV1Api(serviceAccountPath, token, { title, body, data }) {
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  const projectId = serviceAccount.project_id;
  const accessToken = await getGoogleAccessToken(serviceAccount);

  const payload = JSON.stringify({
    message: {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
    },
  });

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'fcm.googleapis.com',
      path: `/v1/projects/${projectId}/messages:send`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(body);
        } else {
          reject(new Error(`FCM v1 ${res.statusCode}: ${body}`));
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

/**
 * Generate a Google OAuth2 access token from a service account using JWT.
 * Caches the token until expiry.
 */
let cachedToken = null;
let cachedExpiry = 0;
async function getGoogleAccessToken(serviceAccount) {
  if (cachedToken && Date.now() < cachedExpiry - 60000) {
    return cachedToken;
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const crypto = require('crypto');
  const encode = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
  const unsignedToken = `${encode(header)}.${encode(claim)}`;
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsignedToken);
  const signature = signer.sign(serviceAccount.private_key, 'base64url');
  const jwt = `${unsignedToken}.${signature}`;

  const params = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  });
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const parsed = JSON.parse(body);
          cachedToken = parsed.access_token;
          cachedExpiry = now + parsed.expires_in;
          resolve(cachedToken);
        } else {
          reject(new Error(`OAuth2 token error ${res.statusCode}: ${body}`));
        }
      });
    });
    req.on('error', reject);
    req.write(params.toString());
    req.end();
  });
}

/**
 * Send notifications to multiple device tokens for the same user.
 */
async function sendToUser({ userId, title, body, data = {}, notificationType = 'general' }) {
  const tokensResult = await query(
    `SELECT token FROM fcm_tokens WHERE user_id = $1 AND is_active = true`,
    [userId]
  );
  const results = [];
  for (const row of tokensResult.rows) {
    const r = await sendPushNotification({
      token: row.token,
      title,
      body,
      data,
      userId,
      notificationType,
    });
    results.push(r);
  }
  return results;
}

module.exports = {
  sendPushNotification,
  sendToUser,
  IS_DEV_MODE,
};
