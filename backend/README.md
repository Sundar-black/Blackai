# Black AI Backend 🚀

A high-performance FastAPI backend for the Black AI project, integrated with MongoDB, Redis, and Qdrant.

## 🛠 Tech Stack
- **FastAPI**: Modern, fast web framework for Python.
- **MongoDB**: NoSQL database for flexible data storage (via `motor`).
- **Redis**: Fast caching for session management and performance (optional).
- **Qdrant**: Vector database for AI-powered semantic search.
- **Render**: Easy hosting and deployment.

## 🏗 Project Structure
```text
backend/
├── app/
│   ├── api/          # Route handlers
│   ├── core/         # Config and database connections
│   ├── models/       # Pydantic & Mongo models
│   ├── services/     # Business logic & external AI services
│   └── main.py       # Entry point
├── .env              # Environment variables
├── Dockerfile        # Containerization for deployment
└── requirements.txt  # Dependencies
```

## 🚀 Getting Started

### 1. Prerequisites
- Python 3.11+
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (Free tier)
- [Qdrant Cloud](https://cloud.qdrant.io/) (Free tier)
- [Upstash Redis](https://upstash.com/) (Free tier - optional)

### 2. Local Setup
1. **Create a virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Configure Environment:**
   - Copy `.env` template and fill in your credentials from MongoDB Atlas, Qdrant Cloud, etc.
4. **Run the server:**
   ```bash
   uvicorn app.main:app --reload
   ```

### 3. Deployment on Render
1. Create a new **Web Service** on Render.
2. Connect your GitHub repository.
3. Select **Docker** as the Runtime.
4. Add your environment variables from `.env` to the Render Dashboard.
5. Deploy!

## 🧪 API Endpoints
- **Root**: `GET /`
- **Health**: `GET /health`
- **Docs**: `GET /docs` (Interactive Swagger UI)

## 🔮 Future Scalability
- **AWS**: Migrate to ECS/EKS for orchestration, DocumentDB for Mongo, and ElastiCache for Redis.
