/**
 * Ethiopian Orthodox Fasting Calendar Service
 *
 * Ethiopian Orthodox Christians observe multiple fasting periods throughout the
 * year. The rules are cyclical and depend on the Ethiopian calendar. This
 * service returns the upcoming fasting days based on the Gregorian calendar.
 *
 * The major fasts:
 * - Great Lent (Hudade): 55 days before Easter (variable, mobile)
 * - Fast of the Apostles (Tsome Hawaryat): 10-40 days before Sene 12 (Eth. new year)
 * - Fast of Nineveh (Tsome Nehemiya): 3 days before Great Lent
 * - Assumption Fast (Tsome Filseta): Aug 1-14 (16 days)
 * - Christmas (Genna) Fast: Nov 25 - Jan 6 (40 days)
 * - Wed/Friday weekly fasts (year-round, except 50 days after Easter)
 * - Dormition / Tsige Fast: variable
 *
 * For SaaS simplicity, this implementation returns the fixed-date and
 * approximate movable fasts within a 60-day window from "today". Movable
 * fasts (Great Lent, Apostles, Nineveh) are approximated using the Coptic
 * Easter computation, which closely matches Ethiopian Easter (typically the
 * same day or one day apart).
 */

// Coptic Easter date (Julian-based) for a given Gregorian year.
// Returns Date object in Gregorian calendar.
function computeCopticEaster(year) {
  const a = year % 4;
  const b = year % 7;
  const c = year % 19;
  const d = (19 * c + 15) % 30;
  const e = (2 * a + 4 * b - d + 34) % 7;
  const month = Math.floor((d + e + 114) / 31); // 3=Mar, 4=Apr
  const day = ((d + e + 114) % 31) + 1;
  // Coptic Easter is in April or May
  return new Date(Date.UTC(year, month - 1, day + 12)); // +12 to map to Gregorian
}

// Add days to a date and return ISO yyyy-mm-dd
function addDays(date, days) {
  const d = new Date(date);
  d.setUTCDate(d.getUTCDate() + days);
  return d;
}

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

/**
 * Return an array of upcoming fasting dates within the next `daysAhead` days.
 * Each entry: { date: 'YYYY-MM-DD', name: '<fasting name>' }
 */
function getUpcomingFastingDays(startDate = new Date(), daysAhead = 60) {
  const today = new Date(Date.UTC(
    startDate.getUTCFullYear(),
    startDate.getUTCMonth(),
    startDate.getUTCDate(),
  ));
  const horizon = addDays(today, daysAhead);

  const fasts = [];
  const year = today.getUTCFullYear();

  // Coptic Easter for this year and next year
  const easter = computeCopticEaster(year);
  const easterNext = computeCopticEaster(year + 1);

  // Great Lent: 55 days before Easter (excluding Saturdays/Sundays, but
  // for calendar reminders we mark every day of the period)
  const greatLentStart = addDays(easter, -55);
  for (let i = 0; i < 55; i++) {
    const d = addDays(greatLentStart, i);
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Great Lent (Hudade)' });
    }
  }

  // Fast of Nineveh: 3 days (Mon-Wed) before Great Lent
  const ninevehStart = addDays(greatLentStart, -3);
  for (let i = 0; i < 3; i++) {
    const d = addDays(ninevehStart, i);
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Fast of Nineveh (Tsome Nehemiya)' });
    }
  }

  // Assumption Fast (Tsome Filseta): Aug 1-14
  for (let day = 1; day <= 14; day++) {
    const d = new Date(Date.UTC(year, 7, day)); // Aug = month 7
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Assumption Fast (Tsome Filseta)' });
    }
  }

  // Christmas (Genna) Fast: Nov 25 - Jan 6 (spans year boundary)
  for (let day = 25; day <= 30; day++) {
    const d = new Date(Date.UTC(year, 10, day)); // Nov = month 10
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Genna Fast (Christmas)' });
    }
  }
  for (let day = 1; day <= 6; day++) {
    const d = new Date(Date.UTC(year, 11, day)); // Dec
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Genna Fast (Christmas)' });
    }
  }
  // Jan 1-6 of next year
  for (let day = 1; day <= 6; day++) {
    const d = new Date(Date.UTC(year + 1, 0, day));
    if (d >= today && d <= horizon) {
      fasts.push({ date: isoDate(d), name: 'Genna Fast (Christmas)' });
    }
  }

  // Weekly Wed/Fri fasts (year-round, except Paschal 50 days after Easter)
  const paschalEnd = addDays(easter, 50);
  const paschalEndNext = addDays(easterNext, 50);
  for (let i = 0; i <= daysAhead; i++) {
    const d = addDays(today, i);
    const dow = d.getUTCDay(); // 0=Sun, 3=Wed, 5=Fri
    if (dow !== 3 && dow !== 5) continue;
    // Skip Paschal period
    if ((d >= easter && d <= paschalEnd) || (d >= easterNext && d <= paschalEndNext)) continue;
    fasts.push({ date: isoDate(d), name: 'Weekly Fast (Wed/Friday)' });
  }

  // Sort by date and de-duplicate (same date could appear in multiple categories)
  const map = new Map();
  for (const f of fasts) {
    if (!map.has(f.date)) {
      map.set(f.date, f);
    } else {
      // Combine names
      const existing = map.get(f.date);
      map.set(f.date, { date: f.date, name: `${existing.name}; ${f.name}` });
    }
  }

  return Array.from(map.values()).sort((a, b) => a.date.localeCompare(b.date));
}

module.exports = {
  getUpcomingFastingDays,
  computeCopticEaster,
};
