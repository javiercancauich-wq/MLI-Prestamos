import hashlib
import os
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Borrower

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Credenciales de Admin para pruebas/MVP (puedes cambiarlas con variables de entorno)
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")


class LoginRequest(BaseModel):
    role: str  # "admin" o "client"
    identifier: str
    password: str


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    role = payload.role.strip().lower()
    identifier = payload.identifier.strip()
    password = payload.password

    if role == "admin":
        if identifier.lower() != ADMIN_USERNAME.lower() or password != ADMIN_PASSWORD:
            raise HTTPException(
                status_code=401,
                detail="Credenciales de administrador incorrectas",
            )
        return {
            "role": "admin",
            "name": "Administrador MLI",
            "username": ADMIN_USERNAME,
            "message": "Inicio de sesión de administrador exitoso",
        }

    if role == "client":
        borrower = (
            db.query(Borrower)
            .filter(Borrower.username == identifier.lower())
            .first()
        )
        if not borrower or borrower.hashed_password != hash_password(password):
            raise HTTPException(
                status_code=401,
                detail="Usuario o contraseña de cliente incorrectos",
            )
        return {
            "role": "client",
            "borrower_id": borrower.id,
            "name": borrower.full_name,
            "username": borrower.username,
            "message": "Inicio de sesión de cliente exitoso",
        }

    raise HTTPException(
        status_code=400,
        detail="El rol debe ser 'admin' o 'client'",
    )