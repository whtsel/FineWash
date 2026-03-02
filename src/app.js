import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.39.3/+esm';

const supabaseUrl = 'https://0ec90b57d6e95fcbda19832f.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IjBlYzkwYjU3ZDZlOTVmY2JkYTE5ODMyZiIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzQwNDI1ODk4LCJleHAiOjIwNTYwMDE4OTh9.T5j8VT2c-K_DkEoCZSS3Jbl4Q3FBGfXhXv4YFxYdhQ8';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export let currentUser = null;
export let plans = [];
export let serviceTypes = [];
export let subscriptions = [];
export let notifications = [];
export let userProfile = null;

export async function initAuth() {
  const { data: { session } } = await supabase.auth.getSession();

  if (session) {
    currentUser = session.user;
    await loadUserData();
  } else {
    await showAuthModal();
  }

  supabase.auth.onAuthStateChange((event, session) => {
    (async () => {
      if (event === 'SIGNED_IN') {
        currentUser = session.user;
        await loadUserData();
        window.location.reload();
      } else if (event === 'SIGNED_OUT') {
        currentUser = null;
        await showAuthModal();
      }
    })();
  });
}

async function showAuthModal() {
  const authModal = document.createElement('div');
  authModal.id = 'authModal';
  authModal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 10000; display: flex; align-items: center; justify-content: center;';

  authModal.innerHTML = `
    <div style="background: white; padding: 40px; border-radius: 20px; max-width: 400px; width: 90%;">
      <h2 style="margin-bottom: 20px; font-family: 'Playfair Display', serif; color: var(--color-charcoal);">Welcome to FineWash</h2>
      <div id="authForm">
        <input type="email" id="authEmail" placeholder="Email" style="width: 100%; padding: 12px; margin-bottom: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px;">
        <input type="password" id="authPassword" placeholder="Password" style="width: 100%; padding: 12px; margin-bottom: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px;">
        <input type="text" id="authName" placeholder="Full Name (for sign up)" style="width: 100%; padding: 12px; margin-bottom: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px;">
        <button id="signInBtn" style="width: 100%; padding: 14px; background: var(--color-gold-primary); color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; margin-bottom: 8px; cursor: pointer;">Sign In</button>
        <button id="signUpBtn" style="width: 100%; padding: 14px; background: var(--color-charcoal); color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer;">Sign Up</button>
        <div id="authError" style="color: red; margin-top: 12px; font-size: 14px;"></div>
      </div>
    </div>
  `;

  document.body.appendChild(authModal);

  document.getElementById('signInBtn').onclick = async () => {
    const email = document.getElementById('authEmail').value;
    const password = document.getElementById('authPassword').value;

    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      authModal.remove();
    } catch (error) {
      document.getElementById('authError').textContent = error.message;
    }
  };

  document.getElementById('signUpBtn').onclick = async () => {
    const email = document.getElementById('authEmail').value;
    const password = document.getElementById('authPassword').value;
    const name = document.getElementById('authName').value;

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, location: 'Accra' }
        }
      });
      if (error) throw error;
      authModal.remove();
      alert('Account created successfully! Please sign in.');
    } catch (error) {
      document.getElementById('authError').textContent = error.message;
    }
  };
}

async function loadUserData() {
  try {
    await Promise.all([
      loadPlans(),
      loadSubscriptions(),
      loadNotifications(),
      loadProfile()
    ]);
  } catch (error) {
    console.error('Error loading user data:', error);
  }
}

async function loadPlans() {
  try {
    const response = await fetch(`${supabaseUrl}/functions/v1/plans`, {
      headers: {
        'Authorization': `Bearer ${supabaseAnonKey}`,
      },
    });
    const data = await response.json();
    plans = data.plans || [];
    serviceTypes = data.serviceTypes || [];
  } catch (error) {
    console.error('Error loading plans:', error);
    plans = [];
    serviceTypes = [];
  }
}

async function loadSubscriptions() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const response = await fetch(`${supabaseUrl}/functions/v1/subscriptions`, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
      },
    });
    const data = await response.json();
    subscriptions = data.subscriptions || [];
  } catch (error) {
    console.error('Error loading subscriptions:', error);
    subscriptions = [];
  }
}

async function loadNotifications() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const response = await fetch(`${supabaseUrl}/functions/v1/notifications`, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
      },
    });
    const data = await response.json();
    notifications = data.notifications || [];
  } catch (error) {
    console.error('Error loading notifications:', error);
    notifications = [];
  }
}

async function loadProfile() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const response = await fetch(`${supabaseUrl}/functions/v1/profile`, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
      },
    });
    const data = await response.json();
    userProfile = data.profile;
  } catch (error) {
    console.error('Error loading profile:', error);
    userProfile = null;
  }
}

export async function createSubscription(planId, serviceTypeId) {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('Not authenticated');

    const response = await fetch(`${supabaseUrl}/functions/v1/subscriptions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        plan_id: planId,
        service_type_id: serviceTypeId,
        start_date: new Date().toISOString(),
      }),
    });

    if (!response.ok) throw new Error('Failed to create subscription');

    const data = await response.json();
    await loadSubscriptions();
    await loadNotifications();

    return data;
  } catch (error) {
    console.error('Error creating subscription:', error);
    throw error;
  }
}

export async function markNotificationAsRead(notificationId) {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    await fetch(`${supabaseUrl}/functions/v1/notifications/${notificationId}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ read: true }),
    });

    await loadNotifications();
  } catch (error) {
    console.error('Error marking notification as read:', error);
  }
}

export async function signOut() {
  await supabase.auth.signOut();
}
