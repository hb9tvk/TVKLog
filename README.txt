TVKLog v1.2.2
-------------

TVKLog ist eine Software, die speziell f�r das Protokollieren von Verbindungen
w�hrend des Contests National Mountain Day (NMD) erstellt wurde. Folgende
Funktionen stehen zur Verf�gung:

- Protokollieren von Verbindungen inkl. Textaustausch und QSO-Zeit in UTC
- Doppelkontrolle nach NMD-Reglement (zweites QSO mit NMD-Stationen nach 08:00 UTC)
- Pr�fung auf 15 Zeichen des empfangenen Texts
- Personalisierte QSO Texte (optional)
- Anzeige des Vornamens des QSO-Partners (wenn vorher erfasst)
- Anzeige der Distanz zur anderen NMD-Station (wenn Koordinaten erfasst sind)
- Anzeige der Anzahl QSO, aufgeschl�sselt nach HB9,NMD und DX (Anmerkung: als
  NMD Punkte werden nur angemeldete Stationen gez�hlt)
- Export des Logs als CSV
- Export des Logs als ADIF (f�r Import in fast alle anderen Logprogramme)
- Worklist: Separates Fenster, das alle NMD-Rufzeichen auflistet, die noch gearbeitet
  werden k�nnen.
  
Installation
------------

TVKLog muss nicht installiert werden. Es besteht aus einer einzigen .exe-Datei, die an einem
beliebigen Ort abgelegt und gestartet werden kann (z.B. auch auf einem Memory-Stick).

Sprachwahl
----------

TVKLog ist zur Zeit auf Deutsch und Englisch verf�gbar. Um auf Englisch umzustellen einfach
vor dem Starten TVKLog.exe Datei nach TVKLog-en.exe umbenennen.

Vorbereitung
------------

Bevor mit TVKLog gearbeitet werden kann, m�ssen 2 Text-Dateien erstellt werden:

- Eine Textdatei, die Information �ber die teilnehmenden NMD-Stationen enth�lt
- Eine Textdatei, die eine Liste von Texten f�r den Austausch enth�lt

Format der Stations-Datei: Jede NMD-Station belegt 1 Zeile, die verschiedenen Werte sind
mit Komma (,) getrennt:

Rufzeichen,Vorname,X-Koordinate,Y-Koordinate,Text1,Text2
Beispiel:

hb9aaa/p,Peter,681239,237065,Fluegelschraube,Buendner Nusstorte
hb9aab/p,Tom,735225,245360,Mikroinduktivitaet,Appenzellerwurst

Bemerkungen:
- Gross-/Kleinschreibung beim Rufzeichen ist egal
- Vorname ist optional (einfach leer lassen wenn unbekannt oder nicht ben�tigt)
- X/Y-Koordinaten sind Schweizer Landeskoordinaten und ebenfalls optional
- Texte sind auch optional. Falls vorhanden, m�ssen sie aber min. 15 Zeichen
  lang sein (exkl. Leerzeichen)
- Es m�ssen immer alle Komma vorhanden sein, auch wenn optionale Informationen
  weggelassen werden. Jede Zeile muss immer 5 Komma enthalten. Beispiele:
  
  hb9qh/p,,692295,239670,,
  hb9qo/p,,,,,
  
Eine Musterdatei wird kurz vor dem NMD zusammen mit der offiziellen Teilehmerliste-
und Karte zum Herunterladen bereitgestellt. Diese muss dann nur noch (optional) durch
pers�nliche Texte erweitert werden.
  
WICHTIG: Die Datei muss als Textdatei abgespeichert werden (Endung .txt), d.h. am Besten
Notepad oder Wordpad oder einen anderer Text-Editor verwenden. Verwendet man Microsoft Word
muss die Datei mit "Speichern unter" als Text-Datei (.txt) abgespeichert werden.

Die zweite Textdatei enth�lt nichtpersonalisierte Texte. Format: je ein Text pro Zeile. 
W�hrend des Contests werden dann von oben nach unten Texte aus dieser Datei zur �bermittlung
vorgeschlagen. Texte, die schon in der Stationsliste verwendet wurden, d�rfen hier nicht noch
einmal benutzt werden. Beispiel:

Funkwetterbericht
I hate winding coils
Spiegelfrequenzen
Kein Gurkensalat


Start und Bedienung von TVKLog
------------------------------

TVKLog wird mit einem Doppelklick auf TVKLog.exe gestartet. Als Erstes muss nun entweder eine
bestehende Log-Datenbank ge�ffnet (Datei->�ffnen) oder eine neue angelegt werden (Datei->Neu).

Bei einer neuen Datenbank muss als Erstes die Stationsbeschreibung und die Liste mit
den Texten geladen werden. Dies erledigt man �ber die Men�s Log->ImportStn f�r
die Stationsliste sowie Log->ImportText f�r die Liste mit den Texten. Ist die
entsprechende Liste fehlerhaft, wird sie nicht geladen, und eine Fehlermeldung weist auf
das Problem hin (z.B. zu kurze Texte, ung�ltige Koordinaten etc.).

Anschliessend sollten die Landeskoordinaten des eigenen QTH eingegeben werden (Extra->QTH eingeben),
falls eine Anzeige der Distanz zur Gegenstation gew�nscht wird.

Eingeben von Verbindungen:

- Empfangenes Rufzeichen im Feld "Call" eingeben, danach mit der 'Tab' Taste zum n�chsten
  Feld vorr�cken.
- TVKLog kontrolliert das Rufzeichen und zeigt je nachdem verschiedene Informationen dazu an:
  - Vorname des OP (bei erfassten NMD-Stationen)
  - Neue Verbindung (==New==) oder Duplikat (==Dupe==)
  - Distanz zur Station (falls eigene Koordinaten sowie die der Gegenstation erfasst wurden)
  - Zu �bermittelnder Text (bei NMD-Stationen)
- Restliche Daten der Verbindung eintragen (RST gesendet / empfangen, Text der Gegenstation)
- Mit 'Tab' kann dabei von Eingabefeld zu Eingabefeld gewechselt werden (mit 'Shift-Tab' auch
  r�ckw�rts)
- Bei der Eingabe des Texts der Gegenstation wird dieser zun�chst rot geschrieben, bis
  die Mindestl�nge von 15 Zeichen erreicht ist. Danach wird der Text schwarz. Zu kurze
  Texte k�nnen jedoch trotzdem gespeichert werden.
- Sind alle Angaben komplett, kann der Eintrag mit "Enter" gespeichert werden.
- Mit der Taste 'Esc' kann ein angefangener Log-Eintrag gel�scht werden. 

QSO-Z�hler: Rechts unter dem TXTr Feld sieht man den aktuellen QSO-Stand, aufgeschl�sselt
nach NMD, HB und DX Verbindungen.

Sonderfunktionen
----------------

- Normalerweise schaltet TVKLog automatisch um 08:00UTC von der ersten Contest-H�lfte
  zur zweiten um. Dies bewirkt, dass nun eine zweite Verbindung mit jeder NMD-Station geloggt
  werden kann. Ebenso wird bei personalisierten Texten nach 08:00UTC der zweite Text
  zur �bermittlung angezeigt.
  Damit man dies im Voraus ausprobieren kann, kann man die Contest-H�lfte �ber das Men�
  "Extra->Erste H�lfte" bzw. "Extra->Zweite H�lfte" fix einstellen. TVKLog verh�lt sich dann so,
  als ob man sich in der ersten bzw. zweiten Contest-H�lfte bef�nde. Mit "Extra->Auto H�lfte"
  schaltet man wieder auf die Automatik zur�ck.
- Worklist: Mit dem Men�punkt "Extra->Worklist anzeigen" kann man ein zus�tzliches Fenster �ffnen,
  welches eine Liste der (in der aktuellen Contest-H�lfte) noch fehlenden NMD-Stationen
  anzeigt.
- Zeiteingabe: Wenn aktiviert erscheint ein neues Eingabefeld "UTC". QSOs k�nnen nun inkl.
  Zeit (in UTC) erfasst werden. Diese Funktion kann verwendet werden um verpasste Eintr�ge
  im Nachhinein zu erfassen.
  

Nach dem Contest
----------------

- Auf dem original Abrechnungsblatt (Erh�ltlich unter http://nmd.uska.ch/index.php?id=62)
  Die Stationsdaten eintragen (Rufzeichen, Standort, Stationsbeschreibung etc.)
- Das Log von TVKLog als CSV-Datei exportieren: Men� Log->Export CSV
- Das ausgef�llte Abrechnungsblatt zusammen mit der .csv Datei bis sp�testens 15 Tage
  nach dem Contest an die NMD-Kommission einsenden (nmd@uska.ch). 
- Falls gew�nscht, kann das Log auch im ADIF-Format exportiert werden (Men� Log->Export ADIF)
  um es in sein pers�nliches Log-Programm zu importieren. ADIF wird von praktisch allen g�ngigen
  Log-Programmen unterst�tzt.


Viel Spass mit TVKLog und gl im Contest w�nscht

Peter Kohler / HB9TVK


Version-History:
----------------

2010-05-07  TVKLog v1.2.2
			- Fehler behoben: Absturz wenn eigene QTH Koordinaten eingegeben, aber Koordinaten
			  in Stations-Datei fehlen.
			- Bessere Pr�fung auf Mindestl�nge der �bermittlungstexte beim Einlesen der Stations-
			  Datei
			  
2009-07-11  TVKLog v1.2.1
		    - Fehler behoben: Automatische Umschaltung um 10:00 HBT auf zweite Contesthaelfte
		      hat nicht funktioniert.

2009-05-30  TVKLog v1.2
		    - Umbenannt von NMDLog nach TVKLog um eine Verwechslung mit dem gleichnamigen Excel
		      Log zu vermeiden.
		    - Wenn das 'Call' Feld leer ist, kann nicht geloggt werden. Beim dr�cken von "Enter"
		      werden alle Eingabefelder gel�scht (wie bei "Esc")
		    - Die Spalte "Text gesendet" ist nun jederzeit editierbar. Somit k�nnen auch f�r nicht
		      als "NMD" erkannte Stationen w�hrend des Contests Texte erfasst und geloggt werden.
		      Ebenso falls zuwenig Texte vorbereitet wurden.
		    - Falsche Z�hlweise von HB und DX Stationen korrigiert (im QSO Z�hler)
		    - Franz�siche Version (Dank an Alexandre, HB9IAL, f�r die �bersetzungen)
		    - CSV Format angepasst damit die UTC Spalte mit f�hrenden Nullen importiert werden kann.
			- Hilfetext verbessert

2008-10-05  NMDLog v1.1

			- Mehrspachigkeit. Deutsch und Englisch vorhanden. Weitere Sprachen einfach m�glich
			  durch �bersetzen einer Textdatei.
			- Beim Anlegen/�ffnen eines NMD Logs merkt sich NDMLog das Verzeichnis und benutzt
			  dieses f�r weitere Import/Export Operationen.
			- Speichern des Logs nun mit "Enter" statt "Shift-Enter"
			- "About" Fenster l�sst sich zus�tzlich mit "Esc" schliessen
			- Neuer Modus "Zeiteingabe" zum nachtr�glichen Erfassen von QSOs (UTC kann mit
			  eingegeben werden)
			- Font: Log wird neu mit einem fix-spaced Font (Courier) und linksb�ndig angezeigt
			- Reduktion der Eingabem�glichkeit f�r RST auf 3 Zahlen zwischen 1-9.
			- �nderung des Logzeitpunkt: Die Zeit wird genommen wenn das erste Zeichen im 
			  "Rufzeichen" Feld eingegeben wird (vorher: beim Abspeichern)
			- Bugfix: Als NMD Stationen werden nur noch HB9*/P, HB3*/P oder HE*/P erkannt 
			          (vorher auch ausl�ndische /P Stationen)
			- Bugfix: Koordinateneingabe (QTH): Bei fehlerhafter Eingabe wurden die Koordinaten
			          trotz Fehlermeldung gespeichert.

2008-09-20	NMDLog v1.0 erste ver�ffentlichte Version

Geplant:
- Nachtr�gliches Editieren von Logeintr�gen
- Integrierter Editor f�r Stationsliste und Textmeldungen




  
  
  








  
  



