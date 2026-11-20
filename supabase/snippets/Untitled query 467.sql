SELECT
    tablename,
    COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN (
        'profiles',
        'wallets',
        'categories',
        'debts',
        'transactions',
        'budgets'
    )
GROUP BY tablename
ORDER BY tablename;