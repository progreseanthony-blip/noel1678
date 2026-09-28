import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import nodemailer from "npm:nodemailer@6.9.14";

const MAX_ATTACHMENT_BYTES = 9 * 1024 * 1024;
const ALLOWED_DOC_TYPES = new Set([
  "pay_application",
  "estimate",
  "payroll",
  "change_order",
  "document",
]);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isValidEmail(value: unknown): value is string {
  return (
    typeof value === "string" &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { error: "Method not allowed" });
  }

  // 1. Auth: require an authenticated user (RLS-equivalent gate).
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user == null) {
    return json(401, { error: "Unauthorized" });
  }

  // 2. Parse + validate payload.
  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "Invalid JSON body" });
  }

  const to = payload["to"];
  const cc = payload["cc"];
  const subject = (payload["subject"] as string ?? "").trim();
  const body = (payload["body"] as string ?? "").trim();
  const fileName = (payload["fileName"] as string ?? "document.pdf").trim();
  const pdfBase64 = payload["pdfBase64"];
  const docType = (payload["docType"] as string ?? "document").trim();
  const projectId = payload["projectId"] as string | undefined;
  const invoiceId = payload["invoiceId"] as string | undefined;
  const quoteId = payload["quoteId"] as string | undefined;

  if (!isValidEmail(to)) {
    return json(400, { error: "Invalid recipient email (to)" });
  }
  if (cc != null && cc !== "" && !isValidEmail(cc)) {
    return json(400, { error: "Invalid CC email" });
  }
  if (subject.length === 0) {
    return json(400, { error: "Subject is required" });
  }
  if (typeof pdfBase64 !== "string" || pdfBase64.length === 0) {
    return json(400, { error: "pdfBase64 attachment is required" });
  }
  if (!ALLOWED_DOC_TYPES.has(docType)) {
    return json(400, { error: `Invalid docType: ${docType}` });
  }
  // Rough base64 size check (4/3 overhead).
  if (pdfBase64.length > (MAX_ATTACHMENT_BYTES * 4) / 3) {
    return json(413, { error: "Attachment too large (max ~9 MB)" });
  }

  // 3. SMTP config from function secrets (never in repo).
  const smtpHost = Deno.env.get("SMTP_HOST") ?? "";
  const smtpPort = Number(Deno.env.get("SMTP_PORT") ?? "465");
  const smtpUser = Deno.env.get("SMTP_USER") ?? "";
  const smtpPass = Deno.env.get("SMTP_PASS") ?? "";
  const smtpFrom = Deno.env.get("SMTP_FROM") ?? smtpUser;
  if (!smtpHost || !smtpUser || !smtpPass) {
    return json(500, { error: "Email service not configured" });
  }

  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: { user: smtpUser, pass: smtpPass },
  });

  const toAddr = (to as string).trim();
  try {
    await transporter.sendMail({
      from: smtpFrom,
      to: toAddr,
      cc: typeof cc === "string" && cc.trim() !== "" ? cc.trim() : undefined,
      subject,
      text: body,
      attachments: [
        {
          filename: fileName,
          content: pdfBase64,
          encoding: "base64",
          contentType: "application/pdf",
        },
      ],
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    await supabase.from("email_logs").insert({
      recipient_to: toAddr,
      recipient_cc: typeof cc === "string" ? cc.trim() : null,
      subject,
      doc_type: docType,
      project_id: projectId ?? null,
      invoice_id: invoiceId ?? null,
      quote_id: quoteId ?? null,
      file_name: fileName,
      status: "failed",
      error_message: message.substring(0, 1000),
      created_by: user.id,
    });
    return json(502, { error: `SMTP send failed: ${message}` });
  }

  // 4. Audit log.
  await supabase.from("email_logs").insert({
    recipient_to: toAddr,
    recipient_cc: typeof cc === "string" ? cc.trim() : null,
    subject,
    doc_type: docType,
    project_id: projectId ?? null,
    invoice_id: invoiceId ?? null,
    quote_id: quoteId ?? null,
    file_name: fileName,
    status: "sent",
    created_by: user.id,
  });

  return json(200, { ok: true });
});
