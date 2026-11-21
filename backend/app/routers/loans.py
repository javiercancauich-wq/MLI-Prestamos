from datetime import datetime, timedelta
import hashlib
import os
import secrets
import uuid
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import (
    Borrower,
    Loan,
    LoanStatus,
    Payment,
    PaymentFrequency,
    PaymentMethod,
)
from app.schemas import (
    InstallmentItem,
    LoanIntakeResponse,
    PaymentCreateResponse,
    ClientLoanSummaryResponse,
    PaymentHistoryItem,
    LoanListItem,
)

router = APIRouter(prefix="/api/loans", tags=["Admin & Client Loans"])

UPLOAD_DIR = "uploads/ine"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def save_ine_image(file: UploadFile, side: str) -> str:
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in {".jpg", ".jpeg", ".png", ".webp"}:
        ext = ".jpg"
    filename = f"{uuid.uuid4().hex}_{side}{ext}"
    path = os.path.join(UPLOAD_DIR, filename)
    with open(path, "wb") as f:
        f.write(file.file.read())
    return path.replace("\\", "/")


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def generate_credentials(full_name: str, db: Session) -> tuple[str, str]:
    base_user = "".join(c for c in full_name.lower().split()[0] if c.isalnum()) or "cliente"
    candidate = f"{base_user}{secrets.randbelow(900) + 100}"
    while db.query(Borrower).filter(Borrower.username == candidate).first():
        candidate = f"{base_user}{secrets.randbelow(9000) + 1000}"
    password = secrets.token_urlsafe(6)
    return candidate, password


def build_schedule(
    amount: float, total_to_pay: float, count: int, frequency: PaymentFrequency
) -> list[InstallmentItem]:
    step_days = {
        PaymentFrequency.weekly: 7,
        PaymentFrequency.biweekly: 15,
        PaymentFrequency.monthly: 30,
    }[frequency]
    cuota = round(total_to_pay / count, 2)
    principal_part = round(amount / count, 2)
    interest_part = round(cuota - principal_part, 2)
    start_date = datetime.utcnow()

    items: list[InstallmentItem] = []
    for i in range(1, count + 1):
        due_date = start_date + timedelta(days=step_days * i)
        items.append(
            InstallmentItem(
                installment=i,
                due_date=due_date.strftime("%Y-%m-%d"),
                amount=cuota,
                principal=principal_part,
                interest=interest_part,
            )
        )
    return items


@router.post("/intake", response_model=LoanIntakeResponse)
def create_borrower_and_loan(
    full_name: str = Form(...),
    phone: str = Form(...),
    address: str = Form(...),
    amount: float = Form(..., gt=0),
    interest_rate: float = Form(..., ge=0),
    installments_count: int = Form(..., gt=0),
    frequency: PaymentFrequency = Form(PaymentFrequency.biweekly),
    ine_front: UploadFile = File(...),
    ine_back: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    if not full_name.strip() or not phone.strip() or not address.strip():
        raise HTTPException(
            status_code=400,
            detail="Nombre completo, teléfono y dirección son obligatorios",
        )

    front_path = save_ine_image(ine_front, "front")
    back_path = save_ine_image(ine_back, "back")
    username, temp_password = generate_credentials(full_name, db)

    total_interest = round(amount * (interest_rate / 100.0), 2)
    total_to_pay = round(amount + total_interest, 2)
    installment_amount = round(total_to_pay / installments_count, 2)

    borrower = Borrower(
        full_name=full_name.strip(),
        phone=phone.strip(),
        address=address.strip(),
        ine_front_path=front_path,
        ine_back_path=back_path,
        username=username,
        password_plain_initial=temp_password,
        hashed_password=hash_password(temp_password),
    )
    db.add(borrower)
    db.flush()

    loan = Loan(
        borrower_id=borrower.id,
        amount=amount,
        interest_rate=interest_rate,
        installments_count=installments_count,
        frequency=frequency,
        total_interest=total_interest,
        total_to_pay=total_to_pay,
        installment_amount=installment_amount,
        status=LoanStatus.approved,
    )
    db.add(loan)
    db.commit()
    db.refresh(loan)
    db.refresh(borrower)

    schedule = build_schedule(amount, total_to_pay, installments_count, frequency)

    return LoanIntakeResponse(
        message="Cliente y préstamo registrados con éxito",
        loan_id=loan.id,
        amount=loan.amount,
        interest_rate=loan.interest_rate,
        installments_count=loan.installments_count,
        frequency=loan.frequency,
        total_interest=loan.total_interest,
        total_to_pay=loan.total_to_pay,
        installment_amount=loan.installment_amount,
        status=loan.status,
        borrower={
            "id": borrower.id,
            "full_name": borrower.full_name,
            "phone": borrower.phone,
            "address": borrower.address,
            "username": borrower.username,
            "initial_password": borrower.password_plain_initial,
            "ine_front_path": borrower.ine_front_path,
            "ine_back_path": borrower.ine_back_path,
        },
        schedule=schedule,
        created_at=loan.created_at,
    )


@router.post("/{loan_id}/payments", response_model=PaymentCreateResponse)
def register_payment(
    loan_id: int,
    amount: float = Form(..., gt=0),
    payment_method: PaymentMethod = Form(...),
    notes: str = Form(default=""),
    db: Session = Depends(get_db),
):
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Préstamo no encontrado")

    principal_ratio = loan.amount / loan.total_to_pay if loan.total_to_pay > 0 else 1.0
    principal_paid = round(amount * principal_ratio, 2)
    interest_paid = round(amount - principal_paid, 2)

    payment = Payment(
        loan_id=loan.id,
        amount=amount,
        principal_paid=principal_paid,
        interest_paid=interest_paid,
        payment_method=payment_method,
        notes=notes,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    return PaymentCreateResponse(
        message="¡Gracias por tu pago! Tu cuenta está al corriente.",
        payment_id=payment.id,
        loan_id=loan.id,
        amount=payment.amount,
        principal_paid=payment.principal_paid,
        interest_paid=payment.interest_paid,
        payment_method=payment.payment_method,
        notes=payment.notes,
    )


@router.get("/client/{borrower_id}", response_model=ClientLoanSummaryResponse)
def get_client_loan_summary(borrower_id: int, db: Session = Depends(get_db)):
    borrower = db.query(Borrower).filter(Borrower.id == borrower_id).first()
    if not borrower:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    loan = (
        db.query(Loan)
        .filter(Loan.borrower_id == borrower.id)
        .order_by(Loan.id.desc())
        .first()
    )
    if not loan:
        raise HTTPException(
            status_code=404,
            detail="El cliente aún no tiene préstamos registrados",
        )

    payments = (
        db.query(Payment)
        .filter(Payment.loan_id == loan.id)
        .order_by(Payment.created_at.desc(), Payment.id.desc())
        .all()
    )

    total_paid = round(sum(p.amount for p in payments), 2)
    remaining_balance = round(max(0.0, loan.total_to_pay - total_paid), 2)
    schedule = build_schedule(
        loan.amount, loan.total_to_pay, loan.installments_count, loan.frequency
    )

    return ClientLoanSummaryResponse(
        borrower_id=borrower.id,
        full_name=borrower.full_name,
        username=borrower.username,
        loan_id=loan.id,
        amount=loan.amount,
        interest_rate=loan.interest_rate,
        installments_count=loan.installments_count,
        frequency=loan.frequency,
        total_interest=loan.total_interest,
        total_to_pay=loan.total_to_pay,
        total_paid=total_paid,
        remaining_balance=remaining_balance,
        installment_amount=loan.installment_amount,
        status=loan.status,
        schedule=schedule,
        payments=payments,
    )


@router.get("", response_model=list[LoanListItem])
def list_loans(db: Session = Depends(get_db)):
    loans = db.query(Loan).order_by(Loan.id.desc()).all()
    result: list[LoanListItem] = []

    for loan in loans:
        borrower = loan.borrower
        if not borrower:
            continue
        payments = db.query(Payment).filter(Payment.loan_id == loan.id).all()
        total_paid = round(sum(p.amount for p in payments), 2)
        remaining_balance = round(max(0.0, loan.total_to_pay - total_paid), 2)

        result.append(
            LoanListItem(
                loan_id=loan.id,
                borrower_id=borrower.id,
                full_name=borrower.full_name,
                phone=borrower.phone,
                address=borrower.address,
                username=borrower.username,
                amount=loan.amount,
                interest_rate=loan.interest_rate,
                installments_count=loan.installments_count,
                frequency=loan.frequency,
                total_to_pay=loan.total_to_pay,
                total_paid=total_paid,
                remaining_balance=remaining_balance,
                installment_amount=loan.installment_amount,
                status=loan.status,
            )
        )

    return result
