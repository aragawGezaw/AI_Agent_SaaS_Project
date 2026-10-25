-- Migration: 012_create_transactions_table.sql
-- Description: Creates raw payment transactions table for Chapa (Telebirr/CBE) and multi-module monetization tracking

CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tx_ref VARCHAR(255) UNIQUE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'ETB',
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'success', 'failed'
    module_type VARCHAR(100) DEFAULT 'subscription',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for high-performance lookup during payment verification
CREATE INDEX IF NOT EXISTS idx_transactions_tx_ref ON transactions(tx_ref);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);