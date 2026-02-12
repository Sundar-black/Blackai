import openai
from app.core.config import settings
from app.services.qdrant_service import qdrant_service
from qdrant_client.http import models as qmodels
import uuid
import logging
import asyncio

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        openai.api_key = self.api_key
        if self.api_key.startswith("sk-or-"):
            openai.api_base = "https://openrouter.ai/api/v1"
            
        if self.api_key == "sk-...":
            logger.warning("OpenAI API Key is a placeholder. Chat will fail.")
            
        self.collection_name = "chat_history"

    async def get_embedding(self, text: str):
        try:
            model = "openai/text-embedding-3-small" if self.api_key.startswith("sk-or-") else "text-embedding-3-small"
            # Synchronous call wrapped in run_in_executor
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None, 
                lambda: openai.Embedding.create(input=text, model=model)
            )
            return response['data'][0]['embedding']
        except Exception as e:
            logger.error(f"Embedding error: {e}")
            # Fallback zero vector if embedding fails (to allow chat to continue without context)
            return [0.0] * 1536

    async def chat_completion(self, messages: list):
        try:
            model = "google/gemini-2.0-flash-001" if self.api_key.startswith("sk-or-") else "gpt-3.5-turbo"
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: openai.ChatCompletion.create(
                    model=model,
                    messages=messages,
                )
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"Chat completion error: {e}")
            return f"Error: AI Service failure. {str(e)}"

    async def chat_completion_stream(self, messages: list):
        try:
            model = "google/gemini-2.0-flash-001" if self.api_key.startswith("sk-or-") else "gpt-3.5-turbo"
            loop = asyncio.get_event_loop()
            
            # Streaming in executor is tricky, we'll use a generator
            def get_stream():
                return openai.ChatCompletion.create(
                    model=model,
                    messages=messages,
                    stream=True
                )
            
            response = await loop.run_in_executor(None, get_stream)
            
            for chunk in response:
                if 'choices' in chunk and len(chunk['choices']) > 0:
                    delta = chunk['choices'][0].get('delta', {})
                    if 'content' in delta:
                        yield delta['content']
        except Exception as e:
            logger.error(f"Streaming error: {e}")
            yield f"Error in AI stream: {str(e)}"

    async def save_context(self, user_id: str, text: str, metadata: dict):
        embedding = await self.get_embedding(text)
        point_id = str(uuid.uuid4())
        qdrant_service.upsert_vectors(
            collection_name=self.collection_name,
            points=[
                qmodels.PointStruct(
                    id=point_id,
                    vector=embedding,
                    payload={"user_id": user_id, "text": text, **metadata}
                )
            ]
        )

    async def search_context(self, user_id: str, query: str, limit: int = 3):
        try:
            query_vector = await self.get_embedding(query)
            # Use search_vectors instead of direct client access
            search_result = qdrant_service.search_vectors(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=limit
            )
            return [hit.payload["text"] for hit in search_result]
        except Exception as e:
            logger.warning(f"Search context failed: {e}")
            return []

ai_service = AIService()
