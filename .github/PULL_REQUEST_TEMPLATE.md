## Was aendert dieser PR?

<!-- Kurze Beschreibung der Aenderung und der Motivation dahinter. -->

## Betroffene Bereiche

- [ ] `Bridge/FarmPulseBridge.lua` (Engine-Glue)
- [ ] `Bridge/scripts/*.lua` (testbare Logikmodule)
- [ ] `Bridge/tests/*`
- [ ] `Bridge/modDesc.xml`
- [ ] `Tools/mock-bridge.sh`
- [ ] Doku (`README.md`, `Bridge/README.md`, ...)
- [ ] Sonstiges: <!-- z.B. CI, .gitignore -->

## Wie wurde getestet?

<!--
Fuer Aenderungen an Bridge/scripts/*.lua: Ausgabe von
`lua5.4 tests/run_tests.lua` (Zusammenfassungszeile genuegt).

Fuer Aenderungen an FarmPulseBridge.lua selbst (nicht automatisiert testbar):
kurz beschreiben, wie/ob manuell im Spiel getestet wurde, siehe
Bridge/README.md, Abschnitt "Test-Feedback-Loop".
-->

## Checkliste

- [ ] Ich habe [`CONTRIBUTING.md`](../CONTRIBUTING.md) gelesen und die dortige
      Checkliste vor Erstellen dieses PRs durchgearbeitet.
- [ ] `lua5.4 tests/run_tests.lua` laeuft lokal ohne Fehlschlaege (falls
      `Bridge/scripts/*` oder `Bridge/tests/*` betroffen sind).
- [ ] Neue/geaenderte Logik in `Bridge/scripts/` ist durch Tests abgedeckt.
- [ ] Neue Dateien unter `Bridge/scripts/` sind in `Bridge/modDesc.xml`
      eingetragen (falls zutreffend).
- [ ] Dateiformat-Doku in `Bridge/README.md` aktualisiert (falls sich
      `telemetry.json`/`world.json`/`farm.json` geaendert haben).
- [ ] `Tools/mock-bridge.sh` an geaendertes Dateiformat angepasst (falls
      zutreffend).
- [ ] `git status`/`git diff` durchgesehen - keine versehentlichen
      Zusatzdateien oder Secrets im Diff.
