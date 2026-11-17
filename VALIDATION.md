# Validierung vom 17. November 2026

- **Ausgeführt:** `swift test` mit Swift 6.0.3 auf Linux. Elf Testfälle bestanden, keine Fehler. Darunter ein Durchlauf über 6 Vorlagen × 12 Tonarten × 128 MIDI-Noten = 9.216 Note-On-/Note-Off-Paare.
- **Ausgeführt:** Swift-Frontend-Syntaxprüfung aller drei App-Dateien. Kein Syntaxfehler. Das ist keine Apple-SDK-Typprüfung.
- **Ausgeführt:** Parsing des generierten Xcode-Projekts im OpenStep-Format und Prüfung seiner Objektverweise; XML-Scheme, Property List, Assets-JSON und Workflow-YAML geprüft.
- **Ausgeführt:** Prüfung gleicher Übersetzungsschlüssel in Deutsch, Englisch und Serbisch sowie reproduzierbarer Projektgenerierung.
- **Noch offen:** GitHub-Actions-Lauf, Kompilierung mit iOS-SDK, Erzeugung/Signierung einer IPA, iPhone-UI, USB-/Bluetooth-Verbindungen und Pa5X-Hardwaretest.

## Erster GitHub-Versuch

Das Projekt wurde nach `3D1B/tercamidi` hochgeladen. GitHub beendet sowohl den IPA-Workflow als auch einen minimalen Runner-Test ohne Checkout oder weitere Actions mit `startup_failure`, bevor Jobs oder Logs entstehen. Eine zusätzliche Prüfung mit Actionlint 1.7.12 meldet keinen Workflow-Fehler. Die konkrete Startfehlermeldung ist über die verfügbaren API-Antworten nicht sichtbar und muss auf der GitHub-Seite des Laufs geprüft werden. Es wurde noch keine IPA erzeugt.

Die erfolgreiche Engine-Prüfung ist kein Nachweis für Funktionsparität mit der Original-App oder für Fehlerfreiheit der nativen Oberfläche und MIDI-Anbindung. Der GitHub-Workflow ist vorbereitet und muss im Zielrepository erstmals ausgeführt werden.
