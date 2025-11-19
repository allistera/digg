# JWT Authentication

This API uses JWT (JSON Web Token) authentication for securing endpoints.

## Overview

The authentication system provides:
- **Access Tokens**: Short-lived tokens (1 hour) for API requests
- **Refresh Tokens**: Long-lived tokens (7 days) for obtaining new access tokens
- **Bearer Token Authentication**: Standard `Authorization: Bearer <token>` header

## Authentication Endpoints

### Register a New User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "user": {
    "username": "johndoe",
    "email": "john@example.com",
    "password": "securepassword",
    "password_confirmation": "securepassword"
  }
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "karma_score": 0,
    "created_at": "2025-11-19T12:00:00.000Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepassword"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "karma_score": 100,
    "avatar_url": null,
    "is_verified": false
  },
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### Refresh Access Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### Get Current User
```http
GET /api/v1/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "karma_score": 100,
  "avatar_url": null,
  "bio": "Developer and tech enthusiast",
  "website_url": "https://example.com",
  "is_verified": false,
  "created_at": "2025-11-19T12:00:00.000Z",
  "followers_count": 10,
  "following_count": 5
}
```

## Using Authentication in API Requests

### Making Authenticated Requests

Include the access token in the `Authorization` header with the `Bearer` scheme:

```http
GET /api/v1/articles
Authorization: Bearer <your_access_token>
```

### Example with cURL
```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "username": "johndoe",
      "email": "john@example.com",
      "password": "securepassword",
      "password_confirmation": "securepassword"
    }
  }'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepassword"
  }'

# Use access token for authenticated requests
curl -X POST http://localhost:3000/api/v1/articles \
  -H "Authorization: Bearer <your_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "article": {
      "title": "My Article Title",
      "url": "https://example.com/article",
      "category_id": 1
    }
  }'
```

### Example with JavaScript/Fetch
```javascript
// Register
const registerResponse = await fetch('http://localhost:3000/api/v1/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    user: {
      username: 'johndoe',
      email: 'john@example.com',
      password: 'securepassword',
      password_confirmation: 'securepassword'
    }
  })
});

const { access_token, refresh_token } = await registerResponse.json();

// Store tokens (e.g., in localStorage or secure storage)
localStorage.setItem('access_token', access_token);
localStorage.setItem('refresh_token', refresh_token);

// Make authenticated requests
const response = await fetch('http://localhost:3000/api/v1/articles', {
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('access_token')}`
  }
});
```

## Token Management

### Access Token Expiration
Access tokens expire after **1 hour**. When an access token expires, you'll receive a `401 Unauthorized` response.

### Refreshing Tokens
When your access token expires, use the refresh token to obtain a new access token:

```javascript
async function refreshAccessToken() {
  const refreshToken = localStorage.getItem('refresh_token');

  const response = await fetch('http://localhost:3000/api/v1/auth/refresh', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      refresh_token: refreshToken
    })
  });

  if (response.ok) {
    const { access_token, refresh_token } = await response.json();
    localStorage.setItem('access_token', access_token);
    localStorage.setItem('refresh_token', refresh_token);
    return access_token;
  } else {
    // Refresh token expired, redirect to login
    window.location.href = '/login';
  }
}
```

### Automatic Token Refresh
Implement automatic token refresh in your HTTP client:

```javascript
async function fetchWithAuth(url, options = {}) {
  const accessToken = localStorage.getItem('access_token');

  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  // If unauthorized, try to refresh token
  if (response.status === 401) {
    const newToken = await refreshAccessToken();

    // Retry request with new token
    return fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${newToken}`
      }
    });
  }

  return response;
}
```

## Security Best Practices

1. **Store tokens securely**: Never store tokens in localStorage in production. Use httpOnly cookies or secure storage mechanisms.

2. **Use HTTPS**: Always use HTTPS in production to prevent token interception.

3. **Token expiration**: Access tokens expire after 1 hour, refresh tokens after 7 days. Implement proper token refresh logic.

4. **Logout**: Clear tokens from storage when user logs out.

5. **Don't expose tokens**: Never log tokens or include them in URLs.

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

### 422 Unprocessable Entity (Validation Error)
```json
{
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

## Migration from Session-Based Auth

If you were previously using session-based authentication:

1. **Old approach** (deprecated):
   ```http
   POST /api/v1/users
   Cookie: _session_id=abc123
   ```

2. **New approach** (recommended):
   ```http
   POST /api/v1/auth/login
   Authorization: Bearer <jwt_token>
   ```

The session-based authentication is deprecated but still supported for backward compatibility. Please migrate to JWT authentication for better scalability and stateless architecture.
