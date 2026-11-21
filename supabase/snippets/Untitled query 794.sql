SELECT
    p.id,
    p.email,
    p.full_name,
    COUNT(c.id) AS category_count
FROM public.profiles p
LEFT JOIN public.categories c
    ON c.user_id = p.id
WHERE p.email = 'user@example.com'
GROUP BY p.id, p.email, p.full_name;