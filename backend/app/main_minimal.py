from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Minimal backend is running properly"}

@app.get("/health")
def health():
    return {"status": "healthy"}
