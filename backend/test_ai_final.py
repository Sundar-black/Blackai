import asyncio
import os
from dotenv import load_dotenv
from openai import AsyncOpenAI

load_dotenv()

async def test_ai_final():
    api_key = os.getenv("OPENAI_API_KEY")
    base_url = "https://openrouter.ai/api/v1" if api_key.startswith("sk-or-") else None
    client = AsyncOpenAI(api_key=api_key, base_url=base_url)
    
    with open("ai_test_results.txt", "w") as f:
        f.write(f"Key Prefix: {api_key[:10]}\n")
        
        # Chat
        try:
            model = "google/gemini-2.0-flash-001" if api_key.startswith("sk-or-") else "gpt-3.5-turbo"
            resp = await client.chat.completions.create(model=model, messages=[{"role": "user", "content": "HI"}])
            f.write(f"Chat Success: {resp.choices[0].message.content}\n")
        except Exception as e:
            f.write(f"Chat Error: {e}\n")
            
        # Embeddings
        try:
            model = "openai/text-embedding-3-small" if api_key.startswith("sk-or-") else "text-embedding-3-small"
            resp = await client.embeddings.create(input="TEST", model=model)
            f.write(f"Embedding Success: {len(resp.data[0].embedding)}\n")
        except Exception as e:
            f.write(f"Embedding Error: {e}\n")

if __name__ == "__main__":
    asyncio.run(test_ai_final())
