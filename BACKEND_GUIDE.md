# FineWash Backend Guide

Your FineWash application now has a complete, production-ready backend powered by Supabase.

## What's Been Set Up

### 1. Database Schema
Complete PostgreSQL database with the following tables:

- **profiles**: User profile information (name, phone, loyalty status, points)
- **subscription_plans**: Available car wash plans (Single, Weekly, Bi-Weekly, Monthly)
- **service_types**: Wash service levels (Basic, Premium, Deluxe)
- **user_subscriptions**: User's active and historical subscriptions
- **car_details**: Vehicle information (make, model, year, color)
- **notifications**: Real-time notification system
- **payments**: Payment transaction records

### 2. Authentication System
Supabase Auth with email/password:
- User registration with automatic profile creation
- Secure JWT-based authentication
- Session management
- Row Level Security (RLS) protecting all user data

### 3. Edge Functions (API Endpoints)

#### Plans API (`/functions/v1/plans`)
- **GET**: Fetch all subscription plans and service types
- Public access (no auth required)
- Supports filtering by category and search

#### Subscriptions API (`/functions/v1/subscriptions`)
- **GET**: Get user's subscriptions with plan and service details
- **POST**: Create new subscription (auto-creates payment record)
- **PUT**: Update subscription status
- **DELETE**: Cancel subscription

#### Notifications API (`/functions/v1/notifications`)
- **GET**: Fetch user notifications with unread count
- **PUT**: Mark notification as read
- **DELETE**: Delete notification

#### Profile API (`/functions/v1/profile`)
- **GET**: Get user profile with stats (current plan, monthly spend, loyalty points)
- **PUT**: Update profile information (name, phone, avatar, location)

### 4. Seeded Data
The database is pre-populated with:
- 4 subscription plans (Single, Weekly, Bi-Weekly, Monthly)
- 3 service types (Basic, Premium, Deluxe)

## How to Use the Backend

### Authentication

#### Sign Up
```javascript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123',
  options: {
    data: {
      name: 'John Doe',
      phone: '+233244123456',
      location: 'Accra'
    }
  }
});
```

#### Sign In
```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
});
```

#### Sign Out
```javascript
await supabase.auth.signOut();
```

### API Calls

#### Get Plans
```javascript
const response = await fetch(
  'https://0ec90b57d6e95fcbda19832f.supabase.co/functions/v1/plans',
  {
    headers: {
      'Authorization': 'Bearer YOUR_ANON_KEY',
    }
  }
);
const { plans, serviceTypes } = await response.json();
```

#### Create Subscription
```javascript
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  'https://0ec90b57d6e95fcbda19832f.supabase.co/functions/v1/subscriptions',
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      plan_id: 'uuid-of-plan',
      service_type_id: 'uuid-of-service-type',
      start_date: new Date().toISOString()
    })
  }
);
const { subscription, payment } = await response.json();
```

#### Get User Subscriptions
```javascript
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  'https://0ec90b57d6e95fcbda19832f.supabase.co/functions/v1/subscriptions',
  {
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
    }
  }
);
const { subscriptions } = await response.json();
```

#### Get Notifications
```javascript
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  'https://0ec90b57d6e95fcbda19832f.supabase.co/functions/v1/notifications',
  {
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
    }
  }
);
const { notifications, unreadCount } = await response.json();
```

#### Get User Profile
```javascript
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  'https://0ec90b57d6e95fcbda19832f.supabase.co/functions/v1/profile',
  {
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
    }
  }
);
const { profile, stats } = await response.json();
```

## Database Structure

### Subscription Plans
```javascript
{
  id: 'uuid',
  name: 'Weekly Plan',
  category: 'weekly',
  description: 'Keep your car consistently clean',
  price: 100.00,
  washes_count: 2,
  wash_frequency: '2 washes per week',
  savings_percentage: 17,
  features: ['Feature 1', 'Feature 2'],
  badge: 'Popular',
  is_active: true
}
```

### User Subscription
```javascript
{
  id: 'uuid',
  user_id: 'uuid',
  plan_id: 'uuid',
  service_type_id: 'uuid',
  status: 'active', // pending, active, completed, cancelled
  start_date: '2024-03-01T00:00:00Z',
  end_date: null,
  next_wash_date: '2024-03-03T10:00:00Z',
  total_washes_used: 0,
  payment_status: 'completed', // pending, completed, failed
  plan: { /* plan object */ },
  service: { /* service type object */ }
}
```

### Notification
```javascript
{
  id: 'uuid',
  user_id: 'uuid',
  title: 'Subscription Created',
  message: 'Your Weekly Plan subscription has been created',
  type: 'subscription', // subscription, payment, reminder, offer
  read: false,
  created_at: '2024-03-01T10:00:00Z'
}
```

## Security Features

- **Row Level Security (RLS)** enabled on all tables
- Users can only access their own data
- JWT-based authentication with secure tokens
- Automatic profile creation on signup
- Loyalty points system with automatic updates
- All API endpoints require authentication (except plans)

## Loyalty System

Users earn loyalty points automatically:
- 1 point per GHS spent
- Bronze: 0-499 points
- Silver: 500-1999 points
- Gold: 2000-4999 points
- Platinum: 5000+ points

Points are calculated automatically when a subscription is completed.

## Next Steps

To fully integrate the backend with your frontend:

1. **Replace hardcoded data** in `index.html` with API calls
2. **Add authentication UI** for sign up/sign in
3. **Connect subscription creation** to the backend
4. **Load real notifications** from the database
5. **Update profile page** to show real user data

The `src/app.js` file contains helper functions you can use for all these operations.

## Testing

You can test the backend by:

1. Creating a test account through the auth modal
2. Viewing the seeded plans (they're already in the database)
3. Creating a subscription
4. Checking notifications
5. Viewing your profile stats

All data persists across sessions and page reloads.
