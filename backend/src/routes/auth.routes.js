const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { query } = require('../db/index.js');

/**
 * @route POST /api/auth/register
 * @desc Register a new user
 * @access Public
 */
router.post('/register', async (req, res, next) => {
  try {
    const { email, password, full_name, preferred_language } = req.body || {};

    // 1. Validate inputs
    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'Invalid input', message: 'Email is required and must be a string' });
    }
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid input', message: 'Please provide a valid email address' });
    }

    if (!password || typeof password !== 'string') {
      return res.status(400).json({ error: 'Invalid input', message: 'Password is required and must be a string' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Invalid input', message: 'Password must be at least 6 characters long' });
    }

    if (!full_name || typeof full_name !== 'string' || !full_name.trim()) {
      return res.status(400).json({ error: 'Invalid input', message: 'Full name is required and must be a non-empty string' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // 2. Check for existing user
    const existingUserResult = await query('SELECT id FROM users WHERE email = $1', [normalizedEmail]);
    if (existingUserResult.rows.length > 0) {
      return res.status(409).json({ error: 'Conflict', message: 'A user with this email address already exists' });
    }

    // 3. Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // 4. Insert new user
    const insertQuery = `
      INSERT INTO users (email, password_hash, full_name, preferred_language)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, full_name, preferred_language, created_at, updated_at
    `;
    
    // Default to 'am' if preferred_language is not provided or invalid
    const lang = (preferred_language && typeof preferred_language === 'string') ? preferred_language : 'am';
    
    const insertResult = await query(insertQuery, [normalizedEmail, passwordHash, full_name.trim(), lang]);
    const newUser = insertResult.rows[0];

    return res.status(201).json({
      message: 'User registered successfully',
      user: newUser
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
