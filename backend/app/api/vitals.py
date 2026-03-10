import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db.tables import Vitals
from app.schemas.user import VitalsCreate, VitalsResponse
from typing import List

router = APIRouter()


@router.post("/{user_id}", response_model=VitalsResponse)
def save_vitals(user_id: int, vitals: VitalsCreate, db: Session = Depends(get_db)):
    record = Vitals(
        user_id=user_id,
        heart_rate=vitals.heart_rate,
        systolic=vitals.systolic,
        diastolic=vitals.diastolic,
        blood_sugar=vitals.blood_sugar,
        body_temp=vitals.body_temp,
        spo2=vitals.spo2,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return _serialize(record)


@router.get("/{user_id}/latest", response_model=VitalsResponse)
def get_latest_vitals(user_id: int, db: Session = Depends(get_db)):
    record = (
        db.query(Vitals)
        .filter(Vitals.user_id == user_id)
        .order_by(Vitals.id.desc())
        .first()
    )
    if not record:
        raise HTTPException(status_code=404, detail="No vitals found")
    return _serialize(record)


@router.get("/{user_id}/history", response_model=List[VitalsResponse])
def get_vitals_history(user_id: int, limit: int = 20, db: Session = Depends(get_db)):
    records = (
        db.query(Vitals)
        .filter(Vitals.user_id == user_id)
        .order_by(Vitals.id.desc())
        .limit(limit)
        .all()
    )
    return [_serialize(r) for r in records]


def _serialize(record: Vitals) -> dict:
    return {
        "id": record.id,
        "user_id": record.user_id,
        "heart_rate": record.heart_rate,
        "systolic": record.systolic,
        "diastolic": record.diastolic,
        "blood_sugar": record.blood_sugar,
        "body_temp": record.body_temp,
        "spo2": record.spo2,
        "recorded_at": str(record.recorded_at) if record.recorded_at else None,
    }
