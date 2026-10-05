from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, description="User's cybersecurity query or incident message")
    conversationId: Optional[str] = Field(None, description="Optional persistent conversation session ID")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Optional client context such as active alert or threat info")

class IncidentGuidance(BaseModel):
    threatIdentified: str
    severity: str
    immediateActions: List[str]
    actionsToAvoid: List[str]
    emergencyHelplines: List[str]

class ChatResponse(BaseModel):
    message: str
    conversationId: str
    suggestions: List[str] = Field(default_factory=list)
    relatedKnowledgeEntries: List[Dict[str, Any]] = Field(default_factory=list)
    relatedAlerts: List[Dict[str, Any]] = Field(default_factory=list)
    incidentGuidance: Optional[IncidentGuidance] = None
    threatContext: Optional[Dict[str, Any]] = None
    timestamp: str

class SuggestionsResponse(BaseModel):
    suggestions: List[str]
