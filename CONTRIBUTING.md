# Beitragen zu FarmPulse

Danke, dass du an FarmPulse mitarbeiten moechtest! Diese Datei beschreibt den
Ablauf fuer Aenderungen an diesem Repo, insbesondere was **vor dem Erstellen
eines Pull Requests** zu erledigen ist.

## Branch- und Commit-Konventionen

- Entwickle auf einem eigenen Feature-Branch, nicht direkt auf `main`.
- Schreibe kurze, aussagekraeftige Commit-Nachrichten auf Deutsch (wie in der
  bisherigen Historie ueblich), z.B. `Bridge: StorageCollector um Fallback
  fuer unbekannte Fill-Typen erweitern`.
- Ein Commit sollte eine in sich abgeschlossene, nachvollziehbare Aenderung
  enthalten.

## Checkliste vor jedem Pull Request

Bitte vor dem Oeffnen eines PRs der Reihe nach durchgehen:

1. **Tests lokal ausfuehren.** Fuer Aenderungen an `Bridge/scripts/*.lua`
   oder den zugehoerigen Tests:

   ```bash
   cd Bridge
   lua5.4 tests/run_tests.lua
   ```

   Erwartet wird `0 fehlgeschlagen` am Ende der Ausgabe (siehe
   `Bridge/README.md`, Abschnitt "Tests ausfuehren", fuer die genaue
   erwartete Anzahl Tests). Ist kein Lua lokal installiert:
   `apt-get install lua5.4` (Debian/Ubuntu) oder aequivalent.

   Fuer Aenderungen unter `backend/`:

   ```bash
   cd backend
   mvn test
   ```

   Erfordert lokal Docker (fuer die Testcontainers-Integrationstests gegen
   MariaDB), siehe `backend/README.md`, Abschnitt "Tests ausfuehren".
   Aendert sich das Datenbankschema, gehoert dazu immer eine neue,
   fortlaufend nummerierte Flyway-Migration unter
   `backend/src/main/resources/db/migration/` - niemals eine bestehende
   Migration nachtraeglich aendern.

   Fuer Aenderungen unter `frontend/`:

   ```bash
   cd frontend
   npm ci        # nur beim ersten Mal bzw. nach package.json-Aenderungen
   npm run build
   npm test -- --watch=false --browsers=ChromeHeadlessCI
   ```

   `ng test` benoetigt einen Headless-Chrome-Launcher; siehe
   `frontend/karma.conf.js` fuer die vorkonfigurierte `ChromeHeadlessCI`-
   Umgebung, falls lokal kein Chrome/Chromium gefunden wird.

2. **Neue Logik testen.** Aenderungen an einem GIANTS-unabhaengigen Modul
   unter `Bridge/scripts/` (also allem ausser `FarmPulseBridge.lua` selbst)
   brauchen passende Tests in `Bridge/tests/`. Reine Engine-Glue-Aenderungen
   in `FarmPulseBridge.lua` sind bewusst nicht automatisiert testbar (siehe
   `Bridge/README.md`) - hier stattdessen kurz beschreiben, wie manuell
   getestet wurde bzw. getestet werden sollte.

3. **Dateiformat-Aenderungen dokumentieren.** Wird das JSON-Format von
   `telemetry.json`, `world.json` oder `farm.json` geaendert (neues Feld,
   andere Semantik, ...), muss `Bridge/README.md` (Abschnitte "Dateiformat: ...")
   entsprechend angepasst werden - Core-seitige Konsumenten verlassen sich
   auf diese Doku.
4. **`modDesc.xml` bei neuen Dateien pflegen.** Wird eine neue
   `Bridge/scripts/*.lua`-Datei hinzugefuegt, muss sie in
   `Bridge/modDesc.xml` unter `<extraSourceFiles>` eingetragen werden, sonst
   laedt FS25 sie nicht.

5. **`mock-bridge.sh` bei JEDER Formataenderung anpassen - kein optionaler
   Schritt.** Aendert sich das JSON-Format der Austauschdateien
   (`telemetry.json`/`world.json`/`farm.json`), muss `Tools/mock-bridge.sh`
   im selben PR entsprechend nachgezogen werden, damit das Mock weiterhin
   ein realistisches Abbild der echten Bridge liefert. Das gilt unabhaengig
   davon, in welchem Bereich die Aenderung eingecheckt wird - z.B. auch,
   wenn nur das Backend ein neues Bridge-Feld erstmals konsumiert, das
   `mock-bridge.sh` aber noch nicht schreibt. Ein veraltetes Mock faellt
   sonst erst spaet auf (z.B. beim naechsten Frontend-Test gegen `npm start`
   + `mock-bridge.sh`) und blockiert dann alle nachgelagerten
   Entwickler:innen.

6. **Neue Mock-Dashboard-Werte ohne echte Datenquelle dokumentieren.** Zeigt
   ein Mock unter `MockDashboard/*.html` einen Wert, fuer den die Bridge
   (noch) keine Daten liefert, wird dafuer **kein** erfundener
   Platzhalterwert angezeigt - stattdessen den Wert in
   `backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md` als Datenluecke eintragen
   (mit einer Einschaetzung, wie er sich ggf. nachziehen liesse).

7. **Neue Frontend-Seiten einbinden.** Eine neue Seite braucht einen Eintrag
   in `frontend/src/app/app.routes.ts` sowie einen aktiven Sidebar-Punkt in
   `frontend/src/app/layout/shell/shell.component.html` (statt eines
   dauerhaft ausgegrauten Platzhalters) und sollte wie die uebrigen Seiten
   alle 5 Sekunden gegen das Backend pollen (siehe das
   `merge(timer(0, 5000), manualRefresh$)`-Pattern in
   `core/services/dashboard.service.ts` als Vorlage).

8. **Diff selbst noch einmal durchsehen** (`git diff`/`git status`): keine
   versehentlich eingecheckten lokalen Dateien (IDE-Konfiguration,
   `mock-exchange/`-Ausgaben, `frontend/dist/`, `frontend/node_modules/`,
   Log-Dateien etc.) und keine Secrets/Zugangsdaten im Diff.

9. **PR-Beschreibung ausfuellen** (siehe PR-Vorlage): was wurde geaendert,
   warum, und wie wurde es getestet (Testlauf-Ausgabe genuegt fuer
   `scripts/`-Aenderungen; bei Engine-Glue-Aenderungen der In-Game-Testablauf
   aus `Bridge/README.md`, Abschnitt "Test-Feedback-Loop").

## CI

Jeder Pull Request laeuft automatisch durch die GitHub-Actions-Pipeline
(`.github/workflows/test.yml`), die die Bridge-Lua-Tests
(`lua5.4 tests/run_tests.lua`) sowie die Backend-Tests (`mvn test`, inkl.
Testcontainers-Integrationstests gegen MariaDB, und einen Docker-Image-Build)
ausfuehrt. **Frontend-Tests laufen aktuell NICHT in CI** - `ng build`/`ng test`
muessen vor einem PR, der `frontend/` betrifft, lokal ausgefuehrt werden
(siehe Schritt 1 oben). Ein PR mit fehlschlagender Pipeline wird nicht
gemergt - im Zweifel lieber vorher lokal wie in Schritt 1 oben pruefen.

## Architektur-Grundsatz

Siehe `Bridge/README.md`, Abschnitt "Architektur des Mod-Codes": Die Bridge
bleibt bewusst dumm. Neue Logik, die sich ohne FS25 testen laesst, gehoert in
ein eigenes Modul unter `Bridge/scripts/`, nicht in `FarmPulseBridge.lua`.
Nur unvermeidbare GIANTS-Engine-Zugriffe gehoeren in `FarmPulseBridge.lua`
selbst, und auch dort mit `pcall()` abgesichert (siehe README, Abschnitt
"Wichtiger Hinweis zur Vertrauenswuerdigkeit dieses Codes").
