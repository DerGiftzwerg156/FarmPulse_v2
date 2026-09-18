# Fachliche Lücken und zukünftige Erweiterungen: FarmPulse

> Aufbauend auf [`IST-Analyse.md`](./IST-Analyse.md). Gegenstand dieses
> Dokuments ist ausschließlich fachliche (funktionale) Logik - nicht
> Code-Qualität, nicht Architektur, nicht Technologiewahl.
>
> Stand: 2026-09-17 · Branch `claude/projekt-analyse-logik-mklzmn` · Commit `f5afabd`

---

## 0. Einordnung & Methodik

Jede Lücke wird einer von drei Kategorien zugeordnet, weil das direkt bestimmt,
wie sie zu schließen ist:

| Kategorie | Bedeutung | Konsequenz |
|---|---|---|
| **A - Datenquelle fehlt** | Die Bridge liefert die nötige Rohgröße (noch) nicht bzw. FS25 gibt sie über die Modding-API nicht her | Erfordert zuerst eine Bridge-Erweiterung (neuer Export, ggf. neue Konfidenz-Recherche gegen die GIANTS-Engine) |
| **B - Ableitungslogik fehlt** | Alle nötigen Rohdaten liegen bereits vor (teils sogar schon in der Datenbank) - es fehlt nur die fachliche Verknüpfung/Berechnung | Reine Backend-/Frontend-Erweiterung, keine Bridge-Änderung nötig - meist der schnellste Weg |
| **C - Offene Produktentscheidung** | Kein technisches Hindernis, sondern eine noch nicht getroffene fachliche Festlegung (was genau soll das Feature tun?) | Erfordert zuerst eine Konzept-/Scope-Entscheidung, dann B und/oder A |

Diese Unterscheidung zieht sich durch das gesamte Dokument und mündet in
Kapitel 2 in eine zusammenfassende Priorisierung.

---

## 1. Aktuelle fachliche Lücken

### 1.1 Finanzen

**1.1.1 Keine Kategorisierung von Einnahmen/Ausgaben** *(B, teils A)*
Die Finanzen-Seite zeigt „Einnahmen" und „Ausgaben" ausschließlich als Summe
positiver bzw. negativer Kontostand-Deltas. Ob eine Ausgabe ein Feldkauf, eine
Reparatur, Diesel oder eine Lohnzahlung war, ist nicht erkennbar - fachlich
bleibt „Finanzen" auf der Stufe einer reinen Kontostand-Kurve stehen, nicht
einer Auswertung nach Kostenarten.
*Auswirkung:* Für eine echte betriebswirtschaftliche Einschätzung ("wofür geht
mein Geld eigentlich drauf?") liefert die Seite aktuell keine Antwort.

**1.1.2 Keine Einzeltransaktionen/Buchungsliste** *(A)*
Der Mock-Prototyp sah eine Tabelle benannter Buchungen vor (z.B. „Verkauf
Weizen 8.200 L +1.788 €"). Die Bridge liefert dafür keine Grundlage (nur den
aggregierten Kontostand je Poll) - dies wurde projektseitig bewusst so belassen,
um die Bridge nicht zum Event-Logger zu machen (siehe IST-Analyse, Kapitel 5).

**1.1.3 Kein Bezug zwischen Finanz-Deltas und anderen bereits vorhandenen
Fachdaten** *(B)*
Ein auffällig großer negativer Delta korreliert häufig mit einem Feldkauf -
der Preis des Feldes ist über `world.json`/`fields[]` sogar bekannt. Diese
Korrelation wird aktuell nirgends hergestellt, obwohl beide Datenpunkte
bereits vorliegen.

**1.1.4 Keine Prognose/Liquiditätsvorschau** *(B)*
Z.B. „bei aktueller Ausgabenrate reicht das Geld noch X Spieltage" - ließe
sich bereits aus der vorhandenen Kontostand-Historie ableiten, existiert aber
nicht.

### 1.2 Progression (Reputation, Mitarbeiterzufriedenheit, Saisonziel)

**1.2.1 Reputation/Mitarbeiterzufriedenheit ohne jede Berechnungslogik** *(B/A
gemischt)*
Beide Werte werden einmalig auf 50 % gesetzt und danach **nie wieder
verändert** - unabhängig davon, was im Spiel passiert. Für die Reputation ließe
sich bereits mit vorhandenen Daten eine erste Näherung bilden (B, z.B. Trend
von Kontostand/Ertrag). Für eine belastbare Mitarbeiterzufriedenheit fehlt
dagegen jede Datengrundlage zu Mitarbeitern überhaupt (A, siehe 1.2.2).

**1.2.2 Saisonziel-Fortschritt wird nie fortgeschrieben** - fachlich
unterschiedlich schwer je Zieltyp, deshalb hier bewusst differenziert:

| Zieltyp | Kategorie | Einschätzung |
|---|---|---|
| `MONEY_BALANCE` | **B - „Quick Win"** | Alle nötigen Daten liegen bereits vor (aktueller Kontostand aus `TelemetrySnapshot`); es fehlt nur der Vergleich mit `targetValue`. |
| `HARVEST_AMOUNT` | **A/B, strukturell anspruchsvoll** | „Geerntete Menge" ist **nicht** dasselbe wie „aktueller Lagerbestand": Lager sinkt beim Verkauf, mehrere Ernten desselben Fill-Typs teilen sich über die Saison hinweg denselben Bestand. Mit den heutigen Point-in-Time-Lagerständen lässt sich eine kumulierte Erntemenge bestenfalls über positive Lagerbestand-Deltas annähern - und das nur so lange, wie nicht gleichzeitig verkauft wird. Eine belastbare Lösung bräuchte vermutlich zusätzliche Bridge-Daten. |
| `EMPLOYEE_COUNT` | **A - technisch unmöglich mit heutigen Daten** | Der Quellcode selbst dokumentiert das bereits explizit: *„in der Bridge noch nicht exportiert"* (`SeasonGoalType.java`). FS25 hat zwar ein Mitarbeiter-/Helfer-System, die Bridge exportiert davon aber nichts - ohne Bridge-Erweiterung nicht berechenbar. |
| `CUSTOM` | **C** | Per Definition ohne strukturierte Berechnungsgrundlage - erfordert eine Produktentscheidung, wie ein freies Ziel überhaupt maschinell auswertbar gemacht werden könnte (oder ob es bewusst manuell bleibt). |

**1.2.3 Kein fachliches Konzept, WAS Reputation/Zufriedenheit beeinflusst**
*(C, Voraussetzung für 1.2.1)*
Es ist nirgends festgelegt - nicht einmal auf Konzeptebene -, ob z.B. ein
negativer Kontostand, ein Rückgang im Fuhrparkwert oder verpasste Ernten die
Reputation senken sollten. Bevor 1.2.1 sinnvoll als B-Lücke geschlossen werden
kann, muss diese C-Frage beantwortet sein.

### 1.3 Postfach/Mailbox

**1.3.1 Keine KI-Anbindung** *(C, mit vorbereiteter B-Grundlage)*
Im Code explizit als offener Punkt markiert. Die Vorgeschichte
(`SavegameBackstory`) und der aktuelle Farmzustand liegen als Kontext bereits
vor - es fehlt die Anbindung eines Sprachmodells sowie die Entscheidung, wie
dessen Ausgabe fachlich geprüft/begrenzt werden soll (Ton, Länge, Häufigkeit).

**1.3.2 Keine inhaltliche Kopplung an den echten Zustand, obwohl die Daten
längst vorliegen** *(B - selbst im Projekt bereits so vermerkt)*
Eine Vorlage wie „Marktbericht: Weizenpreis fällt um 27 %" kann erscheinen,
unabhängig davon, ob `currentPricePer1000L` gerade tatsächlich fällt oder
steigt. Seit der Marktpreis-Anbindung an `world.json`/`storages[]` existiert
diese Datenquelle - sie wird von der Nachrichtengenerierung aber schlicht
nicht angesehen.

**1.3.3 Rein zeitgesteuerte statt ereignisgesteuerte Erzeugung** *(B)*
Nachrichten entstehen strikt alle 3 Minuten per Zufall, nicht ausgelöst durch
tatsächliche Ereignisse (z.B. Farmerstellung, tatsächlich fast volles Lager,
tatsächlicher Preis-Höchststand).

**1.3.4 Kategorien suggerieren Fachdomänen, die sonst im System nicht
existieren** *(C)*
`STAFFING`/`PAYROLL` (Personal) und `BANK` (Kredit) referenzieren Bereiche, für
die es aktuell weder Datenmodell noch Logik gibt (siehe 1.8.1). Das Postfach
"verspricht" damit fachlich mehr, als der Rest des Systems heute abbildet.

### 1.4 Felder & Ertragsprognose

**1.4.1 Vereinfachte Ertragsformel ohne Bonus-/Malus-Faktoren** *(A)*
Spritz-, Pflug-, Walz- und Unkraut-Boni, die das eigentliche Dreschergebnis
beeinflussen, fließen bewusst nicht ein (siehe IST-Analyse, Kapitel 3.3).

**1.4.2 Keine Konfidenzanzeige im Frontend** *(B/C)*
Die Bridge-Dokumentation führt fein differenzierte Konfidenzstufen je
Datenpunkt - im Frontend ist davon nichts sichtbar, obwohl der Mock-Prototyp
eine Konfidenzprozentangabe je Ertragsprognose vorsah.

**1.4.3 Keine Feldnamen, nur numerische IDs** *(A, neue Fachfunktion nötig)*
FS25 selbst vergibt ebenfalls keine sprechenden Namen - eine Benennung müsste
als eigene FarmPulse-Funktion ("Feld umbenennen") hinzugefügt werden, inkl.
eigener Datenhaltung (die Bridge kann das nicht liefern).

**1.4.4 Keine Bodenfeuchte** *(A, ungeklärt)*
Möglicherweise an das Precision-Farming-DLC gebunden - nicht abschließend
recherchiert.

**1.4.5 Keine saisonübergreifende Ertragshistorie je Feld** *(B - reiner
Auswertungs-Gap auf ohnehin vorhandenen Daten)*
Jeder `world_snapshot` speichert bereits die volle Feldliste inklusive
Anbaudaten - die Rohdaten für „wie hat sich Feld 7 über die letzten drei
Saisons entwickelt" liegen also technisch bereits in der Datenbank. Es fehlt
ausschließlich die Auswertung/Aggregation darüber.

### 1.5 Lagerbestände & Marktpreise

**1.5.1 Keine Verkaufsempfehlung trotz vorhandener Preisdaten** *(B - „Quick
Win")*
`currentPricePer1000L` und `bestPricePer1000L` liegen für jeden Lagerbestand
bereits vor, werden aber nirgends verglichen oder bewertet (z.B. „aktueller
Preis liegt 15 % unter dem 12-Perioden-Hoch").

**1.5.2 Kein fruchtartenweiter Marktpreis-Ticker unabhängig vom eigenen
Lagerbestand** *(A)*
Aktuell sind Preise nur für Fruchtarten sichtbar, die tatsächlich eingelagert
sind. Ein vollständiger Ticker (wie im Mock als „Economic Market Ticker")
bräuchte eine Bridge-Erweiterung, die alle Fruchtarten der Karte abfragt statt
nur die im Lager vorhandenen.

**1.5.3 Kein Verkaufsereignis-Log** *(A, analog zu 1.1.2)*

### 1.6 Alerts / Hinweise

**1.6.1 Genau eine Regel im gesamten System** *(B)*
„Kontostand negativ" ist aktuell die einzige Warnregel. Das `Severity`-Enum ist
bereits auf einen einzigen Wert (`WARNING`) begrenzt - es gibt fachlich noch
keine Abstufung (z.B. Hinweis vs. kritische Warnung).

**1.6.2 Keine konfigurierbaren Schwellwerte** *(B/C)*
Z.B. „warne mich, wenn der Kontostand unter einen von mir gewählten Betrag
fällt" existiert nicht - der Schwellwert `0` ist fest im Code verankert.

**1.6.3 „Lager fast voll" ist nur noch UI-Kennzeichnung ohne
Dashboard-Anbindung** *(C)*
Die frühere Warnung wurde laut Projekt-Historie bewusst vom Dashboard entfernt
(die Lager-Seite zeigt stattdessen den Füllstand direkt). Ob ein
Lager-Alarm wieder zentral (z.B. im Postfach oder als Dashboard-Hinweis)
auftauchen soll, ist eine offene Produktentscheidung.

### 1.7 Fuhrpark

**1.7.1 Nur Summenwert, keine Einzelfahrzeugsicht** *(A)*
Der Sidebar-Punkt „Flotte" liegt im Frontend bereits (ausgegraut) bereit. Für
eine Einzelfahrzeugsicht (Name/Typ, zugewiesener Mitarbeiter, Status,
Kraftstoff/Schaden, aktueller Job, Position) müsste die Bridge `world.json`
(oder eine neue Datei) um eine `vehicles[]`-Liste erweitern - inklusive neuer
Konfidenz-Recherche gegen die GIANTS-Engine für jeden dieser Werte.

### 1.8 Betriebsführung / unternehmerische Gesamtsicht

**1.8.1 Keine Kredite-/Schulden-Logik** *(C)*
Im Bridge-README explizit als künftige Backend-Aufgabe benannt: *„Kredite/
Schulden ... diese Logik übernimmt FarmPulse Core vollständig, statt die
Ingame-Kreditlogik zu spiegeln"* - bislang nicht begonnen. Weder Datenmodell
noch Service existieren dafür.

**1.8.2 Keine Verträge-/Missionen-Logik** *(C)*
Gleiche Fundstelle, gleicher Status wie 1.8.1.

**1.8.3 Keine Tier-/Viehwirtschaft** *(C)*
Im Projekt bislang an keiner Stelle thematisiert oder für die Zukunft
angekündigt - vollständig offen.

**1.8.4 Genau eine aktive Farm pro Backend-Instanz** *(C)*
Explizit als „Bekannte Einschränkung" dokumentiert. Schränkt ein, wie viele
parallele Spielstände/Höfe mit einer FarmPulse-Instanz sinnvoll begleitet
werden können (z.B. nicht geeignet, um zwei unabhängige Let's-Play-Spielstände
gleichzeitig zu verfolgen).

**1.8.5 Keine Rollen/Rechte** *(C)*
Jede Person mit Zugriff auf das Dashboard kann alles sehen und tun
(Vorgeschichte eintragen, Nachrichten als gelesen markieren, ...). Bei mehreren
Beteiligten (Mehrspieler-Hof, Streamer mit Community-Einblick) fachlich
potenziell relevant, aktuell aber nicht einmal konzeptionell adressiert.

---

## 2. Priorisierung

Zusammenfassend nach Kategorie sortiert - Kategorie-B-Lücken sind in der Regel
der schnellste Hebel, weil die fachlichen Rohdaten bereits vollständig
vorliegen:

| Priorität | Lücken (Kategorie B - Daten vorhanden, Logik fehlt) |
|---|---|
| **Quick Wins** | 1.2.2 `MONEY_BALANCE`-Saisonziel · 1.5.1 Verkaufsempfehlung · 1.4.5 Ertragshistorie je Feld · 1.1.3 Finanz-Delta-Korrelation · 1.3.2 Postfach-Inhalt an echte Preisdaten koppeln · 1.6.1/1.6.2 Alert-Regeln erweitern |

| Priorität | Lücken (Kategorie A - neue Bridge-Datenquelle nötig) |
|---|---|
| **Mittelfristig** | 1.7.1 Einzelfahrzeuge · 1.5.2 fruchtartenweiter Ticker · 1.1.2/1.5.3 Transaktionslogs · 1.4.3 Feldnamen · 1.2.2 `EMPLOYEE_COUNT` (bräuchte zuerst überhaupt Mitarbeiterdaten) |

| Priorität | Lücken (Kategorie C - erst Produktentscheidung nötig) |
|---|---|
| **Konzeptionell zuerst klären** | 1.2.3 Was beeinflusst Reputation/Zufriedenheit? · 1.3.1 KI-Anbindung (Umfang, Ton, Kosten) · 1.8.1/1.8.2 Kredite/Verträge (großer neuer Fachbereich) · 1.8.4 Mehr-Hof-Fähigkeit · 1.8.5 Rollen/Rechte |

---

## 3. Zukünftig sinnvolle Erweiterungen

Über das reine Schließen bestehender Lücken hinaus ergeben sich aus der
Analyse folgende sinnvolle Ausbaustufen:

**3.1 KI-gestütztes Postfach.**
Direkt an die im Code vorbereitete Stelle anknüpfend: Nachrichten, die
Vorgeschichte und aktuellen Farmzustand (Kontostand-Trend, Feldstatus,
Marktpreise) tatsächlich als Kontext nutzen, statt zufällig aus acht
statischen Vorlagen zu wählen. Größter narrativer Hebel des gesamten Systems,
da er das ursprüngliche Rollenspiel-Versprechen (Kapitel 1 der IST-Analyse)
einlöst.

**3.2 Berechnungslogik für Reputation, Mitarbeiterzufriedenheit und
Saisonziel-Fortschritt.**
Beginnend mit dem bereits heute berechenbaren `MONEY_BALANCE`-Ziel als
Machbarkeitsnachweis, danach schrittweise Reputation als Funktion vorhandener
Trends (z.B. Kontostand-Entwicklung, Ertragsentwicklung). Mitarbeiterzufrieden-
heit und `EMPLOYEE_COUNT`-Ziele bleiben abhängig von einer künftigen
Bridge-Erweiterung um Mitarbeiterdaten.

**3.3 Finanz-Kategorisierung / einfache betriebswirtschaftliche Auswertung.**
Heuristische Zuordnung großer Kontostand-Sprünge zu bereits bekannten Ursachen
(Feldkauf anhand bekannter Feldpreise, Fuhrpark-Käufe anhand Wertsprüngen),
perspektivisch ergänzt um echte Kategorien, sobald ggf. weitere Datenquellen
verfügbar werden. Ziel: aus einer reinen Kontostand-Kurve wird eine grobe
Einnahmen-/Ausgaben-Struktur.

**3.4 Verkaufsempfehlungs-/Preis-Trend-Logik.**
Ableitung einer einfachen Handlungsempfehlung aus bereits vorhandenen Daten
(„aktueller Preis nahe am 12-Perioden-Hoch - guter Verkaufszeitpunkt" /
„Preis deutlich unter historischem Schnitt - eventuell abwarten"). Baut direkt
auf 1.5.1 auf und wäre der erste wirklich *vorausschauende* (statt rein
beschreibende) Baustein außerhalb der Kontostand-Warnung.

**3.5 Erweiterte, konfigurierbare Alert-/Hinweis-Engine.**
Mehrere Schweregrade statt nur `WARNING`, vom Nutzer wählbare Schwellwerte,
Reaktivierung eines Lager-Alarms als bewusst konfigurierbare (statt fest
verdrahtete) Regel, perspektivisch Zustellung außerhalb des Dashboards (z.B.
Push-Benachrichtigung), sobald ein entsprechender Kanal existiert.

**3.6 Feldverwaltung.**
Eigene Feldnamen/Tags, mehrjährige Ertragshistorie und -statistik je Feld
(Datenbasis liegt bereits vor, siehe 1.4.5), perspektivisch eine einfache
Fruchtfolge-Planung/-Empfehlung auf Basis der Historie.

**3.7 Saison-/Jahresrückblick & Reporting.**
Die historisierten Snapshots erlauben bereits heute einen Rückblick („wie war
diese Saison im Vergleich zur letzten") - aktuell existiert dafür keine
eigene Auswertungsseite. Perspektivisch inklusive Export (z.B. als PDF/CSV
„Saison-Abschlussbericht").

**3.8 Ausbau des Zielsystems.**
Spieler wählen/erstellen eigene Ziele statt einer zufälligen Vorbelegung,
mehrere gleichzeitig aktive Ziele statt eines einzigen, sichtbare
Meilensteine/Belohnungen bei Zielerreichung.

**3.9 Fuhrpark-Detailsicht.**
Sobald 1.7.1 (Bridge-Erweiterung um `vehicles[]`) umgesetzt ist: Status je
Fahrzeug, ggf. ein „Werkstatt nötig"-Hinweis als weitere Alert-Regel.

**3.10 Kredite-/Schulden-Modul.**
Bereits im Projekt als künftige Aufgabe benannt (siehe 1.8.1) - ein
eigenständiger neuer Fachbereich mit eigenem Datenmodell (Kreditlinie,
Rate, Laufzeit) unabhängig von der Ingame-Kreditlogik.

**3.11 Verträge-/Missionen-Modul.**
Ebenfalls bereits angekündigt (1.8.2) - Abbildung von Aufträgen/Zielen mit
Frist und Belohnung als eigener Fachbereich.

**3.12 Mehr-Hof-/Mehr-Save-Fähigkeit.**
Aufhebung der heutigen 1:1-Annahme (eine Bridge, eine Farm, eine
Backend-Instanz), z.B. um mehrere parallele Spielstände oder mehrere Spieler
in derselben FarmPulse-Installation zu verfolgen. Vorbedingung: Die Bridge
müsste `world.json`/`farm.json` um eine FarmID ergänzen (siehe IST-Analyse,
Kapitel 3.4).

**3.13 Rollen & Rechte.**
Relevant, sobald mehrere Personen (Mitspieler, Community/Zuschauer bei einem
Let's Play) unterschiedlichen Zugriff auf dasselbe Dashboard haben sollen -
z.B. lesender Community-Zugang gegenüber vollem Zugriff für den Betriebsleiter.

**3.14 Community-/Vergleichsfunktionen** *(spekulativ, weiter in der Zukunft)*.
Sobald mehrere Höfe/Instanzen technisch unterscheidbar sind (siehe 3.12), wäre
ein Vergleich zwischen Höfen (z.B. einfache Kennzahlen-Bestenliste) denkbar -
klar als Erweiterung mit größerem Vorlauf zu verstehen, nicht als nächster
Schritt.

---

## 4. Empfehlung: sinnvolle nächste Schritte

Ohne Aufwandsschätzung, aber nach fachlicher Hebelwirkung und Abhängigkeit
geordnet:

1. **`MONEY_BALANCE`-Saisonziel berechnen** (1.2.2) - kleinste denkbare
   Änderung, schließt die erste von drei Progression-Lücken vollständig und
   validiert das Konzept „Fortschritt aus echtem Zustand ableiten".
2. **Verkaufsempfehlung auf der Lager-Seite** (1.5.1/3.4) - Daten sind
   vollständig vorhanden, hoher sichtbarer Nutzen, kein Abhängigkeitsrisiko.
3. **Postfach-Inhalte an echte Marktpreis-/Kontostand-Daten koppeln** (1.3.2)
   - von der Projektdokumentation selbst bereits als naheliegend vermerkt.
4. **Fachliches Konzept „was beeinflusst Reputation/Zufriedenheit"
   festlegen** (1.2.3) - Voraussetzung für 3.2, aber selbst reine
   Konzeptarbeit ohne Implementierungsrisiko.
5. **Ertragshistorie je Feld auswerten** (1.4.5) - reine Auswertung auf
   bereits vorhandenen historisierten Daten.
6. Erst danach die größeren, mehrere Bausteine voraussetzenden Themen
   angehen: KI-Postfach (3.1), Finanz-Kategorisierung (3.3), sowie die
   grundsätzlicheren Produktentscheidungen Kredite/Verträge (3.10/3.11) und
   Mehr-Hof-Fähigkeit (3.12).

---

## 5. Fazit

Die meisten der hier aufgeführten Lücken sind **keine technischen
Blockaden**, sondern fehlende letzte Schritte auf bereits vorhandenen Daten
(Kategorie B) - das gilt besonders für die Progression- und
Lager/Preis-Domäne. Die aufwendigeren Erweiterungen (neue Bridge-Exporte,
neue Fachbereiche wie Kredite/Verträge/Tiere, Mehr-Hof-Fähigkeit) sind vom
Projekt selbst bereits als künftige Richtung benannt, aber bewusst noch nicht
begonnen. Die sinnvollste Reihenfolge ist entsprechend: zuerst die Quick Wins
auf vorhandenen Daten heben, dann gezielt einzelne Bridge-Erweiterungen
nachziehen, und die großen neuen Fachbereiche erst angehen, wenn die dafür
nötigen Produktentscheidungen (Kategorie C) getroffen sind.
