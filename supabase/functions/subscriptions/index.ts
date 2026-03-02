import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authHeader = req.headers.get("Authorization")!;

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const url = new URL(req.url);
    const pathParts = url.pathname.split("/").filter(Boolean);
    const method = req.method;

    if (method === "GET") {
      const { data: subscriptions, error } = await supabase
        .from("user_subscriptions")
        .select(`
          *,
          plan:subscription_plans(*),
          service:service_types(*)
        `)
        .eq("user_id", user.id)
        .order("created_at", { ascending: false });

      if (error) throw error;

      return new Response(
        JSON.stringify({ subscriptions }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (method === "POST") {
      const body = await req.json();
      const { plan_id, service_type_id, start_date } = body;

      if (!plan_id || !service_type_id || !start_date) {
        return new Response(
          JSON.stringify({ error: "Missing required fields" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { data: plan } = await supabase
        .from("subscription_plans")
        .select("*")
        .eq("id", plan_id)
        .single();

      const { data: serviceType } = await supabase
        .from("service_types")
        .select("*")
        .eq("id", service_type_id)
        .single();

      if (!plan || !serviceType) {
        return new Response(
          JSON.stringify({ error: "Invalid plan or service type" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const subscriptionData = {
        user_id: user.id,
        plan_id,
        service_type_id,
        start_date,
        status: "pending",
        payment_status: "pending",
        total_washes_used: 0,
      };

      const { data: subscription, error: subError } = await supabase
        .from("user_subscriptions")
        .insert(subscriptionData)
        .select(`
          *,
          plan:subscription_plans(*),
          service:service_types(*)
        `)
        .single();

      if (subError) throw subError;

      const amount = plan.price * serviceType.base_price_modifier;
      const transactionId = `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

      const { data: payment, error: payError } = await supabase
        .from("payments")
        .insert({
          user_id: user.id,
          subscription_id: subscription.id,
          amount,
          payment_method: "mobile_money",
          status: "pending",
          transaction_id: transactionId,
        })
        .select()
        .single();

      if (payError) throw payError;

      const { error: notifError } = await supabase
        .from("notifications")
        .insert({
          user_id: user.id,
          title: "Subscription Created",
          message: `Your ${plan.name} subscription has been created. Please complete the payment.`,
          type: "subscription",
          read: false,
        });

      if (notifError) throw notifError;

      return new Response(
        JSON.stringify({ subscription, payment }),
        {
          status: 201,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (method === "PUT") {
      const subscriptionId = pathParts[pathParts.length - 1];
      const body = await req.json();

      const { data: subscription, error } = await supabase
        .from("user_subscriptions")
        .update(body)
        .eq("id", subscriptionId)
        .eq("user_id", user.id)
        .select(`
          *,
          plan:subscription_plans(*),
          service:service_types(*)
        `)
        .single();

      if (error) throw error;

      return new Response(
        JSON.stringify({ subscription }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (method === "DELETE") {
      const subscriptionId = pathParts[pathParts.length - 1];

      const { error } = await supabase
        .from("user_subscriptions")
        .delete()
        .eq("id", subscriptionId)
        .eq("user_id", user.id);

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
