"""add onchain fingerprint fields to transactions

Revision ID: g007_fingerprint
Revises: 30957e8462d7
Create Date: 2026-03-23
"""
from alembic import op
import sqlalchemy as sa

revision = 'g007_fingerprint'
down_revision = '30957e8462d7'
branch_labels = None
depends_on = None


def upgrade():
    # onchain_hash: the keccak256 fingerprint stored in HashStore.sol (bytes32 as hex)
    op.add_column('transactions', sa.Column(
        'onchain_hash', sa.String(length=66), nullable=True,
        comment='keccak256 fingerprint stored in HashStore.sol (0x + 64 hex chars)'
    ))
    # hash_store_tx: the Base transaction hash of the HashStore.storeHash() call
    op.add_column('transactions', sa.Column(
        'hash_store_tx', sa.String(length=66), nullable=True,
        comment='Base tx hash of the HashStore.storeHash() call'
    ))
    # fingerprint_stored_at: when the fingerprint was stored on-chain
    op.add_column('transactions', sa.Column(
        'fingerprint_stored_at', sa.DateTime(), nullable=True
    ))

    # Index for fast lookup by hash
    op.create_index(
        'ix_transactions_onchain_hash',
        'transactions',
        ['onchain_hash'],
        unique=False
    )


def downgrade():
    op.drop_index('ix_transactions_onchain_hash', table_name='transactions')
    op.drop_column('transactions', 'fingerprint_stored_at')
    op.drop_column('transactions', 'hash_store_tx')
    op.drop_column('transactions', 'onchain_hash')
