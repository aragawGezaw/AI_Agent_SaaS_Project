const jwt = require('jsonwebtoken');

/**
 * Authentication middleware to protect routes.
 * 1. Extract the Bearer token from the 'Authorization' header.
 * 2. Verify the token using process.env.JWT_SECRET.
 * 3. Attach the decoded user payload to req.user.
 * 4. Return 401 Unauthorized if no token is provided, and 403 Forbidden if the token is invalid or expired.
 *
 * Hardened: every code path either responds directly or calls next(). A malformed
 * Authorization header is treated as 401 (not as a thrown exception) so it cannot
 * bypass Express error handling and surface as an opaque 500.
 */
const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || req.headers['authorization'];

    if (!authHeader || typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Access token is missing or invalid'
      });
    }

    const parts = authHeader.split(' ');
    const token = parts[1];

    if (!token || typeof token !== 'string' || token.trim() === '') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Access token is missing'
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error('[AuthMiddleware] FATAL: process.env.JWT_SECRET is not set.');
      return res.status(500).json({
        error: 'Server misconfiguration',
        message: 'JWT_SECRET is not configured on the server'
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (jwtErr) {
      console.error('[AuthMiddleware] jwt.verify Error:', jwtErr.message);
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Token is invalid or expired'
      });
    }

    if (!decoded || typeof decoded !== 'object' || decoded.id === undefined) {
      console.error('[AuthMiddleware] Token decoded but missing user id:', decoded);
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Token payload is invalid'
      });
    }

    req.user = decoded;
    return next();
  } catch (err) {
    // Defensive catch-all: never let an unexpected error here become a silent 500.
    console.error('[AuthMiddleware] Unexpected error:', err);
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication failed'
    });
  }
};

module.exports = authMiddleware;
