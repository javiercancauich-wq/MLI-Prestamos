from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models import LoanStatus, PaymentFrequency, PaymentMethod


class BorrowerSummary(BaseModel):
    id: int
    full_name: str
    phone: str
    address: str
    username: str
    initial_password: str
    ine_front_path: str
    ine_back_path: str

    class Config:
        from_attributes = True


class InstallmentItem(BaseModel):
    installment: int
    due_date: str
    amount: float
    principal: float
    interest: float


class LoanIntakeResponse(BaseModel):
    message: str
    loan_id: int
    amount: float
    interest_rate: float
    installments_count: int
    frequency: PaymentFrequency
    total_interest: float
    total_to_pay: float
    installment_amount: float
    status: LoanStatus
    borrower: BorrowerSummary
    schedule: list[InstallmentItem]
    created_at: datetime


class PaymentCreateResponse(BaseModel):
    message: str
    payment_id: int
    loan_id: int
    amount: float
    principal_paid: float
    interest_paid: float
    payment_method: PaymentMethod
    notes: Optional[str] = None


class PaymentHistoryItem(BaseModel):
    id: int
    amount: float
    principal_paid: float
    interest_paid: float
    payment_method: PaymentMethod
    notes: Optional[str] = None
    created_at: datetime

    class Config: 
        from_attributes = True


class ClientLoanSummaryResponse(BaseModel):
    borrower_id: int 
    full_name: str
    username: str
    loan_id: int
    amount: float
    interest_rate: float
    installments_count: int
    frequency: PaymentFrequency
    total_interest: float
    total_to_pay: float
    total_paid: float
    remaining_balance: float
    installment_amount: float
    status: LoanStatus
    schedule: list[InstallmentItem]
    payments: list[PaymentHistoryItem]


class LoanListItem(BaseModel):
    loan_id: int
    borrower_id: int
    full_name: str
    phone: str
    address: str
    username: str
    amount: float
    interest_rate: float
    installments_count: int
    frequency: PaymentFrequency
    total_to_pay: float
    total_paid: float
    remaining_balance: float
    installment_amount: float
    status: LoanStatus