-- Create an atomic transaction function
CREATE OR REPLACE FUNCTION public.create_transaction(
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
    v_transaction_id UUID;
    v_wallet_scope TEXT;
    v_destination_scope TEXT;
    v_wallet_balance NUMERIC(15, 2);
    v_category_type TEXT;
    v_category_scope TEXT;
    v_is_cross_scope BOOLEAN := FALSE;
BEGIN
    -- Validate the authenticated user
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
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

    -- Validate wallet ID
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

    -- Lock the involved wallets in a consistent order
    IF p_type = 'transfer' THEN
        PERFORM 1
        FROM public.wallets
        WHERE id IN (p_wallet_id, p_destination_wallet_id)
          AND user_id = v_user_id
        ORDER BY id
        FOR UPDATE;
    ELSE
        PERFORM 1
        FROM public.wallets
        WHERE id = p_wallet_id
          AND user_id = v_user_id
        FOR UPDATE;
    END IF;

    -- Validate and retrieve the source wallet
    SELECT scope, balance
    INTO v_wallet_scope, v_wallet_balance
    FROM public.wallets
    WHERE id = p_wallet_id
      AND user_id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source wallet was not found';
    END IF;

    -- Validate and retrieve the destination wallet for transfers
    IF p_type = 'transfer' THEN
        SELECT scope
        INTO v_destination_scope
        FROM public.wallets
        WHERE id = p_destination_wallet_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Destination wallet was not found';
        END IF;

        v_is_cross_scope := v_wallet_scope <> v_destination_scope;
    END IF;

    -- Validate the category for income and expense transactions
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
           AND v_category_scope <> v_wallet_scope THEN
            RAISE EXCEPTION 'Category scope does not match wallet scope';
        END IF;
    END IF;

    -- Prevent negative source wallet balance
    IF p_type IN ('expense', 'transfer')
       AND v_wallet_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;

    -- Update wallet balances
    IF p_type = 'income' THEN
        UPDATE public.wallets
        SET balance = balance + p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id;

    ELSIF p_type = 'expense' THEN
        UPDATE public.wallets
        SET balance = balance - p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id;

    ELSE
        UPDATE public.wallets
        SET balance = balance - p_amount
        WHERE id = p_wallet_id
          AND user_id = v_user_id;

        UPDATE public.wallets
        SET balance = balance + p_amount
        WHERE id = p_destination_wallet_id
          AND user_id = v_user_id;
    END IF;

    -- Insert the transaction record
    INSERT INTO public.transactions (
        user_id,
        wallet_id,
        destination_wallet_id,
        category_id,
        type,
        amount,
        is_cross_scope,
        note,
        receipt_path,
        transaction_date
    )
    VALUES (
        v_user_id,
        p_wallet_id,
        p_destination_wallet_id,
        p_category_id,
        p_type,
        p_amount,
        v_is_cross_scope,
        p_note,
        p_receipt_path,
        p_transaction_date
    )
    RETURNING id INTO v_transaction_id;

    RETURN v_transaction_id;
END;
$$;
