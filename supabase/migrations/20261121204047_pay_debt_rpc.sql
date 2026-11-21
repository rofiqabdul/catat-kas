
CREATE OR REPLACE FUNCTION public.pay_debt(
    p_debt_id UUID,
    p_payment_amount NUMERIC,
    p_note TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_debt public.debts%ROWTYPE;
    v_wallet_balance NUMERIC(15, 2);
    v_new_remaining_amount NUMERIC(15, 2);
    v_transaction_type TEXT;
    v_transaction_note TEXT;
    v_transaction_id UUID;
BEGIN
    -- Validate authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    -- Validate debt ID
    IF p_debt_id IS NULL THEN
        RAISE EXCEPTION 'Debt ID is required';
    END IF;

    -- Validate payment amount
    IF p_payment_amount IS NULL OR p_payment_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than zero';
    END IF;

    IF p_payment_amount > 9999999999999.99 THEN
        RAISE EXCEPTION 'Payment amount exceeds the supported limit';
    END IF;

    IF p_payment_amount <> ROUND(p_payment_amount, 2) THEN
        RAISE EXCEPTION 'Payment amount cannot have more than two decimal places';
    END IF;

    -- Lock and retrieve the user's debt
    SELECT *
    INTO v_debt
    FROM public.debts
    WHERE id = p_debt_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Debt was not found';
    END IF;

    -- Validate debt status and remaining amount
    IF v_debt.status = 'paid' OR v_debt.remaining_amount <= 0 THEN
        RAISE EXCEPTION 'Debt has already been fully paid';
    END IF;

    IF p_payment_amount > v_debt.remaining_amount THEN
        RAISE EXCEPTION 'Payment amount exceeds remaining debt';
    END IF;

    -- Determine remaining amount
    v_new_remaining_amount :=
        v_debt.remaining_amount - p_payment_amount;

    -- Handle debt without wallet impact
    IF v_debt.affect_wallet = FALSE THEN
        UPDATE public.debts
        SET
            remaining_amount = v_new_remaining_amount,
            status = CASE
                WHEN v_new_remaining_amount = 0 THEN 'paid'
                ELSE 'partial'
            END
        WHERE id = p_debt_id
          AND user_id = v_user_id;

        RETURN NULL;
    END IF;

    -- Wallet is required when wallet impact is enabled
    IF v_debt.wallet_id IS NULL THEN
        RAISE EXCEPTION 'Debt wallet is missing';
    END IF;

    -- Lock and validate the original wallet
    SELECT balance
    INTO v_wallet_balance
    FROM public.wallets
    WHERE id = v_debt.wallet_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Debt wallet was not found';
    END IF;

    -- Determine transaction type and validate wallet balance
    IF v_debt.type = 'receivable' THEN
        v_transaction_type := 'income';

        IF v_wallet_balance + p_payment_amount > 9999999999999.99 THEN
            RAISE EXCEPTION 'Wallet balance exceeds the supported limit';
        END IF;

        v_transaction_note := 'Receivable payment: ' || v_debt.person_name;

    ELSIF v_debt.type = 'payable' THEN
        v_transaction_type := 'expense';

        IF v_wallet_balance < p_payment_amount THEN
            RAISE EXCEPTION 'Insufficient wallet balance';
        END IF;

        v_transaction_note := 'Payable payment: ' || v_debt.person_name;

    ELSE
        RAISE EXCEPTION 'Unsupported debt type';
    END IF;

    -- Apply optional payment note
    IF NULLIF(BTRIM(p_note), '') IS NOT NULL THEN
        v_transaction_note := BTRIM(p_note);
    END IF;

    -- Update debt remaining amount and status
    UPDATE public.debts
    SET
        remaining_amount = v_new_remaining_amount,
        status = CASE
            WHEN v_new_remaining_amount = 0 THEN 'paid'
            ELSE 'partial'
        END
    WHERE id = p_debt_id
      AND user_id = v_user_id;

    -- Update wallet balance
    IF v_debt.type = 'receivable' THEN
        UPDATE public.wallets
        SET balance = balance + p_payment_amount
        WHERE id = v_debt.wallet_id
          AND user_id = v_user_id;
    ELSE
        UPDATE public.wallets
        SET balance = balance - p_payment_amount
        WHERE id = v_debt.wallet_id
          AND user_id = v_user_id;
    END IF;

    -- Create linked payment transaction
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
        v_debt.wallet_id,
        NULL,
        NULL,
        p_debt_id,
        v_transaction_type,
        p_payment_amount,
        FALSE,
        v_transaction_note,
        NULL,
        CURRENT_DATE
    )
    RETURNING id INTO v_transaction_id;

    RETURN v_transaction_id;
END;
$$;
