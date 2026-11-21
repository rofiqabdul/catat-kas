
-- Update an existing transaction atomically
CREATE OR REPLACE FUNCTION public.update_transaction(
    p_transaction_id UUID,
    p_wallet_id UUID,
    p_type TEXT,
    p_amount NUMERIC,
    p_transaction_date DATE,
    p_category_id UUID DEFAULT NULL,
    p_destination_wallet_id UUID DEFAULT NULL,
    p_note TEXT DEFAULT NULL,
    p_receipt_path TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_old_transaction public.transactions%ROWTYPE;
    v_old_wallet_balance NUMERIC(15, 2);
    v_old_destination_balance NUMERIC(15, 2);
    v_new_wallet_balance NUMERIC(15, 2);
    v_new_wallet_scope TEXT;
    v_new_destination_scope TEXT;
    v_category_type TEXT;
    v_category_scope TEXT;
    v_is_cross_scope BOOLEAN := FALSE;
BEGIN
    -- Validate the authenticated user
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    -- Validate the transaction ID
    IF p_transaction_id IS NULL THEN
        RAISE EXCEPTION 'Transaction ID is required';
    END IF;

    -- Lock and retrieve the existing transaction
    SELECT *
    INTO v_old_transaction
    FROM public.transactions
    WHERE id = p_transaction_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction was not found';
    END IF;

    -- Debt-related transactions must be managed through debt functions
    IF v_old_transaction.debt_id IS NOT NULL THEN
        RAISE EXCEPTION 'Debt-related transactions cannot be edited with this function';
    END IF;

    -- Validate transaction type
    IF p_type IS NULL OR p_type NOT IN ('income', 'expense', 'transfer') THEN
        RAISE EXCEPTION 'Invalid transaction type';
    END IF;

    -- Validate amount
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Transaction amount must be greater than zero';
    END IF;

    -- Validate transaction date
    IF p_transaction_date IS NULL THEN
        RAISE EXCEPTION 'Transaction date is required';
    END IF;

    -- Validate source wallet
    IF p_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Source wallet is required';
    END IF;

    -- Validate transaction-specific fields
    IF p_type = 'transfer' THEN
        IF p_category_id IS NOT NULL THEN
            RAISE EXCEPTION 'Transfer transactions cannot have a category';
        END IF;

        IF p_destination_wallet_id IS NULL THEN
            RAISE EXCEPTION 'Destination wallet is required for transfers';
        END IF;

        IF p_wallet_id = p_destination_wallet_id THEN
            RAISE EXCEPTION 'Source and destination wallets must be different';
        END IF;
    ELSE
        IF p_category_id IS NULL THEN
            RAISE EXCEPTION 'Category is required for income and expense transactions';
        END IF;

        IF p_destination_wallet_id IS NOT NULL THEN
            RAISE EXCEPTION 'Destination wallet is only allowed for transfers';
        END IF;
    END IF;

    -- Lock all involved wallets in a consistent order
    PERFORM 1
    FROM public.wallets
    WHERE user_id = v_user_id
      AND id IN (
          v_old_transaction.wallet_id,
          v_old_transaction.destination_wallet_id,
          p_wallet_id,
          p_destination_wallet_id
      )
    ORDER BY id
    FOR UPDATE;

    -- Validate the old source wallet
    SELECT balance
    INTO v_old_wallet_balance
    FROM public.wallets
    WHERE id = v_old_transaction.wallet_id
      AND user_id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Original source wallet was not found';
    END IF;

    -- Validate the old destination wallet when the old transaction is a transfer
    IF v_old_transaction.type = 'transfer' THEN
        SELECT balance
        INTO v_old_destination_balance
        FROM public.wallets
        WHERE id = v_old_transaction.destination_wallet_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Original destination wallet was not found';
        END IF;
    END IF;

    -- Validate the new source wallet
    SELECT scope, balance
    INTO v_new_wallet_scope, v_new_wallet_balance
    FROM public.wallets
    WHERE id = p_wallet_id
      AND user_id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'New source wallet was not found';
    END IF;

    -- Validate the new destination wallet for transfers
    IF p_type = 'transfer' THEN
        SELECT scope
        INTO v_new_destination_scope
        FROM public.wallets
        WHERE id = p_destination_wallet_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'New destination wallet was not found';
        END IF;

        v_is_cross_scope := v_new_wallet_scope <> v_new_destination_scope;
    END IF;

    -- Validate the new category for income and expense transactions
    IF p_type IN ('income', 'expense') THEN
        SELECT type, scope
        INTO v_category_type, v_category_scope
        FROM public.categories
        WHERE id = p_category_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Category was not found';
        END IF;

        IF v_category_type <> p_type THEN
            RAISE EXCEPTION 'Category type does not match transaction type';
        END IF;

        IF v_category_scope <> 'both'
           AND v_category_scope <> v_new_wallet_scope THEN
            RAISE EXCEPTION 'Category scope does not match wallet scope';
        END IF;
    END IF;

    -- Restore the original transaction effect
    IF v_old_transaction.type = 'income' THEN
        UPDATE public.wallets
        SET balance = balance - v_old_transaction.amount
        WHERE id = v_old_transaction.wallet_id
          AND user_id = v_user_id
          AND balance >= v_old_transaction.amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot edit transaction because its income has already been spent';
        END IF;

    ELSIF v_old_transaction.type = 'expense' THEN
        UPDATE public.wallets
        SET balance = balance + v_old_transaction.amount
        WHERE id = v_old_transaction.wallet_id
          AND user_id = v_user_id;

    ELSE
        UPDATE public.wallets
        SET balance = balance + v_old_transaction.amount
        WHERE id = v_old_transaction.wallet_id
          AND user_id = v_user_id;

        UPDATE public.wallets
        SET balance = balance - v_old_transaction.amount
        WHERE id = v_old_transaction.destination_wallet_id
          AND user_id = v_user_id
          AND balance >= v_old_transaction.amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot edit transfer because its destination funds have already been spent';
        END IF;
    END IF;

    -- Apply the new transaction effect
    IF p_type = 'income' THEN
        UPDATE public.wallets
        SET balance = balance + p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id;

    ELSIF p_type = 'expense' THEN
        UPDATE public.wallets
        SET balance = balance - p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id
          AND balance >= p_amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient wallet balance';
        END IF;

    ELSE
        UPDATE public.wallets
        SET balance = balance - p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id
          AND balance >= p_amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient wallet balance';
        END IF;

        UPDATE public.wallets
        SET balance = balance + p_amount
        WHERE id = p_destination_wallet_id
          AND user_id = v_user_id;
    END IF;

    -- Update the transaction record
    UPDATE public.transactions
    SET
        wallet_id = p_wallet_id,
        destination_wallet_id = p_destination_wallet_id,
        category_id = p_category_id,
        type = p_type,
        amount = p_amount,
        is_cross_scope = v_is_cross_scope,
        note = p_note,
        receipt_path = p_receipt_path,
        transaction_date = p_transaction_date
    WHERE id = p_transaction_id
      AND user_id = v_user_id;

    RETURN p_transaction_id;
END;
$$;
