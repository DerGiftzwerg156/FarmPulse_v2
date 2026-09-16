-- Marktpreisdaten je Lagerbestand (siehe Bridge/README.md, Abschnitt
-- "Dateiformat: world.json", world.json/storages[]). Nullable, da die
-- Bridge den Preis nicht fuer jeden Fill-Typ zuverlaessig lesen kann (siehe
-- Bridge/README.md, Abschnitt "Bekannte Luecken").
ALTER TABLE storage_snapshot
    ADD COLUMN current_price_per_1000l  DOUBLE       NULL,
    ADD COLUMN best_price_per_1000l     DOUBLE       NULL,
    ADD COLUMN best_price_period        INT          NULL,
    ADD COLUMN best_price_period_label  VARCHAR(64)  NULL;
