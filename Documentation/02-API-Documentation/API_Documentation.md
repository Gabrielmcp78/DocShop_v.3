# DocShop v3 API Documentation

## API Overview

DocShop v3 includes a REST API server built with the Hummingbird framework, providing programmatic access to document operations, file system interactions, and shell command execution.

**Base URL**: `http://127.0.0.1:8080`  
**API Version**: v1  
**Content-Type**: `application/json`  
**Server Framework**: Hummingbird  

## Server Configuration

- **Host**: 127.0.0.1 (localhost only)
- **Port**: 8080
- **CORS**: Enabled for all origins
- **Allowed Methods**: GET, POST, OPTIONS
- **Allowed Headers**: Content-Type, Authorization
- **Middleware**: Request logging enabled

## Authentication

**Current Status**: No authentication required  
**Security Note**: API is designed for local development and testing

---

## Document API Endpoints

### 1. Search Documents

Search through indexed documents using query terms.

**Endpoint**: `POST /v1/documents/search`

#### Parameters

**Request Body** (JSON):
```json
{
  "query": "string"
}
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| query     | string | Yes      | Search term or phrase          |

#### Request Example

```bash
curl -X POST http://127.0.0.1:8080/v1/documents/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Swift documentation"
  }'
```

#### Response Examples

**Success Response** (200 OK):
```json
[
  {
    "id": "doc_123",
    "title": "Swift Language Guide",
    "url": "https://docs.swift.org/swift-book/",
    "contentType": "documentation",
    "createdAt": "2025-01-28T10:00:00Z",
    "lastModified": "2025-01-28T15:30:00Z",
    "tags": ["swift", "programming", "language"],
    "summary": "Comprehensive guide to Swift programming language",
    "wordCount": 15420,
    "complexity": "intermediate",
    "isIndexed": true
  }
]
```

**Empty Results** (200 OK):
```json
[]
```

#### Status Codes

| Code | Description                    |
|------|--------------------------------|
| 200  | Success - returns search results |
| 400  | Bad Request - invalid JSON     |
| 500  | Internal Server Error          |

---

## File System API Endpoints

### 1. Read File

Read the contents of a file from the local file system.

**Endpoint**: `POST /v1/files/read`

#### Parameters

**Request Body** (JSON):
```json
{
  "path": "string"
}
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| path      | string | Yes      | Absolute file path to read     |

#### Request Example

```bash
curl -X POST http://127.0.0.1:8080/v1/files/read \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/Users/example/Documents/readme.txt"
  }'
```

#### Response Examples

**Success Response** (200 OK):
```json
{
  "content": "# README\n\nThis is the content of the file.\n\n## Features\n- Document processing\n- AI analysis"
}
```

**File Not Found** (500 Internal Server Error):
```json
{
  "error": "File not found at path: /invalid/path.txt"
}
```

#### Status Codes

| Code | Description                    |
|------|--------------------------------|
| 200  | Success - file content returned |
| 400  | Bad Request - invalid JSON     |
| 500  | Internal Server Error - file access error |

### 2. Write File

Write content to a file in the local file system.

**Endpoint**: `POST /v1/files/write`

#### Parameters

**Request Body** (JSON):
```json
{
  "path": "string",
  "content": "string"
}
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| path      | string | Yes      | Absolute file path to write    |
| content   | string | Yes      | Content to write to file       |

#### Request Example

```bash
curl -X POST http://127.0.0.1:8080/v1/files/write \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/Users/example/Documents/output.txt",
    "content": "# New Document\n\nThis is new content."
  }'
```

#### Response Examples

**Success Response** (200 OK):
```json
{
  "success": true
}
```

**Write Failed** (500 Internal Server Error):
```json
{
  "success": false,
  "error": "Permission denied or invalid path"
}
```

#### Status Codes

| Code | Description                    |
|------|--------------------------------|
| 200  | Success - file written         |
| 400  | Bad Request - invalid JSON     |
| 500  | Internal Server Error - write failed |

---

## Shell API Endpoints

### 1. Execute Shell Command

Execute a shell command and return the output.

**Endpoint**: `POST /v1/shell/execute`

#### Parameters

**Request Body** (JSON):
```json
{
  "command": "string"
}
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| command   | string | Yes      | Shell command to execute       |

#### Request Example

```bash
curl -X POST http://127.0.0.1:8080/v1/shell/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "ls -la /Users"
  }'
```

#### Response Examples

**Success Response** (200 OK):
```json
{
  "stdout": "total 0\ndrwxr-xr-x   4 root  admin  128 Jan 28 10:00 .\ndrwxr-xr-x  20 root  wheel  640 Jan 28 09:30 ..\ndrwxrwxrwt   2 root  admin   64 Jan 28 10:00 Shared\ndrwxr-xr-x   5 user  staff  160 Jan 28 15:30 user",
  "stderr": "",
  "exitCode": 0
}
```

**Command Failed** (200 OK):
```json
{
  "stdout": "",
  "stderr": "ls: /invalid/path: No such file or directory",
  "exitCode": 1
}
```

#### Status Codes

| Code | Description                    |
|------|--------------------------------|
| 200  | Success - command executed (check exitCode) |
| 400  | Bad Request - invalid JSON     |
| 500  | Internal Server Error          |

---

## General API Information

### Response Format

All API responses use JSON format with pretty printing enabled for readability.

### Error Handling

- **4xx errors**: Client-side issues (malformed requests, missing parameters)
- **5xx errors**: Server-side issues (file access, processing errors)
- Error responses include descriptive messages when possible

### CORS Policy

The API includes CORS middleware with the following configuration:
- **Allow Origins**: All (`*`)
- **Allow Methods**: GET, POST, OPTIONS
- **Allow Headers**: Content-Type, Authorization

### Request Logging

All requests are logged with INFO level including:
- HTTP method and path
- Request timestamp
- Response status

### Rate Limiting

**Current Status**: No rate limiting implemented  
**Recommendation**: Implement rate limiting for production use

---

## Usage Examples

### Complete Workflow Example

```bash
# 1. Search for documents
curl -X POST http://127.0.0.1:8080/v1/documents/search \
  -H "Content-Type: application/json" \
  -d '{"query": "API documentation"}'

# 2. Read a configuration file
curl -X POST http://127.0.0.1:8080/v1/files/read \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/config.json"}'

# 3. Execute system command
curl -X POST http://127.0.0.1:8080/v1/shell/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "git status"}'

# 4. Write results to file
curl -X POST http://127.0.0.1:8080/v1/files/write \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/tmp/api_results.txt",
    "content": "API test completed successfully"
  }'
```

### JavaScript/Node.js Example

```javascript
const baseURL = 'http://127.0.0.1:8080/v1';

// Search documents
async function searchDocuments(query) {
  const response = await fetch(`${baseURL}/documents/search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query })
  });
  return await response.json();
}

// Read file
async function readFile(path) {
  const response = await fetch(`${baseURL}/files/read`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ path })
  });
  return await response.json();
}

// Execute command
async function executeCommand(command) {
  const response = await fetch(`${baseURL}/shell/execute`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ command })
  });
  return await response.json();
}
```

---

## Security Considerations

### Current Security Status
- **Local Access Only**: Server binds to localhost (127.0.0.1)
- **No Authentication**: No API keys or authentication required
- **Shell Access**: Full shell command execution available
- **File System Access**: Read/write access to entire file system

### Security Recommendations
1. **Add Authentication**: Implement API key or token-based auth
2. **Restrict Commands**: Whitelist allowed shell commands
3. **Path Validation**: Restrict file access to specific directories
4. **Rate Limiting**: Implement request rate limiting
5. **Input Sanitization**: Validate and sanitize all input parameters
6. **Audit Logging**: Log all API access and operations

### Production Deployment Notes
- Consider running API server on different port for production
- Implement HTTPS with proper certificates
- Add request validation middleware
- Set up monitoring and alerting for API usage

---

*Generated: 2025-01-28*  
*API Version: v1*  
*Server: Hummingbird Framework*