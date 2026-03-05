"""enhance transaction model for offchain and onchain tracking

Revision ID: f006_enhance_tx
Revises: e005_add_privy
Create Date: 2026-03-05

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'f006_enhance_tx'
down_revision: Union[str, None] = 'e005_add_privy'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    
    # Check and add transaction_type only if missing
    result = conn.execute(sa.text(
        "SHOW COLUMNS FROM transactions LIKE 'transaction_type'"
    ))
    if not result.fetchone():
        op.add_column('transactions', sa.Column('transaction_type', sa.Enum('expense', 'income', name='transactiontype'), server_default='expense', nullable=False))
    
    # Check and add recipient only if missing
    result = conn.execute(sa.text(
        "SHOW COLUMNS FROM transactions LIKE 'recipient'"
    ))
    if not result.fetchone():
        op.add_column('transactions', sa.Column('recipient', sa.String(length=255), nullable=True))
    
    # Check and add reference_number only if missing
    result = conn.execute(sa.text(
        "SHOW COLUMNS FROM transactions LIKE 'reference_number'"
    ))
    if not result.fetchone():
        op.add_column('transactions', sa.Column('reference_number', sa.String(length=255), nullable=True))
    
    # Check and add is_verified only if missing
    result = conn.execute(sa.text(
        "SHOW COLUMNS FROM transactions LIKE 'is_verified'"
    ))
    if not result.fetchone():
        op.add_column('transactions', sa.Column('is_verified', sa.Boolean(), server_default='0', nullable=False))
    
    # Check and add updated_at only if missing
    result = conn.execute(sa.text(
        "SHOW COLUMNS FROM transactions LIKE 'updated_at'"
    ))
    if not result.fetchone():
        op.add_column('transactions', sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False))
    
    # Create indices for better query performance (idempotent - won't fail if they exist)
    try:
        op.create_index('ix_transactions_source', 'transactions', ['source'])
    except:
        pass
    
    try:
        op.create_index('ix_transactions_transaction_type', 'transactions', ['transaction_type'])
    except:
        pass
    
    try:
        op.create_index('ix_transactions_user_created', 'transactions', ['user_id', 'created_at'])
    except:
        pass


def downgrade() -> None:
    op.drop_index('ix_transactions_user_created', table_name='transactions')
    op.drop_index('ix_transactions_transaction_type', table_name='transactions')
    op.drop_index('ix_transactions_source', table_name='transactions')
    op.drop_column('transactions', 'updated_at')
    op.drop_column('transactions', 'is_verified')
    op.drop_column('transactions', 'reference_number')
    op.drop_column('transactions', 'recipient')
    op.drop_column('transactions', 'transaction_type')
