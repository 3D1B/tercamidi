# Herkunft und Analysegrenzen

## Untersuchtes Material

- Vom Nutzer bereitgestellt: `com.japi.terca_6825043604_1.0.4.ipa`.
- Bundle: `com.japi.terca`, Anzeigename `Terca`, Version `1.0.4`, Build `12`.
- Enthaltene Metadaten nennen iOS 15 als Mindestversion, iPhone und Querformat sowie Bluetooth-MIDI-Berechtigungen und Audio/Bluetooth-Hintergrundmodi.
- Das ARM64-Mach-O enthält `LC_ENCRYPTION_INFO_64` mit `cryptid = 1`, verschlüsseltem Bereich ab Offset 16384 mit Länge 4538368. Eine vollständige statische Rekonstruktion des Anwendungscodes war damit nicht möglich. Es wurde keine Entschlüsselung oder Ausführung der Original-App durchgeführt.
- Importierte Symbole weisen auf CoreMIDI sowie Apples `CABTMIDICentralViewController` hin. Imports belegen verwendete APIs, nicht die genaue Anwendungslogik.
- Die öffentliche App-Store-Beschreibung für ID `6825043604`, abgerufen über Apples Lookup-Endpunkt für Store `rs`, beschreibt MIDI-Harmonien, individuelle Zuordnungen pro Note/Oktave, Mehrstimmigkeit, Tonart/Transpose, Seiten, MIDI-Kanäle, Sicherungen und Panik.
- Ein REA-Aufruf `inspect-native-load-image` wurde versucht. Er scheiterte mit `provider_unavailable`, weil keine native Analyse-Engine konfiguriert ist. Dieser Aufruf wird ausdrücklich nicht als erfolgreiche REA-Dekompilierung gewertet. Die oben genannten Metadaten wurden direkt mit ZIP-, Property-List- und Mach-O-Header-Parsing gelesen.

## Schlussfolgerung

Diese Quellen erlauben eine Beschreibung der öffentlich beworbenen Produktfunktionen, aber keine Behauptung, die Original-App vollständig verstanden oder getestet zu haben. Insbesondere fehlen belastbare Beobachtungen zum exakten Korg-SysEx-/Transpose-Protokoll, den Original-Presets, deren Dateiformat, Bildschirmabläufen und einer vollständigen Modellliste.

OpenHarmony wurde eigenständig mit SwiftUI/CoreMIDI geschrieben. Kein Programmcode, App-Icon, Assets-Katalog, Kaufmechanismus oder sonstiges Originalmaterial ist Teil der Lieferung. Die Original-IPA und persönliche Store-Metadaten sind nicht im Projektarchiv enthalten. Die MIT-Lizenz bezieht sich auf diese neue Implementierung.

Das Ziel ist ein frei veränderbarer Ausgangspunkt für die gewünschten Funktionen mit drei Sprachen. Eine vollständige Funktionsparität, Latenzqualität auf echten Geräten oder Pa5X-Kompatibilität wird erst durch weitere Implementierung und Hardwaretests feststellbar.
