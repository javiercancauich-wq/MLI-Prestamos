from fastapi import FastAPI
from app.database import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="MLI Prestamos API",
    description="Backend para gestion de prestamos (Admin y Cliente)",
    version="0.1.0",
)


@app.get("/")
def root():
    return {"app": "MLI Prestamos", "status": "activo"}