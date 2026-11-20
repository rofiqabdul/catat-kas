SELECT
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN (
        'profiles',
        'wallets',
        'categories',
        'debts',
        'transactions',
        'budgets'
    )
ORDER BY tablename;