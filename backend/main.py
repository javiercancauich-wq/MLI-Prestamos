from fastapi import FastAPI
from app.database import Base, engine
from app import models # Asegura que AQLAlchemy registre todas las tablas
from app.routers import auth, loans

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="MLI Prestamos API",
    description="Backend para gestion de prestamos (Admin y Cliente)",
    version="0.1.0",
)

app.include_router(auth.router)
app.include_router(loans.router)


@app.get("/")
def root():
    return {"app": "MLI Prestamos", "status": "activo"}