# OpenHarmony — freie MIDI-Harmoniebox für iPhone

Eigenständiger erster Entwicklungsstand einer MIDI-Harmonie-App für **Deutsch, Englisch und Serbisch (lateinisch)**. SwiftUI, CoreMIDI, iOS 16 oder neuer, MIT-Lizenz. Keine Käufe, Abos, Konten, Werbung oder Netzwerkdienste im App-Code. Das iPhone erzeugt MIDI-Harmonien; den Klang liefert dein Keyboard.

Dies ist eine neue Implementierung mit eigener Oberfläche und eigenen Beispiel-Vorlagen. Sie enthält keinen Programmcode, keine Grafiken und keine freigeschalteten Kauf-Funktionen aus Terca. Sie ist weder ein offizielles Terca-Produkt noch ein bestätigter funktionsgleicher Ersatz.

## IPA über GitHub bauen — kein eigenes Xcode nötig

1. Neues GitHub-Repository anlegen. Auf die standardmäßig vorgeschlagene README verzichten oder diese anschließend ersetzen.
2. Dieses ZIP entpacken. Den **Inhalt des Ordners OpenHarmony** ins Repository hochladen: `App`, `Core`, `OpenHarmony.xcodeproj`, `scripts`, **`.github`** und die übrigen Dateien gehören direkt in die oberste Ebene. Nicht das ZIP selbst hochladen und keine zusätzliche Ordnerebene anlegen.
3. Prüfen, dass die Datei **`.github/workflows/ios.yml`** im Repository vorhanden ist. Falls der Datei-Dialog versteckte Ordner ausblendet, diesen Pfad über „Add file → Create new file“ anlegen und den mitgelieferten Workflow-Inhalt einfügen.
4. Unter **Actions → Build iPhone IPA → Run workflow** den Build starten. Falls GitHub Actions erst aktiviert werden muss, dies im Repository bestätigen. Der Workflow startet auch bei Push auf `main` oder `master`.
5. Den erfolgreichen Lauf öffnen. Unter **Artifacts → OpenHarmony-unsigned-IPA** das ZIP herunterladen und entpacken. Darin liegt **OpenHarmony-unsigned.ipa**.
6. Die IPA mit deinem bestehenden Verfahren signieren und auf dem iPhone installieren, beispielsweise mit einem für dein Gerät geeigneten Sideloading-Werkzeug. **Die unsignierte IPA lässt sich nicht allein durch Antippen installieren.** Der Workflow benötigt keine Apple-Zugangsdaten oder Zertifikate. Apples Signierungs- und gegebenenfalls Erneuerungsvorgaben gelten unabhängig von der kostenlosen App.

Der Workflow verwendet einen GitHub-macOS-Runner, führt die Swift-Tests aus, baut für echte iPhones und verpackt `Payload/OpenHarmony.app`. Das Projekt hat keine Drittanbieter-App-Abhängigkeiten; `HarmonyCore` ist ein lokales Swift-Paket. GitHub kann je nach Repository-Sichtbarkeit, Kontingent und Tarif Runner-Kosten berechnen.

**Validierungsstand:** Die Harmonie-Engine wurde hier mit Swift 6.0.3 auf Linux getestet. Die App-Dateien wurden auf Swift-Syntax geprüft, Projektstruktur und Workflow wurden statisch geprüft. Ein Apple-SDK-Build, der GitHub-Workflow und echte iPhone-/Keyboard-Verbindungen wurden hier nicht ausgeführt. Ein erfolgreicher erster GitHub-Lauf und ein Hardwaretest sind noch erforderlich. Das ZIP enthält daher Quellcode und Build-Konfiguration, keine bereits gebaute IPA.

## Korg Pa5X über USB einrichten

1. Pa5X über seinen für die Rechnerverbindung vorgesehenen USB-MIDI-Anschluss mit dem iPhone verbinden. Datenfähiges Kabel verwenden. Je nach iPhone ist ein passender USB-C- oder Lightning-USB-Adapter, gegebenenfalls mit Stromversorgung, erforderlich. Ein Anschluss für USB-Speicher ist nicht automatisch ein USB-MIDI-Geräteanschluss.
2. App öffnen → **Einstellungen → MIDI-Verbindung**. Pa5X als Eingang **und** Ausgang wählen. Bei mehreren Anschlüssen die zu den gewünschten MIDI-Parts gehörenden Ports auswählen.
3. Standard der App: **Melodie auf MIDI-Kanal 1 empfangen, Harmonie auf Kanal 2 senden**. Am Keyboard muss der gespielte Part auf Kanal 1 senden und ein hörbarer Part auf Kanal 2 empfangen. Falls dein MIDI-Profil andere Kanäle verwendet, beide Seiten entsprechend einstellen. Die App verändert keine Keyboard-Konfiguration.
4. Der Melodieklang kommt direkt vom Keyboard: die passende lokale Klangerzeugung muss aktiv sein. MIDI Thru beziehungsweise das Zurücksenden empfangener Harmonien vermeiden. Die App ignoriert neue Eingangsnoten auf ihrem eigenen Ausgangskanal zusätzlich als Schleifenschutz. Bei „Alle Kanäle“ wird der Ausgangskanal deshalb ebenfalls ignoriert.
5. Auf der Hauptseite Tonart und **Dur-Terzen** wählen. In C-Dur erzeugt ein gespieltes C4/MIDI 60 eine E4/MIDI 64 auf Kanal 2. Beim Loslassen muss E4 verstummen. Erst danach Akkorde und Sustain testen.
6. Bei einer klemmenden Harmonie **Panik** drücken. Die App beendet eigene aktive Noten und schickt Sustain-Off/All-Notes-Off auf ihren verwendeten Harmoniekanälen, nicht pauschal auf allen Keyboard-Kanälen.

**Keine bestätigte Pa5X-Kompatibilität:** CoreMIDI-Unterstützung und vorhandene USB-Ports sind implementiert, aber es fand kein Pa5X-Hardwaretest statt. Die Original-App nennt keine vollständige verbindliche Modellliste. Pa5X, andere Korg-Pa-Modelle und Geräte anderer Hersteller werden deshalb noch nicht als geprüft geführt. Voraussetzung ist ein von iOS erkanntes MIDI-1.0-Gerät mit passenden Ein-/Ausgangsrouten. Proprietäre USB-Treiber können auf iPhones nicht nachinstalliert werden.

## Bedienung

- **Sprache:** Einstellungen → Sprache → Deutsch, English oder Srpski. Wechsel ohne Neuinstallation.
- **Vorlagen:** Dur-Terzen, Moll-Terzen, Dur-Sexten, harmonisch Moll, Oktave und Quinte plus Oktave. Sechs große farbige Tasten pro Seite; weitere Tasten über Bearbeiten → Neue Harmonie. Maximal 256 Vorlagen.
- **Tonart:** verschiebt die relativ zu C definierte Zuordnung. Bei den diatonischen Vorlagen haben skalenfremde Noten zunächst keine Harmonie. Im Editor lassen sie sich gezielt ergänzen.
- **Editor:** Vorlage wählen, eigenen Namen/Farbe einstellen und eine MIDI-Note von 0 bis 127 auswählen. Halbtonabstände eingeben: `4` = große Terz, `-3` = kleine Terz darunter, `7,12` = Quinte plus Oktave. Bis zu acht unterschiedliche Harmoniestimmen je Eingangsnote, Abstände −48 bis +48. Leeres Feld bedeutet keine Zusatznote. **Note übernehmen** speichert die Zeile; **Diese Oktave auf alle Oktaven kopieren** wiederholt die zwölf Zeilen dieser Oktave. Am oberen MIDI-Rand existieren nur acht Noten der letzten Oktave.
- **Reihenfolge:** im Editor „Bearbeiten“ aktivieren, Vorlagen über die Ziehgriffe verschieben oder löschen. Mindestens eine Vorlage bleibt bestehen.
- **Oktave/Anschlagstärke:** zusätzliche Oktavlage von −3 bis +3 und relative MIDI-Anschlagstärke von 10 bis 150 %, auf gültige Werte begrenzt.
- **Sicherung:** Einstellungen → Vorlagen exportieren → Datei teilen. Import verwendet das eigene versionierte JSON-Format und **ersetzt die Vorlagen**. Vorher Sicherung exportieren. Original-Terca-Preset-Dateien sind nicht als kompatibel bestätigt.
- **Bluetooth:** Einstellungen → Bluetooth MIDI öffnet Apples MIDI-Geräteauswahl. Nach Verbindung die Ein-/Ausgangsports wählen. Bluetooth ist noch nicht mit Hardware getestet.

Vorlagen und zentrale MIDI-Einstellungen werden lokal gespeichert. Hardware-Ports werden nach dem Start bewusst neu ausgewählt, damit keine ungeprüfte automatische Verbindung entsteht. Die App bleibt im Vordergrund wach. Beim Verlassen des aktiven Zustands werden die Harmoniestimmen beendet; eine Hintergrund-Performance ist noch nicht implementiert.

## Bekannte Unterschiede und offene Arbeiten

| Funktion | Stand |
| --- | --- |
| Mehrstimmige MIDI-Harmonien, individuelle Noten/Oktaven, Tonart, Editor | Implementiert; Engine automatisiert getestet |
| USB/CoreMIDI, BLE-Geräteauswahl, Sustain, Panik | Implementiert; Hardwaretest offen |
| Deutsch, Englisch, serbische Lateinschrift | Oberfläche übersetzt; native UI-Prüfung offen |
| Speichern, eigenes JSON-Import/Export, Seiten, Reihenfolge | Implementiert; iPhone-Test offen |
| Automatisches Korg-Transpose | **Nicht implementiert**; Tonart manuell einstellen |
| Hersteller-SysEx, Pitchbend, Aftertouch und Program Changes | Werden nicht an die Harmonie weitergereicht |
| Hintergrundbetrieb und automatisches Wiederverbinden | Noch nicht implementiert |
| Exakte Original-Vorlagen, Original-Layout und Original-Dateiformat | Nicht übernommen; eigenes Design und eigene Vorlagen |
| Bereits signierte IPA/App-Store-Veröffentlichung | Nicht enthalten |

Bei Einstellungen- oder Vorlagenwechsel werden bestehende Harmoniestimmen beendet. Neue Einstellungen gelten mit dem nächsten Note-On. Bei dynamischen Wechseln unter gehaltenem Sustain kann daher eine gewollte Unterbrechung entstehen.

## Entwicklung und Tests

```sh
swift test --package-path Core
python3 scripts/generate_project.py
```

Das direkt öffnungsfähige `OpenHarmony.xcodeproj` liegt bereits bei. Der Generator verwendet nur die Python-Standardbibliothek. `project.yml` beschreibt alternativ eine XcodeGen-Konfiguration; der GitHub-Workflow nutzt ausschließlich das mitgelieferte Xcode-Projekt und benötigt XcodeGen nicht.

Auf einem Mac mit Xcode lässt sich die gleiche Gerätekompilierung wie im Workflow ausführen:

```sh
xcodebuild -project OpenHarmony.xcodeproj -scheme OpenHarmony \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Die Tests prüfen unter anderem jeden MIDI-Ton in zwölf Tonarten für alle sechs Vorlagen, Note-Off-Zuordnung nach Konfigurationswechsel, überlappende Stimmen, wiederholte Noten, Kanalfilter, Schleifenschutz, Sustain, Panik, Datenstrom-Parsing, Wertebereiche und das Vorlagendateiformat. Sie ersetzen keinen iOS-Build oder Hardwaretest.

Für den ersten Pa5X-Test: geringe Lautstärke, erst einzelne Noten, dann überlappende Noten und Akkorde, Sustain, Vorlagenwechsel, USB-Abziehen und erneute Verbindung prüfen. Danach am Keyboard Transpose ändern und die Tonart in der App manuell nachführen. Ergebnisse pro Keyboard, iPhone, iOS-Version, Kabel und MIDI-Profil dokumentieren.

Lizenz: [MIT](LICENSE). Herkunft und technische Befunde: [ANALYSIS.md](ANALYSIS.md).
