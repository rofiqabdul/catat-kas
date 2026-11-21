SELECT
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'handle_new_user'; 