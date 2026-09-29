from pydantic import BaseModel
from typing import List, Optional

class KnowledgeEntryBase(BaseModel):
    id: str
    title: str
    category: str
    description: str
    riskLevel: str
    howScammersDoIt: str
    warningSigns: List[str]
    recommendedActions: List[str]
    preventionTips: List[str]
    keywords: List[str]
    relatedEventTypes: Optional[List[str]] = []
    iconName: Optional[str] = "shield"

class KnowledgeEntryResponse(KnowledgeEntryBase):
    pass

class KnowledgeListResponse(BaseModel):
    total: int
    items: List[KnowledgeEntryResponse]
