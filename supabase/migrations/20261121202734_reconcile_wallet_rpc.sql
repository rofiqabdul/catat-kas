
CREATE OR REPLACE FUNCTION public.reconcile_wallet(
    p_wallet_id UUID,
    p_actual_balance NUMERIC
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_balance NUMERIC(15, 2);
    v_difference NUMERIC;
    v_category_id UUID;
    v_category_count BIGINT;
    v_transaction_id UUID;
    v_transaction_type TEXT;
    v_category_name TEXT;
BEGIN
    -- Validate authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    -- Validate wallet ID
    IF p_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet ID is required';
    END IF;

    -- Validate actual balance
    IF p_actual_balance IS NULL THEN
        RAISE EXCEPTION 'Actual balance is required';
    END IF;

    IF p_actual_balance < 0 THEN
        RAISE EXCEPTION 'Actual balance cannot be negative';
    END IF;

    IF p_actual_balance > 9999999999999.99 THEN
        RAISE EXCEPTION 'Actual balance exceeds the supported limit';
    END IF;

    IF p_actual_balance <> ROUND(p_actual_balance, 2) THEN
        RAISE EXCEPTION 'Actual balance cannot have more than two decimal places';
    END IF;

    -- Lock and retrieve the user's wallet
    SELECT balance
    INTO v_current_balance
    FROM public.wallets
    WHERE id = p_wallet_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet was not found';
    END IF;

    -- Calculate the difference
    v_difference := p_actual_balance - v_current_balance;

    -- No adjustment is needed
    IF v_difference = 0 THEN
        RETURN NULL;
    END IF;

    -- Determine transaction type and system category
    IF v_difference > 0 THEN
        v_transaction_type := 'income';
        v_category_name := 'Selisih Kas Masuk';
    ELSE
        v_transaction_type := 'expense';
        v_category_name := 'Selisih Kas Keluar';
    END IF;

    -- Find the user's active system category
    SELECT
        COUNT(*),
        (ARRAY_AGG(id))[1]
    INTO
        v_category_count,
        v_category_id
    FROM public.categories
    WHERE user_id = v_user_id
      AND name = v_category_name
      AND type = v_transaction_type
      AND scope = 'both'
      AND is_system = TRUE
      AND is_archived = FALSE;

    IF v_category_count <> 1 THEN
        RAISE EXCEPTION 'Required system category is missing or duplicated: %',
            v_category_name;
    END IF;

    -- Create the adjustment transaction
    INSERT INTO public.transactions (
        user_id,
        wallet_id,
        destination_wallet_id,
        category_id,
        debt_id,
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
        NULL,
        v_category_id,
        NULL,
        v_transaction_type,
        ABS(v_difference),
        FALSE,
        'Wallet balance reconciliation',
        NULL,
        CURRENT_DATE
    )
    RETURNING id INTO v_transaction_id;

    -- Synchronize the wallet balance
    UPDATE public.wallets
    SET balance = p_actual_balance
    WHERE id = p_wallet_id
      AND user_id = v_user_id;

    RETURN v_transaction_id;
END;
$$;
