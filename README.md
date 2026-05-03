# John Casablancas Centers — Applicant Platform

A web application for managing applicants to JCC programs.

## Stack
- **Backend**: Node.js with Express
- **Frontend**: Static HTML/CSS/JavaScript (served by Express)
- **Database**: In-memory (PostgreSQL coming in a later class)

## Project Structure
```
john-casablancas-platform/
├── public/          # Static frontend files
│   └── index.html   # Main application UI
├── server.js        # Express API server
├── package.json     # Node.js project manifest
├── .gitignore       # Files excluded from version control
└── README.md        # This file
```

## Running Locally
```bash
npm install       # Install dependencies (first time only)
npm start         # Start the server on http://localhost:3000
```

## API Endpoints
| Method | Path               | Description              |
|--------|--------------------|--------------------------|
| GET    | /health            | Server health check      |
| GET    | /api/programs      | List all programs        |
| GET    | /api/applicants    | List all applicants      |
| POST   | /api/applicants    | Submit a new application |

### POST /api/applicants — Request Body
```json
{ "name": "Jane Doe", "email": "jane@example.com", "programId": 1 }
```
