
-- Delete a transaction and restore its wallet balances atomically
CREATE OR REPLACE FUNCTION public.delete_transaction(
    p_transaction_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_transaction public.transactions%ROWTYPE;
    v_receipt_path TEXT;
BEGIN
    -- Validate the authenticated user
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    -- Validate the transaction ID
    IF p_transaction_id IS NULL THEN
        RAISE EXCEPTION 'Transaction ID is required';
    END IF;

    -- Lock and retrieve the transaction
    SELECT *
    INTO v_transaction
    FROM public.transactions
    WHERE id = p_transaction_id
      AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction was not found';
    END IF;

    -- Debt-related transactions must be managed through debt functions
    IF v_transaction.debt_id IS NOT NULL THEN
        RAISE EXCEPTION 'Debt-related transactions cannot be deleted with this function';
    END IF;

    -- Lock all involved wallets in a consistent order
    PERFORM 1
    FROM public.wallets
    WHERE user_id = v_user_id
      AND id IN (
          v_transaction.wallet_id,
          v_transaction.destination_wallet_id
      )
    ORDER BY id
    FOR UPDATE;

    -- Restore the original transaction effect
    IF v_transaction.type = 'income' THEN
        UPDATE public.wallets
        SET balance = balance - v_transaction.amount
        WHERE id = v_transaction.wallet_id
          AND user_id = v_user_id
          AND balance >= v_transaction.amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot delete income because its funds have already been spent';
        END IF;

    ELSIF v_transaction.type = 'expense' THEN
        UPDATE public.wallets
        SET balance = balance + v_transaction.amount
        WHERE id = v_transaction.wallet_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transaction wallet was not found';
        END IF;

    ELSIF v_transaction.type = 'transfer' THEN
        -- Restore the source wallet
        UPDATE public.wallets
        SET balance = balance + v_transaction.amount
        WHERE id = v_transaction.wallet_id
          AND user_id = v_user_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transfer source wallet was not found';
        END IF;

        -- Deduct the amount from the destination wallet
        UPDATE public.wallets
        SET balance = balance - v_transaction.amount
        WHERE id = v_transaction.destination_wallet_id
          AND user_id = v_user_id
          AND balance >= v_transaction.amount;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot delete transfer because its destination funds have already been spent';
        END IF;

    ELSE
        RAISE EXCEPTION 'Unsupported transaction type';
    END IF;

    -- Delete the transaction and capture its receipt path
    DELETE FROM public.transactions
    WHERE id = p_transaction_id
      AND user_id = v_user_id
    RETURNING receipt_path INTO v_receipt_path;

    RETURN v_receipt_path;
END;
$$;
