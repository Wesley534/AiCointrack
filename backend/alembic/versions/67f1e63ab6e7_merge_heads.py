"""merge heads

Revision ID: 67f1e63ab6e7
Revises: 1917caf6b4f1, f006_enhance_tx
Create Date: 2026-03-05 13:47:24.335454

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '67f1e63ab6e7'
down_revision: Union[str, Sequence[str], None] = ('1917caf6b4f1', 'f006_enhance_tx')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
