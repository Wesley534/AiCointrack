"""add privy_user_id and wallet_type to user

Revision ID: e005_add_privy
Revises: d004_add_wallet
Create Date: 2026-03-04

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e005_add_privy'
down_revision: Union[str, None] = 'd004_add_wallet'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('privy_user_id', sa.String(length=128), nullable=True))
    op.add_column('users', sa.Column('wallet_type', sa.String(length=32), nullable=True))
    op.create_index('ix_users_privy_user_id', 'users', ['privy_user_id'], unique=True)


def downgrade() -> None:
    op.drop_index('ix_users_privy_user_id', table_name='users')
    op.drop_column('users', 'wallet_type')
    op.drop_column('users', 'privy_user_id')
