
-- 1. User profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Wallets
CREATE TABLE public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    scope VARCHAR(20) NOT NULL
        CHECK (scope IN ('business', 'personal')),
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Transaction categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('income', 'expense')),
    scope VARCHAR(20) NOT NULL
        CHECK (scope IN ('business', 'personal', 'both')),
    icon VARCHAR(50),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE
);

-- 4. Debts and receivables
CREATE TABLE public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES public.wallets(id),
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('receivable', 'payable')),
    person_name VARCHAR(100) NOT NULL,
    total_amount NUMERIC(15, 2) NOT NULL CHECK (total_amount > 0),
    remaining_amount NUMERIC(15, 2) NOT NULL
        CHECK (remaining_amount >= 0),
    affect_wallet BOOLEAN NOT NULL DEFAULT TRUE,
    due_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid'
        CHECK (status IN ('unpaid', 'partial', 'paid')),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Transactions
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    wallet_id UUID NOT NULL REFERENCES public.wallets(id),
    destination_wallet_id UUID REFERENCES public.wallets(id),
    category_id UUID REFERENCES public.categories(id),
    debt_id UUID REFERENCES public.debts(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('income', 'expense', 'transfer')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    is_cross_scope BOOLEAN NOT NULL DEFAULT FALSE,
    note TEXT,
    receipt_path TEXT,
    transaction_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Monthly budgets
CREATE TABLE public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL
        REFERENCES public.categories(id) ON DELETE CASCADE,
    amount_limit NUMERIC(15, 2) NOT NULL CHECK (amount_limit > 0),
    month_year VARCHAR(7) NOT NULL,
    UNIQUE(user_id, category_id, month_year)
);

-- Indexes for dashboard and report queries
CREATE INDEX idx_transactions_user_date
    ON public.transactions(user_id, transaction_date DESC);

CREATE INDEX idx_wallets_user
    ON public.wallets(user_id);

CREATE INDEX idx_debts_user_status
    ON public.debts(user_id, status);
