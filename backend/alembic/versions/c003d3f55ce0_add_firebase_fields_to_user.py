"""add firebase fields to user

Revision ID: c003d3f55ce0
Revises: b002c2f44bd9
Create Date: 2026-03-02 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c003d3f55ce0'
down_revision: Union[str, None] = 'b002c2f44bd9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to add Firebase authentication fields."""
    # Make hashed_password nullable for Firebase users
    op.alter_column('users', 'hashed_password',
                    existing_type=sa.String(length=255),
                    nullable=True)
    
    # Add Firebase-specific fields
    op.add_column('users', sa.Column('firebase_uid', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('display_name', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('photo_url', sa.String(length=500), nullable=True))
    op.add_column('users', sa.Column('updated_at', sa.DateTime(), nullable=True))
    
    # Create indexes for Firebase UID
    op.create_index('ix_users_firebase_uid', 'users', ['firebase_uid'], unique=True)


def downgrade() -> None:
    """Downgrade schema by removing Firebase fields."""
    # Remove indexes
    op.drop_index('ix_users_firebase_uid', table_name='users')
    
    # Remove columns
    op.drop_column('users', 'updated_at')
    op.drop_column('users', 'photo_url')
    op.drop_column('users', 'display_name')
    op.drop_column('users', 'firebase_uid')
    
    # Make hashed_password not nullable again
    op.alter_column('users', 'hashed_password',
                    existing_type=sa.String(length=255),
                    nullable=False)
