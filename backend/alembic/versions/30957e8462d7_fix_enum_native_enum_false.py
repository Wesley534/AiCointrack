"""fix_enum_native_enum_false

Revision ID: 30957e8462d7
Revises: 67f1e63ab6e7
Create Date: 2026-03-05 14:20:42.097966

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '30957e8462d7'
down_revision: Union[str, Sequence[str], None] = '67f1e63ab6e7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - convert ENUM to VARCHAR (PostgreSQL-compatible)."""
    # The initial migration already creates source as String and transaction_type
    # was set as String by f006_enhance_tx, so this migration is a no-op for PostgreSQL.
    # On MySQL the raw ALTER TABLE statements were needed to strip ENUM types.
    pass


def downgrade() -> None:
    """Downgrade schema - no-op (ENUM was never used on PostgreSQL)."""
    pass