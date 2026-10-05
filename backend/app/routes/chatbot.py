from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.chatbot import ChatRequest, ChatResponse, SuggestionsResponse
from app.services.chatbot_service import ChatbotService

router = APIRouter(
    prefix="/chat",
    tags=["AI Chatbot"]
)

@router.post("", response_model=ChatResponse, status_code=status.HTTP_200_OK)
async def process_chat_message(
    req: ChatRequest,
    db: Session = Depends(get_db)
):
    """
    Module 6: AI Chatbot Endpoint
    Answers cybersecurity queries, provides incident guidance, step-by-step solutions,
    and integrates with Knowledge Base (M4), Threat Detection (M3), and Alerts (M5).
    """
    if not req.message or not req.message.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Message cannot be empty."
        )
    return await ChatbotService.process_message(db, req)

@router.get("/suggestions", response_model=SuggestionsResponse, status_code=status.HTTP_200_OK)
def get_chat_suggestions():
    """
    Returns default quick-prompt suggestions for cybersecurity inquiries.
    """
    return SuggestionsResponse(suggestions=ChatbotService.get_default_suggestions())
