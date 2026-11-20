
-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
ON public.profiles
FOR SELECT
USING (id = auth.uid());

CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "Users can delete their own profile"
ON public.profiles
FOR DELETE
USING (id = auth.uid());

-- Wallets policies
CREATE POLICY "Users can view their own wallets"
ON public.wallets
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own wallets"
ON public.wallets
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own wallets"
ON public.wallets
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own wallets"
ON public.wallets
FOR DELETE
USING (user_id = auth.uid());

-- Categories policies
CREATE POLICY "Users can view their own categories"
ON public.categories
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own categories"
ON public.categories
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own categories"
ON public.categories
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own custom categories"
ON public.categories
FOR DELETE
USING (
    user_id = auth.uid()
    AND is_system = FALSE
);

-- Debts policies
CREATE POLICY "Users can view their own debts"
ON public.debts
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own debts"
ON public.debts
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own debts"
ON public.debts
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own debts"
ON public.debts
FOR DELETE
USING (user_id = auth.uid());

-- Transactions policies
CREATE POLICY "Users can view their own transactions"
ON public.transactions
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own transactions"
ON public.transactions
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own transactions"
ON public.transactions
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own transactions"
ON public.transactions
FOR DELETE
USING (user_id = auth.uid());

-- Budgets policies
CREATE POLICY "Users can view their own budgets"
ON public.budgets
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own budgets"
ON public.budgets
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own budgets"
ON public.budgets
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own budgets"
ON public.budgets
FOR DELETE
USING (user_id = auth.uid());
