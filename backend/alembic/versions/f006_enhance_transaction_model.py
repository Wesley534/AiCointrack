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
    # Add new columns to transactions table
    op.add_column('transactions', sa.Column('transaction_type', sa.Enum('expense', 'income', name='transactiontype'), server_default='expense', nullable=False))
    op.add_column('transactions', sa.Column('recipient', sa.String(length=255), nullable=True))
    op.add_column('transactions', sa.Column('reference_number', sa.String(length=255), nullable=True))
    op.add_column('transactions', sa.Column('is_verified', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('transactions', sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False))
    
    # Create indices for better query performance
    op.create_index('ix_transactions_source', 'transactions', ['source'])
    op.create_index('ix_transactions_transaction_type', 'transactions', ['transaction_type'])
    op.create_index('ix_transactions_user_created', 'transactions', ['user_id', 'created_at'])


def downgrade() -> None:
    op.drop_index('ix_transactions_user_created', table_name='transactions')
    op.drop_index('ix_transactions_transaction_type', table_name='transactions')
    op.drop_index('ix_transactions_source', table_name='transactions')
    op.drop_column('transactions', 'updated_at')
    op.drop_column('transactions', 'is_verified')
    op.drop_column('transactions', 'reference_number')
    op.drop_column('transactions', 'recipient')
    op.drop_column('transactions', 'transaction_type')
