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
    """Upgrade schema - convert ENUM to VARCHAR to avoid case sensitivity issues."""
    # Convert ENUM columns to VARCHAR to preserve data and avoid case issues
    # Data will remain lowercase (mpesa, bank, cash, onchain, expense, income)
    op.execute('ALTER TABLE transactions MODIFY COLUMN source VARCHAR(20) NOT NULL')
    op.execute('ALTER TABLE transactions MODIFY COLUMN transaction_type VARCHAR(20) DEFAULT "expense"')


def downgrade() -> None:
    """Downgrade schema."""
    # Revert to ENUM columns with lowercase values
    op.execute('ALTER TABLE transactions MODIFY COLUMN source ENUM("mpesa", "bank", "cash", "onchain") NOT NULL')
    op.execute('ALTER TABLE transactions MODIFY COLUMN transaction_type ENUM("expense", "income") DEFAULT "expense"')