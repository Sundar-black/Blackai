import asyncio
import os
from dotenv import load_dotenv
from openai import AsyncOpenAI

load_dotenv()

async def test_ai():
    api_key = os.getenv("OPENAI_API_KEY")
    print(f"Testing Key: {api_key[:10]}...")
    
    base_url = "https://openrouter.ai/api/v1" if api_key.startswith("sk-or-") else None
    client = AsyncOpenAI(api_key=api_key, base_url=base_url)
    
    print("\n--- Testing Chat ---")
    try:
        response = await client.chat.completions.create(
            model="google/gemini-2.0-flash-exp",
            messages=[{"role": "user", "content": "Say hello!"}]
        )
        print(f"Chat Response: {response.choices[0].message.content}")
    except Exception as e:
        print(f"Chat failed: {e}")

    print("\n--- Testing Embeddings ---")
    try:
        model = "openai/text-embedding-3-small" if api_key.startswith("sk-or-") else "text-embedding-3-small"
        print(f"Using embedding model: {model}")
        response = await client.embeddings.create(
            input="Hello world",
            model=model
        )
        print(f"Embedding success! Vector length: {len(response.data[0].embedding)}")
    except Exception as e:
        print(f"Embeddings failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_ai())
