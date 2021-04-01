<!-- filename: bestell_script_han.js -->

// Skript fuer Bestell-Button per Mailformular
// erstellt fuer Dokumentbestellungen HAN 25.02.2015/bmt
// Adaption von bestell_script_ibb.js
// Zuerst alle Variablen, die sprachabhaengig geaendert werden muessen:
switch (myLNG) {
    case "GER":
        var b_labelTit = "Titel";
        var b_labelSys = "Systemnummer";
        var b_labelBib = "Signatur";
        var b_labelBibOld = "Frühere Signatur";
        var b_labelBibAlt = "Alternativsignatur";
        var b_labelClass = "Zugang";
        var b_labelLevel = "Verzeichnungsstufe";
        var b_labelPart = "Teil";
        var b_labelBESText = "Bestellen Sie hier zur Konsultation in den Lesesaal.";
        var b_access = "Zugangsbestimmungen"; 
        var b_downlink = "Untergeordn. Teil";
        var b_downlink2 = "Bandübersicht";
        var b_time = "Zeit (normiert)";
        break;
    case "ENG":
        var b_labelTit = "Title";
        var b_labelSys = "System number";
        var b_labelBib = "Location";
        var b_labelBibOld = "Former Location";
        var b_labelBibAlt = "Alternate call no.";
        var b_labelClass = "Classification";
        var b_labelLevel = "Description level";
        var b_labelPart = "Part";
        var b_labelBESText = "Order here for consultation in the reading room.";
        var b_access = "Access conditions"; 
        var b_downlink = "Down";
        var b_downlink2 = "View down links";
        var b_time = "Date (norm.)";
        break;
    // unser default ist GER ...        
    default:
        var b_labelTit = "Titel";
        var b_labelSys = "Systemnummer";
        var b_labelBib = "Signatur";
        var b_labelBibOld = "Frühere Signatur";
        var b_labelBibAlt = "Alternativsignatur";
        var b_labelClass = "Zugang";
        var b_labelLevel = "Verzeichnungsstufe";
        var b_labelPart = "Teil";
        var b_labelBESText = "Bestellen Sie hier zur Konsultation in den Lesesaal.";
        var b_access = "Zugangsbestimmungen"; 
        var b_downlink = "Untergeordn. Teil";
        var b_downlink2 = "Bandübersicht";
        var b_time = "Zeit (normiert)";
        break;
}

// function by abi: Reduziert String auf Zahlen (fuer Sysnr)

function b_reduceToNumbers(b_inString1) {
    var b_outString1 = b_inString1.replace(/\D/g,'');
    return b_outString1;
}

// function by abi: loescht ueberfluessige HTML-Tags, Leerzeichen und Anfuerungszeichen
function b_removeTags(b_inString2) {
    b_outString2 = b_inString2.replace(/<.+?>/g,'');
    b_outString2 = b_outString2.replace(/\s+$/g,'');
    b_outString2 = b_outString2.replace(/\n/g,'');
    b_outString2 = b_outString2.replace(/^ +/g,'');
    b_outString2 = b_outString2.replace(/^ +/g,'');
    b_outString2 = b_outString2.replace(/["']/g,'');
    return b_outString2;
}

// function by Innsbruck, die Bestell-Button setzt.
function b_integrateBES(b_table, b_sysNumberText, b_signatur, b_bibPos, b_titleText, b_library) { 

    // erstelle Hash (associative Array fuer PHP-Leute :-) mit Bibliothekscodes und Link zum Formular
    // Link zum Formular braucht folgende Argumente: Systemnummer (b_sysNumberText.innerHTML); Signatur (b_signatur) und Titel (b_titleText)

    b_signatur = encodeURIComponent(b_signatur);
    b_titleText = encodeURIComponent(b_titleText);

    var links = new Object();
    links.A100 = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A100&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.A125 = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A125&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.A150 = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A150&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.B445 = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=B445&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.B583 = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=B583&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.LUZHB = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=LUZHB&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.SGKBV = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGKBV&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.SGARK = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGARK&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.SGSTI = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGSTI&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;
    links.TGKB = 'http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=TGKB&lng=' + myLNG + '&sys=' + b_reduceToNumbers(b_sysNumberText.innerHTML) + '&sig=' + b_signatur + '&title=' + b_titleText;

    var b_besURL = links[b_library];

    //Link zur Bestellknopf-Grafik
    var b_besImg = "/bestell_button_han.gif"

    //Fuege Bestellink und Knopf in die OPAC Vollanzeige ein
    var b_row = b_table.insertRow(b_bibPos + 1); 
    var b_bescell1 = b_row.insertCell(0); 
    b_bescell1.className = 'td1'; 
    b_bescell1.innerHTML = '<a href="' + b_besURL + '" target="_blank" title="Dokument bestellen"> <img src="' + b_besImg + '" border="0" title="Dokument bestellen" alt="Dokument bestellen" /></a>';
    var b_bescell2 = b_row.insertCell(1);
    b_bescell2.className = 'td1';
    b_bescell2.innerHTML = '<a href="' + b_besURL + '" target="_blank" title="Bestellen Sie hier zur Konsultation in den Lesesaal">' + b_labelBESText + '</a>';
} 
 
// Hauptfunktion by Innsbruck
function b_checkYear(){ 

    // Variablen, die wir nachher brauchen
    var b_table = document.getElementById("bibdat");
    var b_cells = b_table.getElementsByTagName("td"); 
    var b_text, b_timeString, b_sysNumber, b_sysNumberText, b_ownerString, b_titleString, b_classString, b_titleText, b_levelString, b_signatur, b_accessString; 
    var b_signaturString = new Array();
    var currentTime = new Date();
    var b_year = currentTime.getFullYear();

    var b_library = false;

    var b_level = new Object();
    b_level.Hptabt = false;
    b_level.Abt = false;
    b_level.Bestand = false;
    b_level.TBestand = false;
    b_level.Serie = false;
    b_level.TSerie = false;
    b_level.Dossier = false;
    b_level.TDossier = false;
    b_level.Dokument = false;
    b_level.Present = false;
  
    var b_orderableA100 = false;
    var b_orderableA125 = false;
    var b_orderableLUZHB = false;
    var b_downlinkPresent = false;
    var b_accessPresent = false;
    var b_save = false;
    var b_a125_save = false;
    var b_working = false;
    var b_index = 0; 
    // Wir zaehlen die Zellen, damit wir unterscheiden koennen, ob wir in den Labels oder im  Fliesstext sind.
    var b_counter = 0;
    var b_systemNumberFound = false; 
    var b_bibPos = -1;
    
    // Lese nacheinander alle Felder der Vollanzeige aus
    for (b_index = 0; b_index < b_cells.length; b_index++) { 
        b_counter++;
        b_cell = b_cells[b_index];

        // Falls irgendwo im Katalogisat 'in Bearbeitung' vorkommt, setzte b_working auf wahr
        if (b_counter % 2 != 0) {
            b_text = b_removeTags(b_cells[b_index + 1].innerHTML);
            if (b_text.indexOf('in Bearbeitung') != -1) {
                b_working = true;
            }
        } 

        // Falls Feld Systemnummer: 
        if ((b_cell.innerHTML.indexOf(b_labelSys) != -1) && (b_counter % 2 != 0)) { 
            b_sysNumber = b_cells[b_index]; 
            b_sysNumberText = b_cells[b_index + 1]; 
            b_systemNumberFound = true; 
        } 

        // Falls Feld Titel:
        if ((b_cell.innerHTML.indexOf(b_labelTit) != -1) && (b_counter % 2 != 0)) { 
            b_titleString = b_cells[b_index + 1]; 
            b_titleText = b_removeTags(b_titleString.innerHTML);
        }

        // Falls Feld Zugangsbestimmungen: 
        if ((b_cell.innerHTML.indexOf(b_access) != -1) && (b_counter % 2 != 0 )) {
            b_accessString = b_cells[b_index + 1];
            if (b_accessString.innerHTML.indexOf('Benutzungsbestimmungen') != -1) { 
                 b_accessPresent = true;
            }
        }
   
        // Falls Feld Zeitangabe: 
        if ((b_cell.innerHTML.indexOf(b_time) != -1) && (b_counter % 2 != 0 )) {
            b_timeString = b_removeTags(b_cells[b_index + 1].innerHTML);
            var b_hyphen = b_timeString.indexOf('-');
            
            // Pruefe ob Bindestrich in Zeitangabe vorkommt 
            if (b_hyphen == -1) {

                // Pruefe ob Dokument aelter als 30 Jahre ist
                if (b_timeString.substr(0,4) >= (b_year - 30)) {
                    b_save = true;
                }
            } else {
                if (b_timeString.substr((b_hyphen + 1), 4) >= (b_year - 30)) {
                    b_save = true;
                }
            }
        }
   
        // Falls Feld Teil (untergeordnete Katalogisate): 
        if ((b_cell.innerHTML.indexOf(b_downlink) != -1) && (b_counter % 2 != 0 )) {
            b_downlinkPresent = true;
        }

        // Falls Feld Banduebersicht (untergeordnete Katalogisate): 
        if ((b_cell.innerHTML.indexOf(b_downlink2) != -1) && (b_counter % 2 != 0 )) {
            b_downlinkPresent = true;
        }

        // Falls Feld Verzeichnungsstufe

        if ((b_cell.innerHTML.indexOf(b_labelLevel) != -1) && (b_counter % 2 != 0)) {
            b_level.Present = true; 
            b_levelString = b_cells[b_index + 1]; 

            if (b_levelString.innerHTML.indexOf('Hauptabteilung') != -1) { b_level.Hptabt = true } 
            else if (b_levelString.innerHTML.indexOf('Abteilung') != -1)      { b_level.Abt = true }
            else if (b_levelString.innerHTML.indexOf('Bestand') != -1 )          { b_level.Bestand = true }
            else if (b_levelString.innerHTML.indexOf('Teilbestand') != -1)   { b_level.TBestand = true }
            else if (b_levelString.innerHTML.indexOf('Serie') != -1)            { b_level.Serie = true } 
            else if (b_levelString.innerHTML.indexOf('Teilserie') != -1)    { b_level.TSerie = true }
            else if (b_levelString.innerHTML.indexOf('Dossier') != -1)                 { b_level.Dossier = true }
            else if (b_levelString.innerHTML.indexOf('Teildossier') != -1)             { b_level.TDossier = true }
            else if (b_levelString.innerHTML.indexOf('Dokument') != -1)                { b_level.Dokument = true }
        }

        // Falls Feld Signatur

        if ((b_cell.innerHTML.indexOf(b_labelBib) != -1) && (b_counter % 2 != 0) && (b_cell.innerHTML.indexOf(b_labelBibOld) == -1)) { 
            // Setzte b_bibPos, damit Bestellink an unterhalb der Signatur eingefuegt wird
            b_bibPos = (b_counter / 2) + 1;
            b_ownerString = b_cells[b_index + 1];
            var b_rawSignatur = b_removeTags(b_ownerString.innerHTML);
       	    var b_a = b_rawSignatur.lastIndexOf("SIGN.:");
            b_signatur = b_rawSignatur.substr(b_a + 12);

            // Stelle Besitzende Bibliothek fest 
            if ((b_ownerString.innerHTML.indexOf("Basel UB") != -1) && (b_ownerString.innerHTML.indexOf("Handschriften") != -1)) {
                b_library = 'A100';
            } else if (b_ownerString.innerHTML.indexOf("Basel UB Wirtschaft") != -1) {
                b_library = 'A125';
            } else if (b_ownerString.innerHTML.indexOf("Solothurn ZB") != -1) {
                b_library = 'A150';
            } else if (b_ownerString.innerHTML.indexOf("Gosteli-Archiv") != -1) {
                b_library = 'B445';
            } else if (b_ownerString.innerHTML.indexOf("Rorschach-Archiv") != -1) {
                b_library = 'B583';
            } else if (b_ownerString.innerHTML.indexOf("Luzern ZHB") != -1) {
                b_library = 'LUZHB';
            } else if (b_ownerString.innerHTML.indexOf("Vadiana") != -1) {
                b_library = 'SGKBV';
            } else if (b_ownerString.innerHTML.indexOf("Stiftsbibliothek") != -1) {
                b_library = 'SGSTI';
            } else if (b_ownerString.innerHTML.indexOf("Ausserrhoden") != -1) {
                b_library = 'SGARK';
            } else if (b_ownerString.innerHTML.indexOf("Thurgau") != -1) {
                b_library = 'TGKB';
            }

            // Falls Benutzung eingeschraenkt in Signatur vorkommt, mache das Dokument fuer A125 nicht bestellbar
            if ((b_ownerString.innerHTML.indexOf("Benutzung") != -1) && (b_ownerString.innerHTML.indexOf("eingeschränkt") != -1)) {
                b_a125_save = true;
            }
        }
        
        // Spezialfall Alternativ/ehematlige Signaturen, fuege Bestelllink unter saemtlichen Signaturenfeldern ein 
        if ((b_cell.innerHTML.indexOf(b_labelBibAlt) != -1) && (b_counter % 2 != 0 )) {
            b_bibPos = (b_counter / 2) + 1;
        }
    
        // Spezialfall Feld Zugang, fuege Bestelllink unter Zugangsfeld ein
        if ((b_cell.innerHTML.indexOf(b_labelClass) != -1) && (b_counter % 2 != 0 ) && (b_cell.innerHTML.indexOf(b_access) == -1)) {
            b_bibPos = (b_counter / 2) + 1;
            b_classString = b_removeTags(b_cells[b_index + 1].innerHTML);

            // Falls in Zugangsfeld eine Schutzfrist erwaehnt ist, mache Pruefung, ob sie schon abgelaufen ist
            if ((b_classString.indexOf("Frist:") != -1) && (b_counter % 2 != 0)) {
                var b_fristPos = b_classString.indexOf("Frist:");
                if (b_classString.substr((b_fristPos + 12),4) >= b_year) {
                    b_save = true;
                }
            }
        }
    }

    // Kriterien fuer A100 und LUZHB: Bestellink anzeigen falls Verzeichnungsstufe Dossier, Teildossier oder Dokument oder falls keine Stufe vorhanden ist (Handschriften)
    if ((! b_level.Present) || b_level.Dossier || b_level.TDossier || b_level.Dokument) {b_orderableA100 = true; b_orderableLUZHB = true}

    // Kriterien fuer A125: Bestelllink anzeigen falls Verzeichnungsstufe Dossier, Teildossier, Dokument. Bei Bestand und Teilbestand nur wenn keine untergeordneten Katalogisate vorhanden sind, bei Serie und Teilserie nur falls Zugangsbestimmungen vorhanden sind
    if (b_level.Dossier || b_level.TDossier || b_level.Dokument || (( b_level.Bestand || b_level.TBestand ) && (! b_downlinkPresent) ) || (( b_level.Serie || b_level.TSerie ) && b_accessPresent  )) {b_orderableA125 = true}
    // A125 entferne Bestellink wieder, falls in Bearbeitung im Katalogisat vorkommt oder in der Signatur Benutzung eingeschraenkt vorkommt
    if (b_working || b_a125_save) {b_orderableA125 = false}

    // Alle anderen ausser LUZHB und Gosteli: Entferne Bestellink wieder, falls Schutzfristen noch nicht abgelaufen sind
    if (b_save) {b_orderableA100 = false}

    // Setzte Bestelllink

    if (b_systemNumberFound && b_library && (( ((b_library == 'A100') || (b_library == 'A150') || (b_library == 'SGKBV') || (b_library == 'SGSTI') || (b_library == 'SGARK') || (b_library == 'TGKB') ) && b_orderableA100 ) || ((b_library == 'A125') && b_orderableA125 ) || (((b_library == 'LUZHB') || (b_library == 'B445')) && b_orderableLUZHB) )) {
        b_integrateBES(b_table, b_sysNumberText, b_signatur, b_bibPos, b_titleText, b_library); 
    } 
} 
 
// Ende Skript fuer Hanbestellbutton
