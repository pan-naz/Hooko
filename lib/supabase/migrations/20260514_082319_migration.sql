-- Fix duplicate viral_examples rows and prevent future duplicates.
--
-- Root cause: two concurrent invocations of `populate-viral-examples-v2` raced
-- each other. Both queried existing rows at the same time (saw none), both ran
-- the same YouTube search (sorted by view count, so they picked the same top
-- candidates), and both inserted the same videos before either could observe
-- the other's writes. In-process Sets cannot prevent this — only the DB can.

-- 1) Remove existing duplicate rows. Keep the oldest row per (niche_id, youtube_url).
DELETE FROM viral_examples ve
USING viral_examples dupe
WHERE ve.niche_id = dupe.niche_id
  AND ve.youtube_url = dupe.youtube_url
  AND ve.created_at > dupe.created_at;

-- 2) Add a unique constraint so the DB itself rejects duplicate inserts even
--    when two invocations race. After this is applied, a racing duplicate
--    insert will return a 23505 error from Postgres instead of silently
--    creating a duplicate row.
ALTER TABLE viral_examples
  ADD CONSTRAINT viral_examples_niche_url_unique UNIQUE (niche_id, youtube_url);
