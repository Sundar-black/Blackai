from app.core.config import settings
from app.core.database import db
from datetime import datetime
import openai
import logging
import uuid
from typing import List, Dict, AsyncGenerator
import json
import asyncio
from concurrent.futures import ThreadPoolExecutor

logger = logging.getLogger(__name__)

# Configure OpenAI (synchronous client)
client = None

def get_openai_client():
    global client
    if client is None:
        client = openai.OpenAI(
            api_key=settings.OPENAI_API_KEY,
            base_url="https://openrouter.ai/api/v1" if settings.OPENAI_API_KEY.startswith("sk-or-") else None
        )
    return client

# Create a ThreadPoolExecutor for run_in_executor
executor = ThreadPoolExecutor(max_workers=10)

class AiService:
    @staticmethod
    async def get_embedding(text: str) -> List[float]:
        try:
            # Note: OpenRouter doesn't support embeddings well, you might need OpenAI for this
            # Or use a local model / separate service.
            # providing a dummy embedding for now to prevent crashes if not configured
            return [0.0] * 1536 
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []

    @staticmethod
    async def chat_completion(messages: List[Dict], model: str = "openai/gpt-3.5-turbo") -> str:
        try:
            loop = asyncio.get_event_loop()
            
            def sync_completion():
                _client = get_openai_client()
                response = _client.chat.completions.create(
                    model=model,
                    messages=messages,
                )
                return response.choices[0].message.content

            return await loop.run_in_executor(executor, sync_completion)
        except Exception as e:
            logger.error(f"Chat completion error: {e}")
            return "I apologize, but I encountered an error processing your request."

    @staticmethod
    async def chat_completion_stream(messages: List[Dict], model: str = "openai/gpt-3.5-turbo") -> AsyncGenerator[str, None]:
        try:
            loop = asyncio.get_event_loop()
            
            def sync_stream():
                _client = get_openai_client()
                return _client.chat.completions.create(
                    model=model,
                    messages=messages,
                    stream=True,
                )

            # Get the synchronous generator in a thread
            stream = await loop.run_in_executor(executor, sync_stream)

            # Iterate over the sync generator in a way that yields to asyncio loop
            # Check for next chunk in thread to avoid blocking
            iterator = iter(stream)
            
            while True:
                def get_next():
                    try:
                        return next(iterator)
                    except StopIteration:
                        return None
                
                chunk = await loop.run_in_executor(executor, get_next)
                if chunk is None:
                    break
                    
                content = chunk.choices[0].delta.content
                if content:
                    yield content

        except Exception as e:
            logger.error(f"Streaming error: {e}")
            yield f"Error: {str(e)}"

    @staticmethod
    async def generate_title(first_message: str) -> str:
        messages = [
            {"role": "system", "content": "You are a helpful assistant. Generate a short, 3-5 word title for this chat based on the user's first message. Do not use quotes."},
            {"role": "user", "content": first_message}
        ]
        title = await AiService.chat_completion(messages)
        return title.strip().replace('"', '')
