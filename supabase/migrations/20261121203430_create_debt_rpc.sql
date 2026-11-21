
CREATE OR REPLACE FUNCTION public.create_debt(
    p_type TEXT,
    p_person_name TEXT,
    p_total_amount NUMERIC,
    p_affect_wallet BOOLEAN DEFAULT TRUE,
    p_wallet_id UUID DEFAULT NULL,
    p_due_date DATE DEFAULT NULL,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_debt_id UUID;
    v_wallet_balance NUMERIC(15, 2);
    v_transaction_type TEXT;
    v_transaction_note TEXT;
BEGIN
    -- Validate authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    -- Validate debt type
    IF p_type IS NULL OR p_type NOT IN ('receivable', 'payable') THEN
        RAISE EXCEPTION 'Invalid debt type';
    END IF;

    -- Validate person name
    IF p_person_name IS NULL OR BTRIM(p_person_name) = '' THEN
        RAISE EXCEPTION 'Person name is required';
    END IF;

    IF LENGTH(BTRIM(p_person_name)) > 100 THEN
        RAISE EXCEPTION 'Person name cannot exceed 100 characters';
    END IF;

    -- Validate amount
    IF p_total_amount IS NULL OR p_total_amount <= 0 THEN
        RAISE EXCEPTION 'Debt amount must be greater than zero';
    END IF;

    IF p_total_amount > 9999999999999.99 THEN
        RAISE EXCEPTION 'Debt amount exceeds the supported limit';
    END IF;

    IF p_total_amount <> ROUND(p_total_amount, 2) THEN
        RAISE EXCEPTION 'Debt amount cannot have more than two decimal places';
    END IF;

    -- Validate wallet selection
    IF p_affect_wallet IS NULL THEN
        RAISE EXCEPTION 'Wallet effect setting is required';
    END IF;

    IF p_affect_wallet = TRUE AND p_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet is required when affecting wallet balance';
    END IF;

    -- Lock and validate wallet when provided
    IF p_wallet_id IS NOT NULL THEN
        SELECT balance
        INTO v_wallet_balance
        FROM public.wallets
        WHERE id = p_wallet_id
          AND user_id = v_user_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Wallet was not found';
        END IF;
    END IF;

    -- Determine automatic transaction type
    IF p_type = 'receivable' THEN
        v_transaction_type := 'expense';
        v_transaction_note := 'Receivable created: ' || BTRIM(p_person_name);
    ELSE
        v_transaction_type := 'income';
        v_transaction_note := 'Payable created: ' || BTRIM(p_person_name);
    END IF;

    -- Validate wallet balance before recording a receivable
    IF p_affect_wallet = TRUE AND p_type = 'receivable' THEN
        IF v_wallet_balance < p_total_amount THEN
            RAISE EXCEPTION 'Insufficient wallet balance';
        END IF;
    END IF;

    -- Prevent wallet balance overflow for a payable
    IF p_affect_wallet = TRUE AND p_type = 'payable' THEN
        IF v_wallet_balance + p_total_amount > 9999999999999.99 THEN
            RAISE EXCEPTION 'Wallet balance exceeds the supported limit';
        END IF;
    END IF;

    -- Create debt record
    INSERT INTO public.debts (
        user_id,
        wallet_id,
        type,
        person_name,
        total_amount,
        remaining_amount,
        affect_wallet,
        due_date,
        status,
        note
    )
    VALUES (
        v_user_id,
        p_wallet_id,
        p_type,
        BTRIM(p_person_name),
        p_total_amount,
        p_total_amount,
        p_affect_wallet,
        p_due_date,
        'unpaid',
        NULLIF(BTRIM(p_note), '')
    )
    RETURNING id INTO v_debt_id;

    -- Update wallet and create linked transaction when enabled
    IF p_affect_wallet = TRUE THEN
        IF p_type = 'receivable' THEN
            UPDATE public.wallets
            SET balance = balance - p_total_amount
            WHERE id = p_wallet_id
              AND user_id = v_user_id;
        ELSE
            UPDATE public.wallets
            SET balance = balance + p_total_amount
            WHERE id = p_wallet_id
              AND user_id = v_user_id;
        END IF;

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
            NULL,
            v_debt_id,
            v_transaction_type,
            p_total_amount,
            FALSE,
            v_transaction_note,
            NULL,
            CURRENT_DATE
        );
    END IF;

    RETURN v_debt_id;
END;
$$;
