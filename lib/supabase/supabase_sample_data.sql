-- Helper function to insert users into auth.users and public.users
CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data into public.users
-- Reference existing user nazariosnz@gmail.com
INSERT INTO public.users (id, email, full_name, avatar_url)
SELECT
  id,
  email,
  'Nazario Sample',
  'https://example.com/avatars/nazario.jpg'
FROM auth.users
WHERE email = 'nazariosnz@gmail.com'
ON CONFLICT (email) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  avatar_url = EXCLUDED.avatar_url;

-- Create additional users for demonstration
SELECT insert_user_to_auth('alice@example.com', 'password123');
SELECT insert_user_to_auth('bob@example.com', 'password123');

INSERT INTO public.users (id, email, full_name, avatar_url)
SELECT
  id,
  email,
  'Alice Wonderland',
  'https://example.com/avatars/alice.jpg'
FROM auth.users
WHERE email = 'alice@example.com'
ON CONFLICT (email) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  avatar_url = EXCLUDED.avatar_url;

INSERT INTO public.users (id, email, full_name, avatar_url)
SELECT
  id,
  email,
  'Bob The Builder',
  'https://example.com/avatars/bob.jpg'
FROM auth.users
WHERE email = 'bob@example.com'
ON CONFLICT (email) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  avatar_url = EXCLUDED.avatar_url;