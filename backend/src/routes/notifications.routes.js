const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware.js');
const { query } = require('../db');
const { sendToUser } = require('../services/notification.service');
const { getUpcomingFastingDays } = require('../services/fasting.calendar');

/**
 * @route POST /api/notifications/register-token
 * @desc Register or update an FCM token for the authenticated user
 * @access Private
 *
 * Body: { token: string, deviceType: 'android'|'ios'|'web', deviceName?: string }
 */
router.post('/register-token', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { token, deviceType, deviceName } = req.body || {};

    if (!token) {
      return res.status(400).json({ error: 'BadRequest', message: 'token is required' });
    }
    if (deviceType && !['android', 'ios', 'web'].includes(deviceType)) {
      return res.status(400).json({ error: 'BadRequest', message: 'Invalid deviceType' });
    }

    // Upsert the token (re-activate if previously deactivated)
    const result = await query(
      `INSERT INTO fcm_tokens (user_id, token, device_type, device_name, is_active)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (user_id, token) DO UPDATE
         SET is_active = true, updated_at = NOW(), device_type = COALESCE($3, fcm_tokens.device_type), device_name = COALESCE($4, fcm_tokens.device_name)
       RETURNING id, device_type, device_name, created_at`,
      [userId, token, deviceType, deviceName]
    );

    // Ensure the user has a notification_preferences row
    await query(
      `INSERT INTO notification_preferences (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );

    res.status(200).json({ success: true, token: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

/**
 * @route DELETE /api/notifications/unregister-token
 * @desc Deactivate an FCM token (logout / uninstall)
 * @access Private
 *
 * Body: { token: string }
 */
router.delete('/unregister-token', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { token } = req.body || {};
    if (!token) {
      return res.status(400).json({ error: 'BadRequest', message: 'token is required' });
    }
    await query(
      `UPDATE fcm_tokens SET is_active = false, updated_at = NOW() WHERE user_id = $1 AND token = $2`,
      [userId, token]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

/**
 * @route GET /api/notifications/preferences
 * @desc Fetch the authenticated user's notification preferences
 * @access Private
 */
router.get('/preferences', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await query(
      `SELECT fasting_reminders, meal_reminders, weekly_summary, educational_tips,
              reminder_time, fasting_reminder_enabled, fasting_day_notice_hours
       FROM notification_preferences WHERE user_id = $1`,
      [userId]
    );
    const prefs = result.rows[0] || {
      fasting_reminders: true,
      meal_reminders: true,
      weekly_summary: true,
      educational_tips: true,
      reminder_time: '07:00',
      fasting_reminder_enabled: true,
      fasting_day_notice_hours: 18,
    };
    res.status(200).json(prefs);
  } catch (err) {
    next(err);
  }
});

/**
 * @route PUT /api/notifications/preferences
 * @desc Update notification preferences
 * @access Private
 */
router.put('/preferences', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      fasting_reminders,
      meal_reminders,
      weekly_summary,
      educational_tips,
      reminder_time,
      fasting_reminder_enabled,
      fasting_day_notice_hours,
    } = req.body || {};

    await query(
      `INSERT INTO notification_preferences
        (user_id, fasting_reminders, meal_reminders, weekly_summary, educational_tips,
         reminder_time, fasting_reminder_enabled, fasting_day_notice_hours)
       VALUES ($1, COALESCE($2, true), COALESCE($3, true), COALESCE($4, true), COALESCE($5, true),
               COALESCE($6, '07:00'), COALESCE($7, true), COALESCE($8, 18))
       ON CONFLICT (user_id) DO UPDATE
         SET fasting_reminders = COALESCE($2, notification_preferences.fasting_reminders),
             meal_reminders = COALESCE($3, notification_preferences.meal_reminders),
             weekly_summary = COALESCE($4, notification_preferences.weekly_summary),
             educational_tips = COALESCE($5, notification_preferences.educational_tips),
             reminder_time = COALESCE($6, notification_preferences.reminder_time),
             fasting_reminder_enabled = COALESCE($7, notification_preferences.fasting_reminder_enabled),
             fasting_day_notice_hours = COALESCE($8, notification_preferences.fasting_day_notice_hours),
             updated_at = NOW()`,
      [userId, fasting_reminders, meal_reminders, weekly_summary, educational_tips,
       reminder_time, fasting_reminder_enabled, fasting_day_notice_hours]
    );

    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

/**
 * @route GET /api/notifications/upcoming-fasts
 * @desc Return Ethiopian Orthodox fasting days in the next 60 days
 * @access Private
 */
router.get('/upcoming-fasts', authMiddleware, async (req, res, next) => {
  try {
    const days = Math.min(parseInt(req.query.days) || 60, 365);
    const fasts = getUpcomingFastingDays(new Date(), days);
    res.status(200).json({ fasts });
  } catch (err) {
    next(err);
  }
});

/**
 * @route GET /api/notifications/log
 * @desc Return recent notifications sent to the authenticated user
 * @access Private
 */
router.get('/log', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const limit = Math.min(parseInt(req.query.limit) || 30, 100);
    const result = await query(
      `SELECT id, notification_type, title, body, data_payload, status, sent_at, opened_at
       FROM notification_log
       WHERE user_id = $1
       ORDER BY sent_at DESC
       LIMIT $2`,
      [userId, limit]
    );
    res.status(200).json({ notifications: result.rows });
  } catch (err) {
    next(err);
  }
});

/**
 * @route POST /api/notifications/mark-opened
 * @desc Mark a notification as opened (for analytics)
 * @access Private
 */
router.post('/mark-opened', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { notificationId } = req.body || {};
    if (!notificationId) {
      return res.status(400).json({ error: 'BadRequest', message: 'notificationId required' });
    }
    await query(
      `UPDATE notification_log SET status = 'opened', opened_at = NOW()
       WHERE id = $1 AND user_id = $2`,
      [notificationId, userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
});

/**
 * @route POST /api/notifications/test
 * @desc Send a test push to the authenticated user (dev only)
 * @access Private
 */
router.post('/test', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { title, body, route } = req.body || {};
    const results = await sendToUser({
      userId,
      title: title || 'Test notification',
      body: body || 'This is a test push from Smart Nutrition & Health.',
      data: { route: route || '/home', type: 'test' },
      notificationType: 'test',
    });
    res.status(200).json({ success: true, results });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
