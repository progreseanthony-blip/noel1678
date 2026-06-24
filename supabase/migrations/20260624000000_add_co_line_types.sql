-- Add change_order_header and change_order_detail to invoice_details line_type check
ALTER TABLE public.invoice_details
  DROP CONSTRAINT IF EXISTS invoice_details_line_type_check;

ALTER TABLE public.invoice_details
  ADD CONSTRAINT invoice_details_line_type_check
    CHECK (line_type = ANY (ARRAY[
      'service'::text,
      'equipment'::text,
      'co_adjustment'::text,
      'change_order_header'::text,
      'change_order_detail'::text
    ]));
