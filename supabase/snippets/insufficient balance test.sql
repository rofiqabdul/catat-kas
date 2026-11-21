BEGIN;

SET LOCAL ROLE authenticated;

SELECT set_config(
    'request.jwt.claim.sub',
    '73b8fe57-304f-4fd5-98bd-08700c55a4a7',
    TRUE
);

DO $$
DECLARE
    v_wallet_id UUID;
    v_category_id UUID;
    v_balance NUMERIC(15, 2);
    v_error_caught BOOLEAN := FALSE;
BEGIN
    -- Create a temporary test wallet
    INSERT INTO public.wallets (user_id, name, scope, balance)
    VALUES (auth.uid(), 'RPC Insufficient Balance Test', 'business', 100000)
    RETURNING id INTO v_wallet_id;

    -- Find the default expense category
    SELECT id
    INTO v_category_id
    FROM public.categories
    WHERE user_id = auth.uid()
      AND name = 'Operasional'
      AND type = 'expense'
    LIMIT 1;

    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Expense category was not found';
    END IF;

    -- Attempt an expense greater than the available balance
    BEGIN
        PERFORM public.create_transaction(
            p_wallet_id := v_wallet_id,
            p_type := 'expense',
            p_amount := 150000,
            p_transaction_date := CURRENT_DATE,
            p_category_id := v_category_id
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM = 'Insufficient wallet balance' THEN
                v_error_caught := TRUE;
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'Expected insufficient balance error was not raised';
    END IF;

    -- Verify that the wallet balance remains unchanged
    SELECT balance
    INTO v_balance
    FROM public.wallets
    WHERE id = v_wallet_id;

    IF v_balance <> 100000 THEN
        RAISE EXCEPTION 'Expected balance 100000, got %', v_balance;
    END IF;
END;
$$;

SELECT 'Insufficient balance test passed' AS test_status;

ROLLBACK;