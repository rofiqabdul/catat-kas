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
    v_transaction_id UUID;
    v_balance NUMERIC(15, 2);
BEGIN
    -- Create a temporary test wallet
    INSERT INTO public.wallets (
        user_id, name, scope, balance
    )
    VALUES (
        auth.uid(), 'RPC Income Test', 'business', 1000
    )
    RETURNING id INTO v_wallet_id;

    -- Find the default income category
    SELECT id
    INTO v_category_id
    FROM public.categories
    WHERE user_id = auth.uid()
      AND name = 'Penjualan'
      AND type = 'income'
    LIMIT 1;

    IF v_category_id IS NULL THEN
        RAISE EXCEPTION 'Income category was not found';
    END IF;

    -- Execute the RPC
    v_transaction_id := public.create_transaction(
        p_wallet_id := v_wallet_id,
        p_type := 'income',
        p_amount := 500,
        p_transaction_date := CURRENT_DATE,
        p_category_id := v_category_id
    );

    -- Verify the resulting balance
    SELECT balance
    INTO v_balance
    FROM public.wallets
    WHERE id = v_wallet_id;

    IF v_balance <> 1500 THEN
        RAISE EXCEPTION 'Expected balance 1500, got %', v_balance;
    END IF;
END;
$$;

SELECT 'Income test passed' AS test_status;

ROLLBACK;