BEGIN;

SET LOCAL ROLE authenticated;

SELECT set_config(
    'request.jwt.claim.sub',
    '73b8fe57-304f-4fd5-98bd-08700c55a4a7',
    TRUE
);

DO $$
DECLARE
    v_business_wallet_id UUID;
    v_personal_wallet_id UUID;
    v_transaction_id UUID;
    v_business_balance NUMERIC(15, 2);
    v_personal_balance NUMERIC(15, 2);
    v_is_cross_scope BOOLEAN;
BEGIN
    -- Create temporary test wallets
    INSERT INTO public.wallets (user_id, name, scope, balance)
    VALUES (auth.uid(), 'RPC Transfer Business', 'business', 1000000)
    RETURNING id INTO v_business_wallet_id;

    INSERT INTO public.wallets (user_id, name, scope, balance)
    VALUES (auth.uid(), 'RPC Transfer Personal', 'personal', 500000)
    RETURNING id INTO v_personal_wallet_id;

    -- Execute cross-scope transfer
    v_transaction_id := public.create_transaction(
        p_wallet_id := v_business_wallet_id,
        p_type := 'transfer',
        p_amount := 300000,
        p_transaction_date := CURRENT_DATE,
        p_destination_wallet_id := v_personal_wallet_id
    );

    -- Verify both wallet balances
    SELECT balance INTO v_business_balance
    FROM public.wallets
    WHERE id = v_business_wallet_id;

    SELECT balance INTO v_personal_balance
    FROM public.wallets
    WHERE id = v_personal_wallet_id;

    -- Verify transfer classification
    SELECT is_cross_scope INTO v_is_cross_scope
    FROM public.transactions
    WHERE id = v_transaction_id;

    IF v_business_balance <> 700000 THEN
        RAISE EXCEPTION 'Expected business balance 700000, got %',
            v_business_balance;
    END IF;

    IF v_personal_balance <> 800000 THEN
        RAISE EXCEPTION 'Expected personal balance 800000, got %',
            v_personal_balance;
    END IF;

    IF v_is_cross_scope IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Expected is_cross_scope to be TRUE';
    END IF;
END;
$$;

SELECT 'Cross-scope transfer test passed' AS test_status;

ROLLBACK;