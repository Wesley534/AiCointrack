"""add wallet fields and auth_providers to user

Revision ID: d004_add_wallet
Revises: c003d3f55ce0
Create Date: 2026-03-04

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd004_add_wallet'
down_revision: Union[str, None] = 'c003d3f55ce0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add wallet and auth_providers fields."""
    op.add_column('users', sa.Column('wallet_address', sa.String(length=42), nullable=True))
    op.add_column('users', sa.Column('wallet_created_by_system', sa.Boolean(), nullable=True, server_default='0'))
    op.add_column('users', sa.Column('auth_providers', sa.JSON(), nullable=True))
    op.create_index('ix_users_wallet_address', 'users', ['wallet_address'], unique=True)
    # Make email nullable for wallet-only users (e.g. wallet@cointrack.xyz placeholder)
    op.alter_column('users', 'email', existing_type=sa.String(255), nullable=True)


def downgrade() -> None:
    op.drop_index('ix_users_wallet_address', table_name='users')
    op.drop_column('users', 'auth_providers')
    op.drop_column('users', 'wallet_created_by_system')
    op.drop_column('users', 'wallet_address')
    op.alter_column('users', 'email', existing_type=sa.String(255), nullable=False)
