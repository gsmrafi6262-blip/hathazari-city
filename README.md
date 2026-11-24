# Hathazari City Guide

Premium blue & white bilingual (Bangla + English) directory for Hathazari, Chattogram.

## Current repository
- `index.html`: responsive welcome / splash landing page.
- `supabase/schema.sql`: initial Supabase schema, categories, and row-level security policies.

## Database setup
1. Create a Supabase project.
2. Open **SQL Editor** and run `supabase/schema.sql`.
3. In **Authentication → Providers**, enable Phone and configure an SMS provider.
4. Create the first admin profile after registering a user:
   ```sql
   insert into public.profiles (id, full_name, role)
   values ('AUTH_USER_UUID', 'Site Admin', 'admin');
   ```
   Replace `AUTH_USER_UUID` with the authenticated user's UUID. Do not expose service-role keys in frontend code.

## Planned application modules
User app: splash/welcome, dashboard, search, categories, hospitals, doctors, hotels/restaurants, shopping/markets, schools/colleges, mosques, transport, emergency services, tourist places, business details, maps, favorites, notifications, profile, business registration, About Hathazari.

Admin: dashboard statistics, category/business/hospital/doctor/user management, business approval, advertisements, featured places, reviews, push notifications, reports, and settings.

## Important
The current landing page is a UI starter, not yet a complete production app. Phone OTP, live database CRUD, admin authorization UI, push notifications, and deployment require Supabase project configuration and further implementation/testing. Never commit `.env`, passwords, or Supabase service-role keys.
