
CREATE OR REPLACE FUNCTION public.get_monthly_report(
    p_month_year TEXT,
    p_scope TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_start_date DATE;
    v_end_date DATE;
    v_result JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication is required';
    END IF;

    IF p_month_year IS NULL
       OR p_month_year !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' THEN
        RAISE EXCEPTION 'Month must use YYYY-MM format';
    END IF;

    IF p_scope IS NULL
       OR p_scope NOT IN ('business', 'personal', 'both') THEN
        RAISE EXCEPTION 'Invalid report scope';
    END IF;

    v_start_date := pg_catalog.make_date(
        pg_catalog.substring(p_month_year, 1, 4)::INTEGER,
        pg_catalog.substring(p_month_year, 6, 2)::INTEGER,
        1
    );

    v_end_date := (v_start_date + INTERVAL '1 month')::DATE;

    WITH report_transactions AS (
        SELECT
            t.category_id,
            t.type,
            t.amount,
            t.wallet_id,
            t.transaction_date,
            c.name AS category_name
        FROM public.transactions AS t
        INNER JOIN public.wallets AS w
            ON w.id = t.wallet_id
           AND w.user_id = v_user_id
        LEFT JOIN public.categories AS c
            ON c.id = t.category_id
           AND c.user_id = v_user_id
        WHERE t.user_id = v_user_id
          AND t.transaction_date >= v_start_date
          AND t.transaction_date < v_end_date
          AND t.type IN ('income', 'expense')
          AND (
              p_scope = 'both'
              OR w.scope = p_scope
          )
    ),
    summary AS (
        SELECT
            COALESCE(
                SUM(amount) FILTER (WHERE type = 'income'),
                0
            ) AS total_income,
            COALESCE(
                SUM(amount) FILTER (WHERE type = 'expense'),
                0
            ) AS total_expense
        FROM report_transactions
    ),
    category_totals AS (
        SELECT
            category_id,
            category_name,
            type,
            SUM(amount) AS total_amount,
            COUNT(*) AS transaction_count
        FROM report_transactions
        WHERE category_id IS NOT NULL
        GROUP BY category_id, category_name, type
    ),
    budget_totals AS (
        SELECT
            b.category_id,
            c.name AS category_name,
            b.amount_limit,
            COALESCE(
                SUM(rt.amount),
                0
            ) AS spent_amount
        FROM public.budgets AS b
        INNER JOIN public.categories AS c
            ON c.id = b.category_id
           AND c.user_id = v_user_id
        LEFT JOIN report_transactions AS rt
            ON rt.category_id = b.category_id
           AND rt.type = 'expense'
        WHERE b.user_id = v_user_id
          AND b.month_year = p_month_year
          AND c.type = 'expense'
          AND (
              p_scope = 'both'
              OR c.scope = 'both'
              OR c.scope = p_scope
          )
        GROUP BY
            b.category_id,
            c.name,
            b.amount_limit
    )
    SELECT pg_catalog.jsonb_build_object(
        'month_year', p_month_year,
        'scope', p_scope,

        'summary', pg_catalog.jsonb_build_object(
            'total_income', s.total_income,
            'total_expense', s.total_expense,
            'net_amount', s.total_income - s.total_expense
        ),

        'categories', COALESCE(
            (
                SELECT pg_catalog.jsonb_agg(
                    pg_catalog.jsonb_build_object(
                        'category_id', ct.category_id,
                        'category_name', ct.category_name,
                        'type', ct.type,
                        'total_amount', ct.total_amount,
                        'transaction_count', ct.transaction_count
                    )
                    ORDER BY ct.category_name, ct.type
                )
                FROM category_totals AS ct
            ),
            '[]'::JSONB
        ),

        'budgets', COALESCE(
            (
                SELECT pg_catalog.jsonb_agg(
                    pg_catalog.jsonb_build_object(
                        'category_id', bt.category_id,
                        'category_name', bt.category_name,
                        'amount_limit', bt.amount_limit,
                        'spent_amount', bt.spent_amount,
                        'usage_percentage',
                            ROUND(
                                bt.spent_amount
                                / NULLIF(bt.amount_limit, 0) * 100,
                                2
                            )
                    )
                    ORDER BY bt.category_name
                )
                FROM budget_totals AS bt
            ),
            '[]'::JSONB
        )
    )
    INTO v_result
    FROM summary AS s;

    RETURN v_result;
END;
$$;
