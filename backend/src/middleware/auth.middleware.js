const jwt = require('jsonwebtoken');

/**
 * Authentication middleware to protect routes.
 * 1. Extract the Bearer token from the 'Authorization' header.
 * 2. Verify the token using process.env.JWT_SECRET.
 * 3. Attach the decoded user payload to req.user.
 * 4. Return 401 Unauthorized if no token is provided, and 403 Forbidden if the token is invalid or expired.
 */
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Access token is missing or invalid'
    });
  }

  const token = authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Access token is missing'
    });
  }

  console.log('[AuthMiddleware] Incoming Auth Header:', authHeader);
  console.log('[AuthMiddleware] process.env.JWT_SECRET:', process.env.JWT_SECRET || 'supersecretkey');

  jwt.verify(token, process.env.JWT_SECRET || 'supersecretkey', (err, decoded) => {
    if (err) {
      console.error('[AuthMiddleware] jwt.verify Error:', err);
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Token is invalid or expired'
      });
    }

    console.log('[AuthMiddleware] Decoded payload:', decoded);
    req.user = decoded;
    next();
  });
};

module.exports = authMiddleware;
