from typing import Any, Dict, List


class AIService:
    def categorize_transactions(self, transactions: List[Dict[str, Any]]) -> List[str]:
        # Placeholder for an AI categorization call (e.g. HuggingFace, OpenAI, etc.)
        # For now, just return "uncategorized" for each transaction.
        return ["uncategorized" for _ in transactions]

