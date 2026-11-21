
BEGIN;

SELECT set_config(
    'request.jwt.claim.sub',
    '6a9cfae6-0a51-4743-8ae9-729c192b8742',
    TRUE
);

DO $$
DECLARE
    v_user_id UUID := '6a9cfae6-0a51-4743-8ae9-729c192b8742';

    v_business_wallet UUID := gen_random_uuid();
    v_personal_wallet UUID := gen_random_uuid();

    v_receivable_id UUID := gen_random_uuid();
    v_payable_id UUID := gen_random_uuid();
    v_no_wallet_id UUID := gen_random_uuid();
    v_insufficient_id UUID := gen_random_uuid();

    v_transaction_id UUID;
    v_transaction_count BIGINT;
    v_balance NUMERIC(15, 2);
    v_remaining NUMERIC(15, 2);
    v_status TEXT;
    v_error TEXT;
BEGIN
    -- Create test wallets.
    INSERT INTO public.wallets (
        id, user_id, name, scope, balance, is_archived
    )
    VALUES
        (
            v_business_wallet, v_user_id,
            'Pay Debt Test Business Wallet',
            'business', 500, FALSE
        ),
        (
            v_personal_wallet, v_user_id,
            'Pay Debt Test Personal Wallet',
            'personal', 20, FALSE
        );

    -- Create a receivable debt with wallet impact.
    INSERT INTO public.debts (
        id, user_id, wallet_id, type, person_name,
        total_amount, remaining_amount, affect_wallet,
        status, note
    )
    VALUES (
        v_receivable_id, v_user_id, v_business_wallet,
        'receivable', 'Receivable Test',
        300, 300, TRUE, 'unpaid', NULL
    );

    -- Create a payable debt with wallet impact.
    INSERT INTO public.debts (
        id, user_id, wallet_id, type, person_name,
        total_amount, remaining_amount, affect_wallet,
        status, note
    )
    VALUES (
        v_payable_id, v_user_id, v_business_wallet,
        'payable', 'Payable Test',
        200, 200, TRUE, 'unpaid', NULL
    );

    -- Create a debt without wallet impact.
    INSERT INTO public.debts (
        id, user_id, wallet_id, type, person_name,
        total_amount, remaining_amount, affect_wallet,
        status, note
    )
    VALUES (
        v_no_wallet_id, v_user_id, NULL,
        'receivable', 'No Wallet Test',
        150, 150, FALSE, 'unpaid', NULL
    );

    -- Create a payable debt that exceeds the personal wallet balance.
    INSERT INTO public.debts (
        id, user_id, wallet_id, type, person_name,
        total_amount, remaining_amount, affect_wallet,
        status, note
    )
    VALUES (
        v_insufficient_id, v_user_id, v_personal_wallet,
        'payable', 'Insufficient Balance Test',
        100, 100, TRUE, 'unpaid', NULL
    );

    -- TEST 1: Partial receivable payment.
    v_transaction_id := public.pay_debt(
        v_receivable_id, 100, 'Receivable partial payment'
    );

    IF v_transaction_id IS NULL THEN
        RAISE EXCEPTION 'Receivable payment did not return a transaction ID';
    END IF;

    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_business_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_receivable_id;

    IF v_balance <> 600
       OR v_remaining <> 200
       OR v_status <> 'partial'
    THEN
        RAISE EXCEPTION
            'Receivable partial payment failed: balance %, remaining %, status %',
            v_balance, v_remaining, v_status;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.transactions
        WHERE id = v_transaction_id
          AND debt_id = v_receivable_id
          AND type = 'income'
          AND amount = 100
          AND note = 'Receivable partial payment'
    ) THEN
        RAISE EXCEPTION 'Receivable income transaction validation failed';
    END IF;

    -- TEST 2: Full receivable settlement.
    v_transaction_id := public.pay_debt(
        v_receivable_id, 200
    );

    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_business_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_receivable_id;

    IF v_balance <> 800
       OR v_remaining <> 0
       OR v_status <> 'paid'
    THEN
        RAISE EXCEPTION
            'Receivable settlement failed: balance %, remaining %, status %',
            v_balance, v_remaining, v_status;
    END IF;

    -- TEST 3: Partial payable repayment.
    v_transaction_id := public.pay_debt(
        v_payable_id, 50
    );

    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_business_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_payable_id;

    IF v_balance <> 750
       OR v_remaining <> 150
       OR v_status <> 'partial'
    THEN
        RAISE EXCEPTION
            'Payable partial repayment failed: balance %, remaining %, status %',
            v_balance, v_remaining, v_status;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.transactions
        WHERE id = v_transaction_id
          AND debt_id = v_payable_id
          AND type = 'expense'
          AND amount = 50
    ) THEN
        RAISE EXCEPTION 'Payable expense transaction validation failed';
    END IF;

    -- TEST 4: Full payable settlement.
    v_transaction_id := public.pay_debt(
        v_payable_id, 150
    );

    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_business_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_payable_id;

    IF v_balance <> 600
       OR v_remaining <> 0
       OR v_status <> 'paid'
    THEN
        RAISE EXCEPTION
            'Payable settlement failed: balance %, remaining %, status %',
            v_balance, v_remaining, v_status;
    END IF;

    -- TEST 5: Payment without wallet impact.
    v_transaction_id := public.pay_debt(
        v_no_wallet_id, 50
    );

    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_business_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_no_wallet_id;

    IF v_transaction_id IS NOT NULL
       OR v_balance <> 600
       OR v_remaining <> 100
       OR v_status <> 'partial'
    THEN
        RAISE EXCEPTION
            'No-wallet partial payment failed: transaction %, balance %, remaining %, status %',
            v_transaction_id, v_balance, v_remaining, v_status;
    END IF;

    -- Complete the no-wallet debt.
    v_transaction_id := public.pay_debt(
        v_no_wallet_id, 100
    );

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_no_wallet_id;

    IF v_transaction_id IS NOT NULL
       OR v_remaining <> 0
       OR v_status <> 'paid'
    THEN
        RAISE EXCEPTION 'No-wallet full settlement failed';
    END IF;

    -- TEST 6: Reject payment exceeding remaining amount.
    v_error := NULL;

    BEGIN
        PERFORM public.pay_debt(v_no_wallet_id, 1);
    EXCEPTION WHEN OTHERS THEN
        v_error := SQLERRM;
    END;

    IF v_error IS NULL
       OR v_error <> 'Debt has already been fully paid'
    THEN
        RAISE EXCEPTION
            'Expected fully-paid debt rejection, received: %',
            v_error;
    END IF;

    -- TEST 7: Reject insufficient wallet balance.
    v_error := NULL;

    BEGIN
        PERFORM public.pay_debt(v_insufficient_id, 50);
    EXCEPTION WHEN OTHERS THEN
        v_error := SQLERRM;
    END;

    IF v_error IS NULL
       OR v_error <> 'Insufficient wallet balance'
    THEN
        RAISE EXCEPTION
            'Expected insufficient balance rejection, received: %',
            v_error;
    END IF;

    -- Verify failed payment did not change debt or wallet.
    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE id = v_personal_wallet;

    SELECT remaining_amount, status
    INTO v_remaining, v_status
    FROM public.debts
    WHERE id = v_insufficient_id;

    IF v_balance <> 20
       OR v_remaining <> 100
       OR v_status <> 'unpaid'
    THEN
        RAISE EXCEPTION
            'Insufficient balance rejection changed existing data';
    END IF;

    -- TEST 8: Reject overpayment.
    v_error := NULL;

    BEGIN
        PERFORM public.pay_debt(v_insufficient_id, 150);
    EXCEPTION WHEN OTHERS THEN
        v_error := SQLERRM;
    END;

    IF v_error IS NULL
       OR v_error <> 'Payment amount exceeds remaining debt'
    THEN
        RAISE EXCEPTION
            'Expected overpayment rejection, received: %',
            v_error;
    END IF;

    -- Verify no transaction was created for the no-wallet debt.
    SELECT COUNT(*) INTO v_transaction_count
    FROM public.transactions
    WHERE debt_id = v_no_wallet_id;

    IF v_transaction_count <> 0 THEN
        RAISE EXCEPTION
            'No-wallet debt unexpectedly created % transactions',
            v_transaction_count;
    END IF;

    RAISE NOTICE 'All pay_debt functional tests passed.';
END;
$$;

ROLLBACK;
