# API Documentation

## 📋 Contents

### `API_Documentation.md` 🆕
**Generated**: 2025-01-28 by Claude Code Analysis  
**Type**: REST API Documentation  
**Status**: Complete  

**Description**: Comprehensive REST API documentation including:
- **Server Configuration**: Hummingbird framework, CORS, middleware
- **Document API**: Search functionality with query parameters
- **File System API**: Read/write operations for local files
- **Shell API**: Command execution with output capture
- **Authentication**: Current security status and recommendations
- **Usage Examples**: cURL commands, JavaScript samples
- **Status Codes**: Complete HTTP response codes
- **Security Considerations**: Current state and production recommendations

**Base URL**: `http://127.0.0.1:8080/v1`  
**Framework**: Hummingbird (Swift)  
**Endpoints**: 4 main endpoints across 3 API groups

## 🔧 API Overview

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/documents/search` | POST | Search indexed documents |
| `/v1/files/read` | POST | Read file contents |
| `/v1/files/write` | POST | Write file contents |
| `/v1/shell/execute` | POST | Execute shell commands |

## 🎯 Usage

**For API Integration**:
1. Review endpoint specifications in `API_Documentation.md`
2. Test with provided cURL examples
3. Implement using JavaScript/Node.js samples

**For Development**:
- Server runs on localhost:8080
- No authentication required (development mode)
- CORS enabled for web development

## ⚠️ Security Notes

- **Development Only**: No authentication currently implemented
- **Local Access**: Server binds to localhost only
- **Production Considerations**: Authentication, rate limiting, input validation needed

## 🔗 Related Files

- **Server Implementation**: `../../DocShop/API/APIServer.swift`
- **Document API**: `../../DocShop/API/DocumentAPI.swift`
- **File System API**: `../../DocShop/API/FilesystemAPI.swift`
- **Shell API**: `../../DocShop/API/ShellAPI.swift`

---

*Generated on 2025-01-28*