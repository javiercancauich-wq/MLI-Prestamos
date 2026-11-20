import enum
from datetime import datetime
from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base


class LoanStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    paid = "paid"


class PaymentFrequency(str, enum.Enum):
    weekly = "weekly"
    biweekly = "biweekly"
    monthly = "monthly"


class PaymentMethod(str, enum.Enum):
    cash = "cash"
    card = "card"
    transfer = "transfer"


class Borrower(Base):
    __tablename__ = "borrowers"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    address = Column(String, nullable=False)
    ine_front_path = Column(String, nullable=False)
    ine_back_path = Column(String, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    password_plain_initial = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    loans = relationship("Loan", back_populates="borrower")


class Loan(Base):
    __tablename__ = "loans"

    id = Column(Integer, primary_key=True, index=True)
    borrower_id = Column(Integer, ForeignKey("borrowers.id"), nullable=False)
    amount = Column(Float, nullable=False)
    interest_rate = Column(Float, nullable=False)
    installments_count = Column(Integer, nullable=False)
    frequency = Column(
        Enum(PaymentFrequency), default=PaymentFrequency.biweekly, nullable=False
    )
    total_interest = Column(Float, nullable=False)
    total_to_pay = Column(Float, nullable=False)
    installment_amount = Column(Float, nullable=False)
    status = Column(Enum(LoanStatus), default=LoanStatus.approved, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    borrower = relationship("Borrower", back_populates="loans")
    payments = relationship("Payment", back_populates="loan")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    loan_id = Column(Integer, ForeignKey("loans.id"), nullable=False)
    amount = Column(Float, nullable=False)
    principal_paid = Column(Float, nullable=False)
    interest_paid = Column(Float, nullable=False)
    payment_method = Column(Enum(PaymentMethod), nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    loan = relationship("Loan", back_populates="payments")