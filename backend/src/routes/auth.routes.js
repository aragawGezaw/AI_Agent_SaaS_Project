const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');

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

/**
 * @route POST /api/auth/login
 * @desc Authenticate user and get token
 * @access Public
 */
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};

    // 1. Validate required fields
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Bad Request', 
        message: 'Email and password are required' 
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // 2. Query user by email
    const userResult = await query(
      'SELECT id, email, password_hash, full_name, preferred_language, created_at, updated_at FROM users WHERE email = $1',
      [normalizedEmail]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Invalid email or password' 
      });
    }

    const user = userResult.rows[0];

    // 3. Compare hashed password
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ 
        error: 'Unauthorized', 
        message: 'Invalid email or password' 
      });
    }

    // 4. Generate JWT token
    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET || 'fallback_secret_change_me',
      { expiresIn: '24h' }
    );

    // 5. Prepare user profile object (excluding password_hash)
    const { password_hash, ...userProfile } = user;

    return res.status(200).json({
      message: 'Login successful',
      token,
      user: userProfile
    });

  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/auth/me
 * @desc Get current user's profile
 * @access Private
 */
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const userResult = await query(
      'SELECT id, email, full_name, preferred_language, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];

    return res.status(200).json(user);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
