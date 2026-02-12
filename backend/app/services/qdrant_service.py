from qdrant_client import QdrantClient
from qdrant_client.http import models
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class QdrantService:
    def __init__(self):
        self.client = QdrantClient(
            url=settings.QDRANT_URL,
            api_key=settings.QDRANT_API_KEY,
        )

    def create_collection(self, collection_name: str, vector_size: int):
        try:
            self.client.recreate_collection(
                collection_name=collection_name,
                vectors_config=models.VectorParams(size=vector_size, distance=models.Distance.COSINE),
            )
            logger.info(f"Collection {collection_name} created in Qdrant")
        except Exception as e:
            logger.error(f"Error creating collection: {e}")

    def upsert_vectors(self, collection_name: str, points: list):
        try:
            self.client.upsert(
                collection_name=collection_name,
                points=points
            )
        except Exception as e:
            logger.error(f"Error upserting vectors: {e}")

    def search_vectors(self, collection_name: str, query_vector: list, limit: int = 5):
        try:
            search_result = self.client.search(
                collection_name=collection_name,
                query_vector=query_vector,
                limit=limit
            )
            return search_result
        except Exception as e:
            logger.error(f"Error searching vectors: {e}")
            return []

qdrant_service = QdrantService()
