-- Create a private storage bucket for receipt images.
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'receipts',
    'receipts',
    FALSE,
    307200,
    ARRAY[
        'image/webp',
        'image/jpeg'
    ]
)
ON CONFLICT (id) DO UPDATE
SET
    public = FALSE,
    file_size_limit = 307200,
    allowed_mime_types = ARRAY[
        'image/webp',
        'image/jpeg'
    ];

-- Allow users to upload receipt files into their own folder.
CREATE POLICY "Users can upload their own receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
);

-- Allow users to view their own receipt files.
CREATE POLICY "Users can view their own receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
);

-- Allow users to delete their own receipt files.
CREATE POLICY "Users can delete their own receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::TEXT
);
