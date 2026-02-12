# BlackAI Backend (Node.js)

Production-ready backend for the BlackAI Flutter application.

## Tech Stack
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB Atlas (via Mongoose)
- **Authentication**: JSON Web Token (JWT)
- **Security**: bcryptjs, helmet, cors, express-validator

## Getting Started

### Prerequisites
- Node.js installed
- MongoDB Atlas account and connection string

### Installation

1. Navigate to the backend directory:
   ```bash
   cd backend-node
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure environment variables:
   - Rename `.env.example` (or create `.env`) and fill in your details:
     ```env
     PORT=5000
     MONGODB_URI=your_mongodb_atlas_uri
     JWT_SECRET=your_jwt_secret
     NODE_ENV=development
     ```

### Running the Server
- Development mode (with nodemon):
  ```bash
  npm run dev
  ```
- Production mode:
  ```bash
  npm start
  ```

## API Endpoints

### Authentication
- `POST /api/auth/signup`: Create a new user account.
- `POST /api/auth/login`: Authenticate user and get JWT.

### User Management (Admin Only)
- `GET /api/users`: List all registered users.
- `POST /api/users`: Manually create a user.
- `PUT /api/users/:id/block`: Toggle user block status.
- `DELETE /api/users/:id`: Remove a user.

### AI Chat
- `GET /api/chat/sessions`: Get all chat history for authenticated user.
- `POST /api/chat/sessions`: Create a new chat session.
- `POST /api/chat/sessions/:id/messages/stream`: Send message and stream AI response.
- `DELETE /api/chat/sessions/:id`: Delete a chat session.

## Security Features
- **Password Hashing**: Uses bcrypt with a salt factor of 10.
- **JWT Protection**: Secured routes require a valid Bearer token.
- **Role-Based Access**: Specialized routes restricted to 'admin' role.
- **Blocking System**: Blocked users cannot log in or access protected routes.
- **Security Headers**: Uses Helmet to set various HTTP headers for security.
- **CORS**: Cross-Origin Resource Sharing enabled for frontend integration.
