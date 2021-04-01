<!-- filename: bestell_script_ibb.js -->

// Skript fuer Bestell-Button per Mailformular
// erstellt fuer Dossierbestellungen SWA 29.01.2015/bmt
// Adaption von eod_script_ibb.js
// Zuerst alle Variablen, die sprachabhaengig geaendert werden muessen:

switch (myLNG) {
    case "ENG":
        var b_labelTit = "Title";
        var b_labelSys = "Sys. no.";
        var b_labelBib = "Library";
        var b_labelBESText = "Order here";
        break;
    case "FRE":
        var b_labelTit = "Titre";
        var b_labelSys = "No. de système";
        var b_labelBib = "Bibliothèque";
        var b_labelBESText = "Commandez ici";
        break;
    // unser default ist GER ...        
    default:
var b_labelTit = "Titel";
        var b_labelSys = "Systemnr.";
        var b_labelBib = "Bibliothek";
        var b_labelBESText = "Bestellen Sie hier";
        break;
}

// function by abi: loescht ueberfluessige HTML-Tags
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
function b_integrateBES(b_table, b_form, b_signatur, b_bibPos, b_titleText) { 

    //var b_besImg = "http://www.ub.unibas.ch/ibb/api/eod-fenster/eod_button_v3.gif";  - Kein Button fuer Dossierbestellungen

    // Definition Link zum Formular
    // Formular braucht folgende Argumente: Typ des Dossiers (b_form); Signatur (b_signatur) und Titel (b_titleText)

    b_signatur = encodeURIComponent(b_signatur);
    b_titleText = encodeURIComponent(b_titleText);

    var b_besURL = 'http://ub.unibas.ch/cgi-bin/cms/cms_dossierbestellung.pl?form=' + b_form + '&sig=' + b_signatur + '&title=' + b_titleText;

    //Integration in OPAC Vollanzeige
    var b_row = b_table.insertRow(b_bibPos); 
    var b_bescell1 = b_row.insertCell(0); 
    b_bescell1.className = 'td1'; 
    var b_bescell2 = b_row.insertCell(1);
    b_bescell2.className = 'td1';
    b_bescell2.innerHTML = '<a href="' + b_besURL + '" target="_blank" title="Bestellung der Dokumentensammlung">' + b_labelBESText + '</a>';
} 
 
// Hauptfunktion by Innsbruck
function b_checkYear(){ 

    // Variablen, die wir nachher brauchen
    var b_table = document.getElementById("bibdat");
    var b_cells = b_table.getElementsByTagName("td"); 
    var b_owner, b_ownerString, b_title, b_titleString, b_titleText; 
    var b_signaturString = new Array();
    var b_ownerUBSWA = false; 
    var b_isDossier = false;
    var b_form = "PV";
    var b_index = 0; 
    // Wir zaehlen die Zellen, damit wir unterscheiden koennen, ob wir in den Labels oder im Fliesstext sind.
    var b_counter = 0;
    var b_systemNumberFound = false; 
    var b_bibPos = -1;
 
    // Lese alle Felder der Vollanzeige nacheinander aus 
    for (b_index = 0; b_index < b_cells.length; b_index++) { 
        b_counter++;
        b_cell = b_cells[b_index]; 

        // Falls Feld Systemnummer:
        if ((b_cell.innerHTML.indexOf(b_labelSys) != -1) && (b_counter % 2 != 0)) { 
            b_systemNumberFound = true; 
        } 

        // Falls Feld Titel:
        if ((b_cell.innerHTML.indexOf(b_labelTit) != -1) && (b_counter % 2 != 0)) { 
            b_title = b_cells[b_index]; 
            b_titleString = b_cells[b_index + 1]; 

            // Pruefung, ob ein Dossier vorliegt (anhand Woerter im Titel):
            if ((b_titleString.innerHTML.indexOf("Dokumentensammlung") != -1) && (b_titleString.innerHTML.indexOf("Virtuelle") == -1) && (b_titleString.innerHTML.indexOf("Fortlaufende") == -1 ) && (b_titleString.innerHTML.indexOf("Elektronische Zeitungsausschnitte") == -1)) {
                // Falls Dossier vorliegt, setzte Variable b_isDossier auf wahr
                b_isDossier = true;
                b_titleText = b_removeTags(b_titleString.innerHTML);
            }
        }
   
        // Falls Feld Exemplarangaben:
        if ((b_cell.innerHTML.indexOf(b_labelBib) != -1) && (b_counter % 2 != 0)) { 
            b_owner = b_cells[b_index]; 
            b_ownerString = b_cells[b_index + 1]; 

            // Pruefe, ob Eigentuemer SWA ist
            if (b_ownerString.innerHTML.indexOf("Basel UB Wirtschaft - SWA") != -1) {
                b_ownerUBSWA = true;

                // Pruefe, ob gewisse Woerter in der Signatur vorkommen, um Typ von Dossier zu bestimmen. Setzte Variable b_form entsprechend (FV, SA oder PV (Standard))
                if ((b_ownerString.innerHTML.indexOf("Aemter") != -1) || (b_ownerString.innerHTML.indexOf("Ausstellungen") != -1) || (b_ownerString.innerHTML.indexOf("Banken") != -1) || (b_ownerString.innerHTML.indexOf("Bv") != -1) || (b_ownerString.innerHTML.indexOf("H + I") != -1) || (b_ownerString.innerHTML.indexOf("Institute") != -1) || (b_ownerString.innerHTML.indexOf("Konferenzen") != -1) || (b_ownerString.innerHTML.indexOf("Konzernges.") != -1) || (b_ownerString.innerHTML.indexOf("Soz. Inst.") != -1) || (b_ownerString.innerHTML.indexOf("Urprod") != -1) || (b_ownerString.innerHTML.indexOf("Verkehr") != -1) || (b_ownerString.innerHTML.indexOf("Versicherungen") != -1)) {
                    b_form = "FV";
                } else if ((b_ownerString.innerHTML.indexOf("Bw") != -1) || (b_ownerString.innerHTML.indexOf("Fw") != -1) || (b_ownerString.innerHTML.indexOf("OR") != -1) || (b_ownerString.innerHTML.indexOf("OS") != -1) || (b_ownerString.innerHTML.indexOf("Recht") != -1) || (b_ownerString.innerHTML.indexOf("Statistik") != -1) || (b_ownerString.innerHTML.indexOf("Vo") != -1) || (b_ownerString.innerHTML.indexOf("ZGB") != -1)) {
                    b_form = "SA";
                }
                
                // Lege Position des Bestelllinks fest (ein Feld unter der Exemplarangabe
                b_bibPos = (b_counter + 1 ) / 2; 	
                // Lies Signatur aus
                var b_rawSignatur = b_removeTags(b_ownerString.innerHTML);
                var b_a = b_rawSignatur.lastIndexOf("Sign");
                var b_signatur = b_rawSignatur.substr(b_a + 12);
                var b_dummy = b_signaturString.push(b_signatur);
            }
        }
    }

    // Pruefe, ob alle Bedingungen erfuellt sind (Systemnummer gefunden, Eigentuemer = SWA, Dossier liegt vor, dann setze den Link
    if (b_systemNumberFound && b_ownerUBSWA && b_isDossier ) {
        b_integrateBES(b_table, b_form, b_signaturString.join("_"), b_bibPos, b_titleText); 
    } 
} 
 
// Ende Skript fuer Dossierbestell-Button
