## Was aendert dieser PR?

<!-- Kurze Beschreibung der Aenderung und der Motivation dahinter. -->

## Betroffene Bereiche

<!--
Zutreffendes ankreuzen. Neue Ordner (z.B. FarmPulse Core) werden hier
ergaenzt, sobald sie im Repo existieren.
-->

- [ ] `Bridge` (FS25 Bridge Mod)
- [ ] `backend` (Spring-Boot-Backend)
- [ ] `frontend` (Angular-Dashboard)
- [ ] `Tools` (Tools, u.a. `mock-bridge.sh`, `docker-compose.dev.yml`)
- [ ] Doku (`README.md`, `CONTRIBUTING.md`, `<Bereich>/README.md`, ...)
- [ ] Sonstiges: <!-- z.B. CI, .gitignore -->

## Wie wurde getestet?

<!--
Kurz beschreiben, wie die Aenderung getestet wurde (automatisiert und/oder
manuell). Bereichsspezifische Testbefehle stehen im README des jeweiligen
Bereichs, z.B. Bridge/README.md, Abschnitt "Tests ausfuehren"
(`lua5.4 tests/run_tests.lua`, Zusammenfassungszeile genuegt) bzw.
"Test-Feedback-Loop" fuer manuelle In-Game-Tests.
-->

## Checkliste

Allgemein (gilt fuer jeden Bereich):

- [ ] Ich habe [`CONTRIBUTING.md`](../CONTRIBUTING.md) gelesen und die dortige
      Checkliste vor Erstellen dieses PRs durchgearbeitet.
- [ ] Die Doku im betroffenen Bereich (`README.md` des Bereichs bzw. des
      Repo-Roots) ist aktuell, falls sich Verhalten, Schnittstellen oder
      Dateiformate geaendert haben.
- [ ] Neue/geaenderte Logik ist durch Tests abgedeckt, sofern der Bereich
      automatisiertes Testen unterstuetzt.
- [ ] **Falls sich das Dateiformat von `telemetry.json`/`world.json`/
      `farm.json` geaendert hat: [`Tools/mock-bridge.sh`](../Tools/mock-bridge.sh)
      wurde entsprechend nachgezogen.** Gilt unabhaengig davon, in welchem
      Bereich die Aenderung eingecheckt wird (z.B. auch bei einer
      Backend-Migration, die ein neues Bridge-Feld erstmals konsumiert) -
      sonst testen nachgelagerte Entwickler:innen und das Frontend lokal
      gegen ein veraltetes, nicht mehr repraesentatives Mock. Nicht
      zutreffend ankreuzen, falls sich das Dateiformat nicht geaendert hat.
- [ ] `git status`/`git diff` durchgesehen - keine versehentlichen
      Zusatzdateien oder Secrets im Diff.

<details>
<summary>Bridge-spezifisch (nur falls <code>Bridge/</code> betroffen)</summary>

- [ ] `lua5.4 tests/run_tests.lua` laeuft lokal ohne Fehlschlaege (falls
      `Bridge/scripts/*` oder `Bridge/tests/*` betroffen sind).
- [ ] Neue Dateien unter `Bridge/scripts/` sind in `Bridge/modDesc.xml`
      unter `<extraSourceFiles>` eingetragen - sonst laedt FS25 sie nicht.
- [ ] Dateiformat-Doku in `Bridge/README.md` aktualisiert (falls sich
      `telemetry.json`/`world.json`/`farm.json` geaendert haben), inkl.
      Konfidenz-Tabelle (BESTAETIGT/HERGELEITET) fuer neue Engine-Aufrufe.
- [ ] `Tools/mock-bridge.sh` an geaendertes Dateiformat angepasst (siehe
      auch die allgemeine Checkliste oben).

</details>

<details>
<summary>Backend-spezifisch (nur falls <code>backend/</code> betroffen)</summary>

- [ ] `mvn test` laeuft lokal ohne Fehlschlaege (inkl. Testcontainers-
      Integrationstests, dafuer wird lokal Docker benoetigt).
- [ ] Schema-Aenderungen erfolgen ausschliesslich ueber eine neue,
      fortlaufend nummerierte Flyway-Migration unter
      `backend/src/main/resources/db/migration/` - bestehende Migrationen
      wurden nicht nachtraeglich geaendert.
- [ ] `backend/README.md` aktualisiert, falls sich Konfiguration,
      Endpunkte, Datenmodell oder Architektur geaendert haben.
- [ ] Neue Mock-Dashboard-Werte ohne (vollstaendige) Bridge-Datenquelle sind
      in `backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md` dokumentiert, statt
      erfundene Platzhalterwerte auszuliefern.

</details>

<details>
<summary>Frontend-spezifisch (nur falls <code>frontend/</code> betroffen)</summary>

- [ ] `ng build` laeuft lokal ohne Fehler.
- [ ] `ng test` (Karma/Headless Chrome) laeuft lokal ohne Fehlschlaege.
- [ ] Neue Seiten sind ins Routing (`app.routes.ts`) sowie in die Sidebar
      (`layout/shell/shell.component.html`) eingebunden, bzw. ein
      ausgegrauter Platzhalter wurde bewusst so belassen.
- [ ] Seiten pollen wie die uebrigen gegen das Backend (5s-Intervall,
      `merge(timer(0, 5000), manualRefresh$)`-Pattern, siehe z.B.
      `core/services/dashboard.service.ts`), statt einmalig zu laden.
- [ ] Neue Mock-Dashboard-Werte ohne echte Datenquelle sind in
      `backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md` dokumentiert, statt
      erfundene Platzhalterwerte anzuzeigen.

</details>

<!--
Fuer weitere Bereiche (z.B. FarmPulse Core) hier analog einen eigenen
<details>-Block mit bereichsspezifischer Checkliste ergaenzen, sobald der
Bereich im Repo existiert.
-->
