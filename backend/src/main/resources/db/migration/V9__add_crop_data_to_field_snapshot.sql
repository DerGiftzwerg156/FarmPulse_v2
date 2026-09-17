-- Anbaudaten je Feld (Fruchtart, Wachstumsfortschritt, Ertragsschaetzung),
-- siehe Bridge/README.md, Abschnitt "Dateiformat: world.json"
-- (fruitType/growthState/estimatedYieldLiters). Nullable: die Bridge liefert
-- sie nur, wenn ein Feld-Objekt gefunden und die Fruchtart aufgeloest werden
-- konnte - siehe Bridge/README.md, "Bekannte Luecken".
ALTER TABLE field_snapshot
    ADD COLUMN fruit_type             VARCHAR(64) NULL,
    ADD COLUMN growth_state           DOUBLE      NULL,
    ADD COLUMN estimated_yield_liters DOUBLE      NULL;
