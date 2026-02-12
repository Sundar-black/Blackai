import asyncio
import os
from dotenv import load_dotenv
from openai import AsyncOpenAI
import logging

load_dotenv()
logging.basicConfig(level=logging.INFO)

async def test_ai_updated():
    api_key = os.getenv("OPENAI_API_KEY")
    print(f"Testing Key: {api_key[:15]}...")
    
    base_url = "https://openrouter.ai/api/v1" if api_key.startswith("sk-or-") else None
    client = AsyncOpenAI(api_key=api_key, base_url=base_url)
    
    print("\n--- Testing Chat (Gemini 2.0 Flash) ---")
    try:
        # OpenRouter model name
        model = "google/gemini-2.0-flash-001" if api_key.startswith("sk-or-") else "gpt-3.5-turbo"
        print(f"Using model: {model}")
        response = await client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say 'AI IS WORKING' and nothing else."}]
        )
        print(f"Chat Response: {response.choices[0].message.content}")
    except Exception as e:
        print(f"Chat failed: {e}")

    print("\n--- Testing Embeddings (OpenRouter) ---")
    try:
        model = "openai/text-embedding-3-small" if api_key.startswith("sk-or-") else "text-embedding-3-small"
        print(f"Using embedding model: {model}")
        response = await client.embeddings.create(
            input="Search query test",
            model=model
        )
        print(f"Embedding vector length: {len(response.data[0].embedding)}")
    except Exception as e:
        print(f"Embeddings failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_ai_updated())
