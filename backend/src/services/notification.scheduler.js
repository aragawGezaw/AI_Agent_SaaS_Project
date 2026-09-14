/**
 * Notification Scheduler Service
 *
 * Uses node-cron to periodically:
 *  1. Check for upcoming fasting days (Ethiopian Orthodox) and send reminders
 *  2. Send daily meal logging reminders at user-preferred time
 *  3. Process any queued notifications
 *
 * Architecture:
 *  - Cron runs every 15 minutes and picks up users due for a reminder.
 *  - Individual notification sends are delegated to notification.service.js
 *  - Scheduling state (is_notified flag) is persisted in fasting_schedules table.
 */

const cron = require('node-cron');
const { query } = require('../db');
const { sendPushNotification } = require('./notification.service');
const { getUpcomingFastingDays } = require('./fasting.calendar');

const LOGGER = console;

/**
 * Compute a target send datetime for a given user preference time.
 * Returns a Date in the user's local timezone approximated as UTC offset 0.
 */
function computeReminderDate(reminderTime, daysFromNow = 0) {
  const now = new Date();
  const [hours, minutes] = reminderTime.split(':').map(Number);
  const target = new Date(now);
  target.setDate(target.getDate() + daysFromNow);
  target.setHours(hours, minutes, 0, 0);
  return target;
}

/**
 * Check if a target datetime has passed (within a 15-min window).
 */
function isWindowPassed(targetDate, windowMinutes = 15) {
  const now = new Date();
  const diffMs = now.getTime() - targetDate.getTime();
  return diffMs >= 0 && diffMs <= windowMinutes * 60 * 1000;
}

/**
 * Sync upcoming fasting days from the calendar into fasting_schedules for
 * all users who have fasting_reminder_enabled = true.
 */
async function syncFastingSchedules() {
  const fastDays = getUpcomingFastingDays(new Date(), 60);
  const fastDates = new Set(fastDays.map(f => f.date));
  const fastNames = Object.fromEntries(fastDays.map(f => [f.date, f.name]));

  if (fastDates.size === 0) return;

  // Upsert fasting schedules for eligible users
  const usersResult = await query(
    `SELECT u.id, u.preferences->>'reminder_time' as reminder_time
     FROM users u
     JOIN notification_preferences np ON np.user_id = u.id
     WHERE np.fasting_reminder_enabled = true`
  );

  for (const user of usersResult.rows) {
    for (const date of fastDates) {
      await query(
        `INSERT INTO fasting_schedules (user_id, fasting_date, fasting_name)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, fasting_date) DO NOTHING`,
        [user.id, date, fastNames[date] || 'Ethiopian Orthodox Fasting']
      );
    }
  }

  LOGGER.log(`[FastingScheduler] Synced ${fastDates.size} fasting days for ${usersResult.rows.length} users`);
}

/**
 * Send fasting reminders for all users due today.
 * Reminder is sent `fasting_notice_hours` (default 18h) before the fast day.
 */
async function sendFastingReminders() {
  const reminderHoursResult = await query(
    `SELECT DISTINCT np.user_id, np.fasting_day_notice_hours, np.reminder_time
     FROM notification_preferences np
     WHERE np.fasting_reminders = true AND np.fasting_reminder_enabled = true`
  );

  for (const pref of reminderHoursResult.rows) {
    const noticeHours = pref.fasting_day_notice_hours || 18;
    const now = new Date();

    // Find fasting days for this user within the notice window
    const fromDate = new Date(now.getTime() + noticeHours * 60 * 60 * 1000);
    const toDate = new Date(now.getTime() + (noticeHours + 2) * 60 * 60 * 1000);
    const fromStr = fromDate.toISOString().slice(0, 10);
    const toStr = toDate.toISOString().slice(0, 10);

    const fastsResult = await query(
      `SELECT fs.id, fs.fasting_date, fs.fasting_name
       FROM fasting_schedules fs
       WHERE fs.user_id = $1
         AND fs.fasting_date BETWEEN $2 AND $3
         AND fs.is_notified = false`,
      [pref.user_id, fromStr, toStr]
    );

    for (const fast of fastsResult.rows) {
      const tokensResult = await query(
        `SELECT token FROM fcm_tokens WHERE user_id = $1 AND is_active = true`,
        [pref.user_id]
      );

      for (const tokenRow of tokensResult.rows) {
        await sendPushNotification({
          token: tokenRow.token,
          title: 'የጾም ማስታወሻ (Fasting Reminder)',
          body: `${fast.fasting_name} ነገ ነው። እባክዎን የማይበሉ ምግቦችን ይዘጋጁ!\nTomorrow is ${fast.fasting_name}. Prepare plant-based meals!`,
          data: { route: '/meal-plan', type: 'fasting_reminder', fastingDate: fast.fasting_date },
          userId: pref.user_id,
          notificationType: 'fasting_reminder',
        });
      }

      // Mark as notified
      await query(
        `UPDATE fasting_schedules
         SET is_notified = true, notification_sent_at = NOW()
         WHERE id = $1`,
        [fast.id]
      );
    }
  }
}

/**
 * Send daily meal logging reminders based on each user's preferred reminder time.
 * Runs every 15 min; sends only if the current time falls within the user's window.
 */
async function sendMealReminders() {
  const now = new Date();
  const timeStr = `${String(now.getUTCHours()).padStart(2, '0')}:${String(now.getUTCMinutes()).padStart(2, '0')}`;

  // Find users whose reminder_time is within this 15-min window
  const usersResult = await query(
    `SELECT np.user_id, np.reminder_time, u.language_preference
     FROM notification_preferences np
     JOIN users u ON u.id = np.user_id
     WHERE np.meal_reminders = true
       AND np.reminder_time BETWEEN 
           ($1::time - interval '15 minutes') 
           AND $1::time`,
    [timeStr]
  );

  for (const user of usersResult.rows) {
    const tokensResult = await query(
      `SELECT token FROM fcm_tokens WHERE user_id = $1 AND is_active = true`,
      [user.user_id]
    );

    const isAm = user.language_preference === 'am';
    const title = isAm ? 'የምግብ ማስታወሻ' : 'Meal Logging Reminder';
    const body = isAm
      ? 'ምግብዎን ሰርዝ። የግላይሴሚክ ሸክላ (GL) እየተከታተሉ ነው!'
      : 'Remember to log your meals. Keep tracking your Glycemic Load!';

    for (const tokenRow of tokensResult.rows) {
      await sendPushNotification({
        token: tokenRow.token,
        title,
        body,
        data: { route: '/meal-logging', type: 'meal_reminder' },
        userId: user.user_id,
        notificationType: 'meal_reminder',
      });
    }
  }
}

/**
 * Main scheduler entry — starts all cron jobs.
 */
function startScheduler() {
  LOGGER.log('[NotificationScheduler] Starting...');

  // Sync Ethiopian Orthodox fasting calendar every 6 hours
  cron.schedule('0 */6 * * *', async () => {
    try {
      await syncFastingSchedules();
    } catch (err) {
      LOGGER.error('[Scheduler] syncFastingSchedules error:', err.message);
    }
  });

  // Check and send fasting reminders every 15 minutes
  cron.schedule('*/15 * * * *', async () => {
    try {
      await sendFastingReminders();
    } catch (err) {
      LOGGER.error('[Scheduler] sendFastingReminders error:', err.message);
    }
  });

  // Check meal reminders every 15 minutes
  cron.schedule('*/15 * * * *', async () => {
    try {
      await sendMealReminders();
    } catch (err) {
      LOGGER.error('[Scheduler] sendMealReminders error:', err.message);
    }
  });

  LOGGER.log('[NotificationScheduler] All cron jobs registered.');
}

module.exports = { startScheduler, sendFastingReminders, sendMealReminders, syncFastingSchedules };