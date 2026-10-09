-- Protects the clients table: a client code never changes, and clients are never deleted.
CREATE FUNCTION clients_protect() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('DELETE', 'TRUNCATE') THEN
    RAISE EXCEPTION 'clients cannot be deleted; set status to closed instead';
  END IF;
  IF NEW.code IS DISTINCT FROM OLD.code THEN
    RAISE EXCEPTION 'client code cannot be changed';
  END IF;
  RETURN NEW;
END;
$$;--> statement-breakpoint
CREATE TRIGGER clients_protect_row
  BEFORE UPDATE OR DELETE ON clients
  FOR EACH ROW EXECUTE FUNCTION clients_protect();--> statement-breakpoint
CREATE TRIGGER clients_protect_truncate
  BEFORE TRUNCATE ON clients
  FOR EACH STATEMENT EXECUTE FUNCTION clients_protect();
