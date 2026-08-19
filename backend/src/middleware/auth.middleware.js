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

  jwt.verify(token, process.env.JWT_SECRET || 'supersecretkey', (err, decoded) => {
    if (err) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Token is invalid or expired'
      });
    }

    req.user = decoded;
    next();
  });
};

module.exports = authMiddleware;
