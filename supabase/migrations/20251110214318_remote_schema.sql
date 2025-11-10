


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."agreements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "provider_name" "text" NOT NULL,
    "category" "text" DEFAULT 'other'::"text",
    "plan_label" "text",
    "price_cents" integer,
    "currency" "text" DEFAULT 'EUR'::"text",
    "billing_cycle" "text" DEFAULT 'monthly'::"text",
    "start_date" "date",
    "trial_end" "date",
    "renewal_date" "date",
    "min_term_rule" "text",
    "notice_rule" "text",
    "earliest_end" "date",
    "status" "text" DEFAULT 'active'::"text",
    "cancel_web_url" "text",
    "cancel_store" "text",
    "cancel_email" "text",
    "cancel_postal_address" "text",
    "confidence" numeric DEFAULT 0.0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "agreements_billing_cycle_check" CHECK (("billing_cycle" = ANY (ARRAY['weekly'::"text", 'monthly'::"text", 'yearly'::"text", 'oneoff'::"text"]))),
    CONSTRAINT "agreements_cancel_store_check" CHECK (("cancel_store" = ANY (ARRAY['apple'::"text", 'google'::"text"]))),
    CONSTRAINT "agreements_category_check" CHECK (("category" = ANY (ARRAY['gym'::"text", 'mobile'::"text", 'internet'::"text", 'streaming'::"text", 'software'::"text", 'retail'::"text", 'warranty'::"text", 'other'::"text"]))),
    CONSTRAINT "agreements_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cancelled'::"text", 'paused'::"text"])))
);


ALTER TABLE "public"."agreements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "id" integer DEFAULT 1 NOT NULL,
    "min_supported_version" "text",
    "latest_version" "text",
    "message" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agreement_id" "uuid",
    "kind" "text",
    "file_url" "text" NOT NULL,
    "uploaded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."feature_flags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."i18n_strings" (
    "key" "text" NOT NULL,
    "locale" "text" NOT NULL,
    "text" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."i18n_strings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."letter_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "locale" "text" NOT NULL,
    "kind" "text" NOT NULL,
    "subject_tpl" "text" NOT NULL,
    "body_tpl" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."letter_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."letters" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agreement_id" "uuid",
    "kind" "text" DEFAULT 'ordinary'::"text",
    "pdf_url" "text",
    "email_subject" "text",
    "email_body" "text",
    "status" "text" DEFAULT 'draft'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "letters_kind_check" CHECK (("kind" = ANY (ARRAY['ordinary'::"text", 'extra_relocation'::"text", 'extra_price'::"text", 'extra_servicefailure'::"text"]))),
    CONSTRAINT "letters_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'sent'::"text", 'posted'::"text", 'confirmed'::"text"])))
);


ALTER TABLE "public"."letters" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."policy_hints" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agreement_id" "uuid" NOT NULL,
    "source_signal_id" "uuid",
    "label" "text",
    "text" "text",
    "importance" integer DEFAULT 2,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "policy_hints_importance_check" CHECK ((("importance" >= 1) AND ("importance" <= 3)))
);


ALTER TABLE "public"."policy_hints" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "user_id" "uuid" NOT NULL,
    "locale" "text" DEFAULT 'auto'::"text",
    "country_code" "text",
    "timezone" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reminders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agreement_id" "uuid",
    "due_at" timestamp with time zone NOT NULL,
    "channel" "text" DEFAULT 'push'::"text",
    "kind" "text",
    "sent_at" timestamp with time zone,
    CONSTRAINT "reminders_channel_check" CHECK (("channel" = ANY (ARRAY['email'::"text", 'push'::"text"]))),
    CONSTRAINT "reminders_kind_check" CHECK (("kind" = ANY (ARRAY['trial'::"text", 'renewal'::"text", 'notice'::"text", 'followup'::"text"])))
);


ALTER TABLE "public"."reminders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."signals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agreement_id" "uuid",
    "kind" "text" NOT NULL,
    "seen_at" timestamp with time zone DEFAULT "now"(),
    "payload" "jsonb",
    "raw_ref" "text",
    CONSTRAINT "signals_kind_check" CHECK (("kind" = ANY (ARRAY['email'::"text", 'upload'::"text", 'manual'::"text", 'bank'::"text", 'calendar'::"text"])))
);


ALTER TABLE "public"."signals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vendors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "locale" "text" DEFAULT 'en'::"text",
    "cancel_web_url" "text",
    "support_email" "text",
    "store_provider" "text",
    "hints" "jsonb",
    CONSTRAINT "vendors_store_provider_check" CHECK (("store_provider" = ANY (ARRAY['apple'::"text", 'google'::"text"])))
);


ALTER TABLE "public"."vendors" OWNER TO "postgres";


ALTER TABLE ONLY "public"."agreements"
    ADD CONSTRAINT "agreements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."i18n_strings"
    ADD CONSTRAINT "i18n_strings_pkey" PRIMARY KEY ("key", "locale");



ALTER TABLE ONLY "public"."letter_templates"
    ADD CONSTRAINT "letter_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."letters"
    ADD CONSTRAINT "letters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."policy_hints"
    ADD CONSTRAINT "policy_hints_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."signals"
    ADD CONSTRAINT "signals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vendors"
    ADD CONSTRAINT "vendors_pkey" PRIMARY KEY ("id");



CREATE INDEX "agreements_renewal_date_idx" ON "public"."agreements" USING "btree" ("renewal_date");



CREATE INDEX "agreements_user_id_idx" ON "public"."agreements" USING "btree" ("user_id");



CREATE INDEX "reminders_user_id_due_at_idx" ON "public"."reminders" USING "btree" ("user_id", "due_at");



CREATE INDEX "signals_user_id_seen_at_idx" ON "public"."signals" USING "btree" ("user_id", "seen_at");



ALTER TABLE ONLY "public"."agreements"
    ADD CONSTRAINT "agreements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "public"."agreements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."letters"
    ADD CONSTRAINT "letters_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "public"."agreements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."letters"
    ADD CONSTRAINT "letters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."policy_hints"
    ADD CONSTRAINT "policy_hints_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "public"."agreements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."policy_hints"
    ADD CONSTRAINT "policy_hints_source_signal_id_fkey" FOREIGN KEY ("source_signal_id") REFERENCES "public"."signals"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "public"."agreements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."signals"
    ADD CONSTRAINT "signals_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "public"."agreements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."signals"
    ADD CONSTRAINT "signals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."agreements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feature_flags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."i18n_strings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."letter_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."letters" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "own_agreements" ON "public"."agreements" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_attachments" ON "public"."attachments" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_letters" ON "public"."letters" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_profile" ON "public"."profiles" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_reminders" ON "public"."reminders" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "own_signals" ON "public"."signals" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."policy_hints" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "read_config" ON "public"."app_config" FOR SELECT USING (true);



CREATE POLICY "read_flags" ON "public"."feature_flags" FOR SELECT USING (true);



CREATE POLICY "read_i18n" ON "public"."i18n_strings" FOR SELECT USING (true);



CREATE POLICY "read_letters_tpl" ON "public"."letter_templates" FOR SELECT USING (true);



CREATE POLICY "read_vendors" ON "public"."vendors" FOR SELECT USING (true);



ALTER TABLE "public"."reminders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."signals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vendors" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sign"("payload" json, "secret" "text", "algorithm" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."sign"("payload" json, "secret" "text", "algorithm" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."sign"("payload" json, "secret" "text", "algorithm" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sign"("payload" json, "secret" "text", "algorithm" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."try_cast_double"("inp" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."try_cast_double"("inp" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."try_cast_double"("inp" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."try_cast_double"("inp" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."url_decode"("data" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."url_decode"("data" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."url_decode"("data" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."url_decode"("data" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."url_encode"("data" "bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."url_encode"("data" "bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."url_encode"("data" "bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."url_encode"("data" "bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."verify"("token" "text", "secret" "text", "algorithm" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."verify"("token" "text", "secret" "text", "algorithm" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify"("token" "text", "secret" "text", "algorithm" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify"("token" "text", "secret" "text", "algorithm" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."agreements" TO "anon";
GRANT ALL ON TABLE "public"."agreements" TO "authenticated";
GRANT ALL ON TABLE "public"."agreements" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."attachments" TO "anon";
GRANT ALL ON TABLE "public"."attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."attachments" TO "service_role";



GRANT ALL ON TABLE "public"."feature_flags" TO "anon";
GRANT ALL ON TABLE "public"."feature_flags" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_flags" TO "service_role";



GRANT ALL ON TABLE "public"."i18n_strings" TO "anon";
GRANT ALL ON TABLE "public"."i18n_strings" TO "authenticated";
GRANT ALL ON TABLE "public"."i18n_strings" TO "service_role";



GRANT ALL ON TABLE "public"."letter_templates" TO "anon";
GRANT ALL ON TABLE "public"."letter_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."letter_templates" TO "service_role";



GRANT ALL ON TABLE "public"."letters" TO "anon";
GRANT ALL ON TABLE "public"."letters" TO "authenticated";
GRANT ALL ON TABLE "public"."letters" TO "service_role";



GRANT ALL ON TABLE "public"."policy_hints" TO "anon";
GRANT ALL ON TABLE "public"."policy_hints" TO "authenticated";
GRANT ALL ON TABLE "public"."policy_hints" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."reminders" TO "anon";
GRANT ALL ON TABLE "public"."reminders" TO "authenticated";
GRANT ALL ON TABLE "public"."reminders" TO "service_role";



GRANT ALL ON TABLE "public"."signals" TO "anon";
GRANT ALL ON TABLE "public"."signals" TO "authenticated";
GRANT ALL ON TABLE "public"."signals" TO "service_role";



GRANT ALL ON TABLE "public"."vendors" TO "anon";
GRANT ALL ON TABLE "public"."vendors" TO "authenticated";
GRANT ALL ON TABLE "public"."vendors" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";


  create policy "letters delete own"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'letters'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



  create policy "letters insert own"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'letters'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



  create policy "letters read own"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'letters'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



  create policy "uploads delete own"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'uploads'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



  create policy "uploads insert own"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'uploads'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



  create policy "uploads read own"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'uploads'::text) AND (SUBSTRING(name FROM 1 FOR 36) = (auth.uid())::text)));



