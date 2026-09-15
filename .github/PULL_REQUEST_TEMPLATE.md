## Was aendert dieser PR?

<!-- Kurze Beschreibung der Aenderung und der Motivation dahinter. -->

## Betroffene Bereiche

<!--
Zutreffendes ankreuzen. Neue Ordner (z.B. Backend, WebDashboard) werden hier
ergaenzt, sobald sie im Repo existieren.
-->

- [ ] `Bridge` (FS-25 Bridge Mod)
- [ ] `backend` (Spring-Boot-Backend)
- [ ] `Tools` (Tools)
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
- [ ] `git status`/`git diff` durchgesehen - keine versehentlichen
      Zusatzdateien oder Secrets im Diff.

<details>
<summary>Bridge-spezifisch (nur falls <code>Bridge/</code> betroffen)</summary>

- [ ] `lua5.4 tests/run_tests.lua` laeuft lokal ohne Fehlschlaege (falls
      `Bridge/scripts/*` oder `Bridge/tests/*` betroffen sind).
- [ ] Neue Dateien unter `Bridge/scripts/` sind in `Bridge/modDesc.xml`
      eingetragen.
- [ ] Dateiformat-Doku in `Bridge/README.md` aktualisiert (falls sich
      `telemetry.json`/`world.json`/`farm.json` geaendert haben).
- [ ] `Tools/mock-bridge.sh` an geaendertes Dateiformat angepasst (falls
      zutreffend).

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
      Datenmodell oder Architektur geaendert haben.

</details>

<!--
Fuer weitere Bereiche (z.B. WebDashboard) hier analog einen eigenen
<details>-Block mit bereichsspezifischer Checkliste ergaenzen, sobald der
Bereich im Repo existiert.
-->
