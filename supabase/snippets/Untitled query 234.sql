SELECT
    name,
    type,
    scope,
    is_system
FROM public.categories
WHERE user_id = (
    SELECT id
    FROM public.profiles
    WHERE email = 'user@example.com'
)
ORDER BY name;