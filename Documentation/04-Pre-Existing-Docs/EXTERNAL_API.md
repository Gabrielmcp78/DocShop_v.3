# DocShop External Agent API v1

This document defines the version 1 API for interacting with the DocShop environment. External agent systems can use this API to access and manipulate resources within a DocShop project.

## Authentication

All API requests must include a valid bearer token in the `Authorization` header.

`Authorization: Bearer <YOUR_API_TOKEN>`

## Endpoints

### Documents

#### `POST /v1/documents/search`

Searches the document library.

**Body:**

```json
{
  "query": "Your search query"
}
```

**Response:**

```json
[
  {
    "id": "...",
    "title": "...",
    "sourceURL": "...",
    "filePath": "..."
  }
]
```

### Filesystem

#### `POST /v1/files/read`

Reads the content of a file.

**Body:**

```json
{
  "path": "/path/to/file/within/project"
}
```

**Response:**

```json
{
  "content": "..."
}
```

#### `POST /v1/files/write`

Writes content to a file.

**Body:**

```json
{
  "path": "/path/to/file/within/project",
  "content": "..."
}
```

**Response:**

```json
{
  "success": true
}
```

### Shell

#### `POST /v1/shell/execute`

Executes a shell command in the project's root directory.

**Body:**

```json
{
  "command": "ls -l"
}
```

**Response:**

```json
{
  "stdout": "...",
  "stderr": "...",
  "exitCode": 0
}
```
