-- Email audit log for documents sent via the send-document-email edge function.
CREATE TABLE IF NOT EXISTS public.email_logs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_to  text NOT NULL,
  recipient_cc  text,
  subject       text NOT NULL DEFAULT '',
  doc_type      text NOT NULL DEFAULT 'document'
                CHECK (doc_type IN ('pay_application','estimate','payroll','change_order','document')),
  project_id    uuid REFERENCES public.projects(id) ON DELETE SET NULL,
  invoice_id    uuid REFERENCES public.invoices(id) ON DELETE SET NULL,
  quote_id      uuid REFERENCES public.quotes(id) ON DELETE SET NULL,
  file_name     text,
  status        text NOT NULL DEFAULT 'sent'
                CHECK (status IN ('sent','failed')),
  error_message text,
  created_by    uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_logs_project ON public.email_logs(project_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_created ON public.email_logs(created_at DESC);

ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated full access" ON public.email_logs;
CREATE POLICY "Authenticated full access" ON public.email_logs
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);
