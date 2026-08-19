const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');
const { generateAgentResponse } = require('../services/ai.service.js');

/**
 * @route POST /api/chat/sessions
 * @desc Create a new chat session
 * @access Private
 */
router.post('/sessions', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { title = 'New Conversation', agent_type = 'nutrition_advisor' } = req.body || {};

    const insertQuery = `
      INSERT INTO chat_sessions (user_id, title, agent_type)
      VALUES ($1, $2, $3)
      RETURNING id, user_id, title, agent_type, created_at, updated_at
    `;

    const result = await query(insertQuery, [userId, title, agent_type]);

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/chat/sessions
 * @desc Get all chat sessions for the current user
 * @access Private
 */
router.get('/sessions', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT id, title, agent_type, created_at, updated_at FROM chat_sessions WHERE user_id = $1 ORDER BY updated_at DESC',
      [userId]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/chat/sessions/:sessionId/messages
 * @desc Add a message to a chat session
 * @access Private
 */
router.post('/sessions/:sessionId/messages', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { sessionId } = req.params;
    const { sender, content, metadata = {} } = req.body || {};

    // Validate sessionId exists and belongs to user
    const sessionCheck = await query(
      'SELECT id FROM chat_sessions WHERE id = $1 AND user_id = $2',
      [sessionId, userId]
    );

    if (sessionCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Chat session not found or does not belong to user'
      });
    }

    // Validate sender
    if (!['user', 'agent', 'system'].includes(sender)) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Sender must be user, agent, or system'
      });
    }

    if (!content || typeof content !== 'string' || content.trim() === '') {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Content is required and must be a non-empty string'
      });
    }

    // Insert message
    const insertMessageQuery = `
      INSERT INTO chat_messages (session_id, sender, content, metadata)
      VALUES ($1, $2, $3, $4)
      RETURNING id, session_id, sender, content, metadata, created_at
    `;

    const messageResult = await query(insertMessageQuery, [
      sessionId,
      sender,
      content.trim(),
      JSON.stringify(metadata)
    ]);

    // Update session updated_at
    await query(
      'UPDATE chat_sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = $1',
      [sessionId]
    );

    return res.status(201).json(messageResult.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/chat/sessions/:sessionId/messages
 * @desc Get message history for a chat session
 * @access Private
 */
router.get('/sessions/:sessionId/messages', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { sessionId } = req.params;

    // Verify session belongs to user
    const sessionCheck = await query(
      'SELECT id FROM chat_sessions WHERE id = $1 AND user_id = $2',
      [sessionId, userId]
    );

    if (sessionCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Chat session not found or does not belong to user'
      });
    }

    // Query messages
    const messagesResult = await query(
      'SELECT id, sender, content, metadata, created_at FROM chat_messages WHERE session_id = $1 ORDER BY created_at ASC',
      [sessionId]
    );

    return res.status(200).json(messagesResult.rows);
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/chat/sessions/:sessionId/generate
 * @desc Generate an AI response for a chat session
 * @access Private
 */
router.post('/sessions/:sessionId/generate', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { sessionId } = req.params;
    const { content } = req.body || {};

    if (!content || typeof content !== 'string' || content.trim() === '') {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Content is required and must be a non-empty string'
      });
    }

    // 1. Validate sessionId exists and belongs to user
    const sessionCheck = await query(
      'SELECT id FROM chat_sessions WHERE id = $1 AND user_id = $2',
      [sessionId, userId]
    );

    if (sessionCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Chat session not found or does not belong to user'
      });
    }

    // 2. Save user message to 'chat_messages'
    const insertUserMessageQuery = `
      INSERT INTO chat_messages (session_id, sender, content)
      VALUES ($1, 'user', $2)
      RETURNING id, session_id, sender, content, metadata, created_at
    `;
    const userMessageResult = await query(insertUserMessageQuery, [sessionId, content.trim()]);
    const userMessage = userMessageResult.rows[0];

    // 3. Call generateAgentResponse service
    const agentResponseText = await generateAgentResponse({
      userId,
      sessionId,
      promptText: content.trim()
    });

    // 4. Save the returned agent message to 'chat_messages'
    const insertAgentMessageQuery = `
      INSERT INTO chat_messages (session_id, sender, content)
      VALUES ($1, 'agent', $2)
      RETURNING id, session_id, sender, content, metadata, created_at
    `;
    const agentMessageResult = await query(insertAgentMessageQuery, [sessionId, agentResponseText]);
    const agentMessage = agentMessageResult.rows[0];

    // 5. Update session updated_at
    await query(
      'UPDATE chat_sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = $1',
      [sessionId]
    );

    // 6. Return both user and agent message objects
    return res.status(200).json({
      userMessage,
      agentMessage
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
