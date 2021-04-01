#!/usr/bin/perl -T

=for doku

Bestellformular für HAN-Dokumente
- http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl
eingebunden in:
-Noch zu definieren 

Programmlogik
- verifiziert Benutzereingabe und authentifiziert Benuzter im Bibliothekssystem
- schickt Bestellung als Email mit HTML-Attachment an die ILL-Stellen (UTF-8)
- schickt eine Bestätigung an den Absender (sofern Email vorhanden)

Autor:  basil.marti@unibas.ch
basiert auf cms_fernleihebestellung.pl von Andres von Arx

history:
  25.02.2015: v.1
  10.10.2015: v.2  -- Ausweitung auf Gesamtverbund HAN
  01.02.2016: v.3  -- Mehrsprachiges Formular
  20.04.2017: Anpassung für KB Thurgau
=cut

use strict;
use warnings;
use Encode;
use POSIX qw(strftime);
use Net::Domain();
use Mail::Sender; $Mail::Sender::NO_X_MAILER = 1;

use ava::aleph::borrower;
use lib qw( /export/www/cgi-bin/cms );
use lib qw( /home/vonarx/www/cgi-bin/cms );
use CgiCms;
use Data::Dumper;
#use CGI::Carp qw(fatalsToBrowser); 

# CGI security
umask 077;
$ENV{PATH}='/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
$CGI::DISABLE_UPLOADS   = 1;    # disable CGI file uploads
$CGI::POST_MAX          = 4096; # maximum number of bytes per post
$| = 1;
# auskommentieren für Produktion:
($^C) or eval "use CGI::Carp qw(fatalsToBrowser);";

# -----------------------
# Config
# -----------------------
my $DoMail      = 1;   # if true, send mail
my $Testing     = 0;   # if true, use test counter and TestEmail

my $lng;         
my $TestEmail       = '';
my $EmailSMTP       = 'smtp.unibas.ch';
my $CounterURL  = "http://intranet.ub.unibas.ch/php/admin/counter.php?next=";
my %Bestellformular = (
   'ger' => 'cms_hanbestellung_formular.html',
   'eng' => 'cms_hanbestellung_formular_eng.html',
);
my %BestellformularBlank = (
   'ger' => 'cms_hanbestellung_formular_blank.html',
   'eng' => 'cms_hanbestellung_formular_blank_eng.html',
);
my $HeaderTemplate = 'cms_hanbestellung_header_template.html';
my %MailTemplate     = (
   'A100' => 'cms_hanbestellung_mail_template.html',
   'A125' => 'cms_dossierbestellung_mail_template.html',
   'A150' => 'cms_hanbestellung_mail_template.html',
   'B445' => 'cms_hanbestellung_mail_template.html',
   'B583' => 'cms_hanbestellung_mail_template.html',
   'LUZHB' => 'cms_hanbestellung_mail_template.html',
   'SGKBV' => 'cms_hanbestellung_mail_template.html',
   'SGSTI' => 'cms_hanbestellung_mail_template.html',
   'SGARK' => 'cms_hanbestellung_mail_template.html',
   'TGKB' => 'cms_hanbestellung_mail_template.html'
);
my %LibraryName = (
   'ger'  =>  {
       'A100' => 'Universit&auml;tsbibliothek Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli-Stiftung Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB'  => 'Kantonsbibliothek Thurgau'
    },
    'eng' => {
       'A100' => 'University library Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli Foundation Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB'  => 'Kantonsbibliothek Thurgau'
    }
);
my %LibraryNameEmail     = (
   'ger' => {
       'A100' => 'Universitätsbibliothek Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli-Stiftung Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB'  => 'Kantonsbibliothek Thurgau'
    },
    'eng' => {
       'A100' => 'Universitätsbibliothek Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli-Stiftung Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB'  => 'Kantonsbibliothek Thurgau'
    }
);
my %LibraryNotes     = (
   'ger' => {
       'A100' => 'Ihre Bestellung konsultieren Sie im Sonderlesesaal der UB Basel (&Ouml;ffnungszeiten: Montag bis Freitag, 9.00 - 19.00 Uhr). Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A100">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:hss-ub@unibas.ch">Mail</a> an uns zu wenden.',
       'A125' => 'Bestellungen werden in der Regel zwischen 9 und 16 Uhr innerhalb einer halben Stunde bereitgestellt.',
       'A150' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A150">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:sondersammlungen@zbsolothurn.ch">Mail</a> an uns zu wenden.',
       'B445' => 'Die Gosteli-Stiftung und das Archiv zur Geschichte der schweizerischen Frauenbewegung sind Dienstag, Donnerstag und Freitag von 09.00h bis 17.00h ge&ouml;ffnet. Wir werden Ihnen Ihren Besuch und die Konsultation der genannten Unterlagen so rasch wie m&ouml;glich per E-Mail best&auml;tigen. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers konsultieren und diese nicht einzeln bestellen oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, die gew&uuml;nschten Signaturen oder Best&auml;nde entweder im Bemerkungsfeld anzugeben oder sich per <a href="mailto:info@gosteli-foundation.ch">E-Mail</a> an uns zu wenden.',
       'B583' => 'to be defined',
       'LUZHB' => 'Bitte beachten Sie, dass sich die ZHB Sondersammlung am Standort Sempacherstrasse befindet. Die &Ouml;ffnungszeiten sind: Dienstag bis Donnerstag, 09:00 bis 17:00.',
       'SGKBV' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGKBV">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:kb.rara@sg.ch">Mail</a> an uns zu wenden.',
       'SGSTI' => 'F&uuml;r die Einsichtnahme in Handschriften und Inkunabeln sind eine Anmeldung mit Angabe des wissenschaftlichen Zwecks, eine Begr&uuml;ndung, weshalb das Original eingesehen werden muss sowie die Angabe einer Referenzperson erforderlich. Bei der Einsichtnahme muss eine g&uuml;ltige Identit&auml;tskarte oder ein g&uuml;ltiger Pass vorgewiesen werden.', 
       'SGARK' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGARK">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:kantonsbibliothek@ar.ch">Mail</a> an uns zu wenden.',
       'TGKB' => 'Wir bitten Sie, Handschriften eine Woche vor der gew&uuml;nschten Konsultation zu bestellen. Ihre Bestellung konsultieren Sie unter Aufsicht am Rara-Arbeitsplatz der Kantonsbibliothek Thurgau (&Ouml;ffnungszeiten: Montag: 14-18 Uhr, Dienstag bis Freitag: 10-18 Uhr).' 
    },
    'eng' => {
       'A100' => 'Ihre Bestellung konsultieren Sie im Sonderlesesaal der UB Basel (&Ouml;ffnungszeiten: Montag bis Freitag, 9.00 - 19.00 Uhr). Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A100">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:hss-ub@unibas.ch">Mail</a> an uns zu wenden.',
       'A125' => 'Bestellungen werden in der Regel zwischen 9 und 16 Uhr innerhalb einer halben Stunde bereitgestellt.',
       'A150' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=A150">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:sondersammlungen@zbsolothurn.ch">Mail</a> an uns zu wenden.',
       'B445' => 'Die Gosteli-Stiftung und das Archiv zur Geschichte der schweizerischen Frauenbewegung sind Dienstag, Donnerstag und Freitag von 09.00h bis 17.00h ge&ouml;ffnet. Wir werden Ihnen Ihren Besuch und die Konsultation der genannten Unterlagen so rasch wie m&ouml;glich per E-Mail best&auml;tigen. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers konsultieren und diese nicht einzeln bestellen oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, die gew&uuml;nschten Signaturen oder Best&auml;nde entweder im Bemerkungsfeld anzugeben oder sich per <a href="mailto:info@gosteli-foundation.ch">E-Mail</a> an uns zu wenden.',
       'B583' => 'to be defined',
       'LUZHB' => 'Bitte beachten Sie, dass sich die ZHB Sondersammlung am Standort Sempacherstrasse befindet. Die &Ouml;ffnungszeiten sind: Dienstag bis Donnerstag, 09:00 bis 17:00.',
       'SGKBV' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGKBV">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:kb.rara@sg.ch">Mail</a> an uns zu wenden.',
       'SGSTI' => 'F&uuml;r die Einsichtnahme in Handschriften und Inkunabeln sind eine Anmeldung mit Angabe des wissenschaftlichen Zwecks, eine Begr&uuml;ndung, weshalb das Original eingesehen werden muss sowie die Angabe einer Referenzperson erforderlich. Bei der Einsichtnahme muss eine g&uuml;ltige Identit&auml;tskarte oder ein g&uuml;ltiger Pass vorgewiesen werden.', 
       'SGARK' => 'Bestellungen f&uuml;r Handschriften f&uuml;hren wir in der Regel sofort aus. Bestellungen aus Nachl&auml;ssen liegen, abh&auml;ngig von deren Umfang, nach einigen Arbeitstagen bereit. M&ouml;chten Sie mehrere Dokumente bzw. Dossiers oder gr&ouml;ssere Best&auml;nde einsehen, so bitten wir Sie, dies entweder im Bemerkungsfeld anzugeben, das <a href="http://www.ub.unibas.ch/cgi-bin/cms/cms_hanbestellung.pl?lib=SGARK">Blankoformular</a> auszuf&uuml;llen oder sich per <a href="mailto:kantonsbibliothek@ar.ch">Mail</a> an uns zu wenden.',
       'TGKB' => 'Wir bitten Sie, Handschriften eine Woche vor der gew&uuml;nschten Konsultation zu bestellen. Ihre Bestellung konsultieren Sie unter Aufsicht am Rara-Arbeitsplatz der Kantonsbibliothek Thurgau (&Ouml;ffnungszeiten: Montag: 14-18 Uhr, Dienstag bis Freitag: 10-18 Uhr).' 
    }
);
my %LibraryEmailNotes = (
    'ger' => {
        'A100' => 'Ihre Bestellung konsultieren Sie im Sonderlesesaal der UB Basel 
(Öffnungszeiten: Montag bis Freitag, 9.00 - 19.00 Uhr). 
Bestellungen für Handschriften führen wir in der Regel sofort aus. 
Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'A125' => 'Bestellungen werden in der Regel zwischen 9 und 16 Uhr innerhalb einer halben Stunde bereitgestellt.',
        'A150' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'B445' => 'Die Gosteli-Stiftung und das Archiv zur Geschichte der schweizerischen Frauenbewegung sind Dienstag, Donnerstag und Freitag von 09.00h bis 17.00h geöffnet. 
Wir werden Ihnen Ihren Besuch und die Konsultation der genannten Unterlagen so rasch wie möglich per E-Mail bestätigen.',
        'B583' => 'to be defined', 
        'LUZHB' => 'Bitte beachten Sie, dass sich die ZHB Sondersammlung am Standort Sempacherstrasse befindet. Die Öffnungszeiten sind: Dienstag bis Donnerstag, 09:00 bis 17:00.',
        'SGKBV' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'SGSTI' => 'Für die Einsichtnahme in Handschriften und Inkunabeln sind eine Anmeldung mit Angabe des wissenschaftlichen Zwecks, eine Begründung, weshalb das Original eingesehen werden muss sowie die Angabe einer Referenzperson erforderlich. Bei der Einsichtnahme muss eine gültige Identitätskarte oder ein gültiger Pass vorgewiesen werden.',
        'SGARK' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'TGKB' => 'Wir bitten Sie, Handschriften eine Woche vor der gewünschten Konsultation zu bestellen. Ihre Bestellung konsultieren Sie unter Aufsicht am Rara-Arbeitsplatz der Kantonsbibliothek Thurgau (Öffnungszeiten: Montag: 14-18 Uhr, Dienstag bis Freitag: 10-18 Uhr).' 
    },
    'eng' => {
        'A100' => 'Ihre Bestellung konsultieren Sie im Sonderlesesaal der UB Basel 
(Öffnungszeiten: Montag bis Freitag, 9.00 - 19.00 Uhr). 
Bestellungen für Handschriften führen wir in der Regel sofort aus. 
Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'A125' => 'Bestellungen werden in der Regel zwischen 9 und 16 Uhr innerhalb einer halben Stunde bereitgestellt.',
        'A150' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'B445' => 'Die Gosteli-Stiftung und das Archiv zur Geschichte der schweizerischen Frauenbewegung sind Dienstag, Donnerstag und Freitag von 09.00h bis 17.00h geöffnet. 
Wir werden Ihnen Ihren Besuch und die Konsultation der genannten Unterlagen so rasch wie möglich per E-Mail bestätigen.',
        'B583' => 'to be defined', 
        'LUZHB' => 'Bitte beachten Sie, dass sich die ZHB Sondersammlung am Standort Sempacherstrasse befindet. Die Öffnungszeiten sind: Dienstag bis Donnerstag, 09:00 bis 17:00.',
        'SGKBV' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'SGSTI' => 'Für die Einsichtnahme in Handschriften und Inkunabeln sind eine Anmeldung mit Angabe des wissenschaftlichen Zwecks, eine Begründung, weshalb das Original eingesehen werden muss sowie die Angabe einer Referenzperson erforderlich. Bei der Einsichtnahme muss eine gültige Identitätskarte oder ein gültiger Pass vorgewiesen werden.',
        'SGARK' => 'Bestellungen für Handschriften führen wir in der Regel sofort aus. Bestellungen aus Nachlässen liegen, abhängig von deren Umfang, nach einigen Arbeitstagen bereit.',
        'TGKB' => 'Wir bitten Sie, Handschriften eine Woche vor der gewünschten Konsultation zu bestellen. Ihre Bestellung konsultieren Sie unter Aufsicht am Rara-Arbeitsplatz der Kantonsbibliothek Thurgau (Öffnungszeiten: Montag: 14-18 Uhr, Dienstag bis Freitag: 10-18 Uhr).' 
    }
);
my %LibraryInfoLink     = (
   'ger' => {
       'A100' => 'http://www.ub.unibas.ch/han/verbundpartner/universitaetsbibliothek-basel/',
       'A125' => 'http://www.ub.unibas.ch/han/verbundpartner/schweizerisches-wirtschaftsarchiv/',
       'A150' => 'http://www.ub.unibas.ch/han/verbundpartner/zentralbibliothek-solothurn/',
       'B445' => 'http://www.ub.unibas.ch/han/verbundpartner/gosteli-stiftung/',
       'B583' => 'http://www.ub.unibas.ch/han/verbundpartner/archiv-und-sammlung-hermann-rorschach/',
       'LUZHB' => 'http://www.ub.unibas.ch/han/verbundpartner/zentral-und-hochschulbibliothek-luzern/',
       'SGKBV' => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-vadiana-st-gallen/',
       'SGSTI' => 'http://www.ub.unibas.ch/han/verbundpartner/stiftsbibliothek-st-gallen/', 
       'SGARK' => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-appenzell-ausserrhoden/',
       'TGKB'  => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-thurgau/'
   },
   'eng' => {
       'A100' => 'http://www.ub.unibas.ch/han/verbundpartner/universitaetsbibliothek-basel/',
       'A125' => 'http://www.ub.unibas.ch/han/verbundpartner/schweizerisches-wirtschaftsarchiv/',
       'A150' => 'http://www.ub.unibas.ch/han/verbundpartner/zentralbibliothek-solothurn/',
       'B445' => 'http://www.ub.unibas.ch/han/verbundpartner/gosteli-stiftung/',
       'B583' => 'http://www.ub.unibas.ch/han/verbundpartner/archiv-und-sammlung-hermann-rorschach/',
       'LUZHB' => 'http://www.ub.unibas.ch/han/verbundpartner/zentral-und-hochschulbibliothek-luzern/',
       'SGKBV' => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-vadiana-st-gallen/',
       'SGSTI' => 'http://www.ub.unibas.ch/han/verbundpartner/stiftsbibliothek-st-gallen/', 
       'SGARK' => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-appenzell-ausserrhoden/',
       'TGKB'  => 'http://www.ub.unibas.ch/han/verbundpartner/kantonsbibliothek-thurgau/'
   }
);
my %LibraryNameHeader     = (
   'ger' => {
       'A100' => 'Universitaetsbibliothek Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli-Stiftung Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB'  => 'Kantonsbibliothek Thurgau'
    },
    'eng' => {
       'A100' => 'Universitaetsbibliothek Basel',
       'A125' => 'Schweizerisches Wirtschaftsarchiv',
       'A150' => 'Zentralbibliothek Solothurn',
       'B445' => 'Gosteli-Stiftung Bern',
       'B583' => 'Rorschach-Archiv Bern',
       'LUZHB' => 'Zentral- und Hochschulbibliothek Luzern',
       'SGKBV' => 'Kantonsbibliothek Vadiana St. Gallen',
       'SGSTI' => 'Stiftsbibliothek St. Gallen',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden',
       'TGKB' => 'Kantonsbibliothek Thurgau'
    }
);
my %PaperEmail      = (
   'A100' => '',
   'A125' => '',
   'A150' => '',
   'B445' => '',
   'B583' => '',
   'LUZHB' => '',
   'SGKBV' => '',
   'SGSTI' => '',
   'SGARK' => '',
   'TGKB'  => '',
);
my %Signature  = (
   'ger' => {
       'A100' => 'UNIVERSITÄT BASEL
Universitätsbibliothek
Abteilung Handschriften und Alte Drucke
Schönbeinstrasse 18-20
4056 Basel, Schweiz
Tel. direkt +41 (0)61 267 29 93
Fax +41 (0)61 267 31 03
E-Mail hss-ub@unibas.ch
URL http://www.ub.unibas.ch',
       'A125' => 'UB Wirtschaft - SWA
Information und Fernleihe
ill-ubw-swa@unibas.ch',
       'A150' => 'Zentralbibliothek Solothurn
Sondersammlungen
Bielstr. 39, Postfach
4502 Solothurn

sondersammlungen@zbsolothurn.ch',
       'B445' => 'Gosteli-Stiftung
Archiv zur Geschichte der schweizerischen Frauenbewegung
Altikofenstrasse 186
3048 Worblaufen
www.gosteli-foundation.ch
info@gosteli-foundation.ch',
       'B583' => 'to be defined',
       'LUZHB' => 'KANTON LUZERN
Zentral- & Hochschulbibliothek Luzern

Sondersammlung
Standort Semparcherstrasse
Sempacherstrasse 10
Postfach 4469
6002 Luzern / Switzerland

sosa@zhbluzern.ch
www.zhbluzern.ch',
       'SGKBV' => 'Kantonsbibliothek Vadiana
Historische Bestände und Sammlungen
Notkerstrasse 22
9000 St. Gallen
Tel.: +58 229 23 40
kb.rara@sg.ch
http://www.kb.sg.ch',
       'SGSTI' => 'Lesesaal / Ausleihe
Stiftsbibliothek St. Gallen, Klosterhof 6d, Postfach, 9004 Ste. Gallen / Schweiz
T +41 71 227 34 17, stibi@stibi.ch, www.stiftsbibliothek.ch',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden
Landsgemeindeplatz 1/7
CH-9043 Trogen
+41 71 343 64 21
kantonsbibliothek@ar.ch',
       'TGKB' => 'Kanton Thurgau
Departement für Erziehung und Kultur (DEK)
Kantonsbibliothek
Promenadenstrasse 12
8510 Frauenfeld
Tel. +41 (0)58 345 69 05

E-Mail: joana.keller@tg.ch

Homepage: www.kantonsbibliothek.tg.ch
Facebook: www.facebook.com/KantonsbibliothekThurgau'
    },
    'eng' => {
       'A100' => 'UNIVERSITÄT BASEL
Universitätsbibliothek
Abteilung Handschriften und Alte Drucke
Schönbeinstrasse 18-20
4056 Basel, Schweiz
Tel. direkt +41 (0)61 267 29 93
Fax +41 (0)61 267 31 03
E-Mail hss-ub@unibas.ch
URL http://www.ub.unibas.ch',
       'A125' => 'UB Wirtschaft - SWA
Information und Fernleihe
ill-ubw-swa@unibas.ch',
       'A150' => 'Zentralbibliothek Solothurn
Sondersammlungen
Bielstr. 39, Postfach
4502 Solothurn

sondersammlungen@zbsolothurn.ch',
       'B445' => 'Gosteli-Stiftung
Archiv zur Geschichte der schweizerischen Frauenbewegung
Altikofenstrasse 186
3048 Worblaufen
www.gosteli-foundation.ch
info@gosteli-foundation.ch',
       'B583' => 'to be defined',
       'LUZHB' => 'KANTON LUZERN
Zentral- & Hochschulbibliothek Luzern

Sondersammlung
Standort Semparcherstrasse
Sempacherstrasse 10
Postfach 4469
6002 Luzern / Switzerland

sosa@zhbluzern.ch
www.zhbluzern.ch',
       'SGKBV' => 'Kantonsbibliothek Vadiana
Historische Bestände und Sammlungen
Notkerstrasse 22
9000 St. Gallen
Tel.: +58 229 23 40
kb.rara@sg.ch
http://www.kb.sg.ch',
       'SGSTI' => 'Lesesaal / Ausleihe
Stiftsbibliothek St. Gallen, Klosterhof 6d, Postfach, 9004 Ste. Gallen / Schweiz
T +41 71 227 34 17, stibi@stibi.ch, www.stiftsbibliothek.ch',
       'SGARK' => 'Kantonsbibliothek Appenzell Ausserrhoden
Landsgemeindeplatz 1/7
CH-9043 Trogen
+41 71 343 64 21
kantonsbibliothek@ar.ch',
       'TGKB' => 'Kanton Thurgau
Departement für Erziehung und Kultur (DEK)
Kantonsbibliothek
Promenadenstrasse 12
8510 Frauenfeld
Tel. +41 (0)58 345 69 05

E-Mail: joana.keller@tg.ch

Homepage: www.kantonsbibliothek.tg.ch
Facebook: www.facebook.com/KantonsbibliothekThurgau'
    }
);
my %CounterURL     = (
   'A100' => $CounterURL . 'BES_HAN_A100',
   'A125' => $CounterURL . 'BES_HAN_A125',
   'A150' => $CounterURL . 'BES_HAN_A150',
   'B445' => $CounterURL . 'BES_HAN_B445',
   'B583' => 'to be defined',
   'LUZHB' => $CounterURL . 'BES_HAN_LUZHB',
   'SGKBV' => $CounterURL . 'BES_HAN_SGKBV',
   'SGSTI' => $CounterURL . 'BES_HAN_SGSTI',
   'SGARK' => $CounterURL . 'BES_HAN_SGARK',
   'TGKB'  => $CounterURL . 'BES_HAN_TGKB'
);
my %ButtonContinue = (
    'ger' => 'weiter >>',
    'eng' => 'continue >>'
);
my %ButtonBack = (
    'ger' => '<< zurück',
    'eng' => '<< return'
);
my %ButtonPrint = (
    'ger' => 'Drucken',
    'eng' => 'Print'
);

my %SubjectSender = (
    'ger' => 'Lesesaalbestellung HAN',
    'eng' => 'Reading room order HAN',
);
    
my %PleaseConfirm = (
    'ger' => 'Bitte bestätigen Sie Ihre Eingabe:',
    'eng' => 'Please confirm your order:'
);

my %YourOrder = (
    'ger' => 'Ihre Bestellung:',
    'eng' => 'Your order:'
);

my %YourData = (
    'ger' => 'Ihre persönlichen Daten:',
    'eng' => 'Your personal data:'
);

my %OrderSent = (
    'ger' => 'Ihre Bestellung wurde übermittelt',
    'eng' => 'Your order has been sent',
);

my %Confirmation = (
    'ger' => 'Sie erhalten eine Bestätigung per E-Mail.', 
    'eng' => 'You will receive an e-mail confirmation',
);

# -----------------------
# CGI handling
# -----------------------
my $q = CgiCms->new;
my(%Buch, @Buch, %User, @User, $Config);
#$lng = (lc $q->param('lng'));
$lng = 'ger';

if (!$q->param('action') ) {
    print_bestellformular();
} else {
    init_data();
    $q->param('uid', uc($q->param('uid')));
    if ( $q->param('action') eq 'submit' ) {
        print $q->header(-type=>'text/html; charset=UTF-8');
        open(F,"<$HeaderTemplate") or die "cannot read $HeaderTemplate: $!";
        local $/;
        $_ = <F>;
        print $_;
        if ( $q->param('uid') && $q->param('pwd')) {
           print_confirm_uid();
        }
        else {
           print_confirm();
        }
        print qq|</div>|;
    }
    elsif ( $q->param('action') eq 'confirm' ) {
        mail_local_bes();
        mail_receipt();
    }
    else {
        print $q->p('unknown action');
    }
}
# ------------------
sub print_bestellformular {
# ------------------
    # Bestellformular (aus Template)

    my $url = $q->url();
    my $sys = $q->param('sys'); 
    my $sig = $q->param('sig'); 
    my $lib = $q->param('lib'); 
    my $title = $q->param('title'); 

    if ($lib && $sys && $sig && $title) {

       print $q->header(-type=>'text/html; charset=UTF-8');
       open(F,"<$Bestellformular{$lng}") or die "cannot read $Bestellformular{$lng}: $!";
       local $/;
       $_ = <F>;

       s|%%MYSYS%%|$sys|g;
       s|%%MYSIG%%|$sig|g;
       s|%%MYLIB%%|$lib|g;
       s|%%MYLNG%%|$lng|g;

       s|%%MYLIBNAME%%|$LibraryName{$lng}{$lib}|g;
       s|%%MYLIBNOTES%%|$LibraryNotes{$lng}{$lib}|g;
       s|%%MYLIBLINK%%|$LibraryInfoLink{$lng}{$lib}|g;
       s|%%MYTITLE%%|$title|g;
       s|%%MYURL%%|$url|g;
       print $_;

    } elsif ($lib && !$sys && !$sig && !$title) {

       print $q->header(-type=>'text/html; charset=UTF-8');
       open(F,"<$BestellformularBlank{$lng}") or die "cannot read $BestellformularBlank{$lng}: $!";
       local $/;
       $_ = <F>;

       s|%%MYLNG%%|$lng|g;
       s|%%MYLIB%%|$lib|g;
       s|%%MYLIBNAME%%|$LibraryName{$lng}{$lib}|g;
       s|%%MYLIBNOTES%%|$LibraryNotes{$lng}{$lib}|g;
       s|%%MYLIBLINK%%|$LibraryInfoLink{$lng}{$lib}|g;
       s|%%MYURL%%|$url|g;
       print $_;
    } else {exit;}
}

# ------------------
sub print_confirm {
# ------------------
    # - Zeige die Benutzereingabe
    # - keine Authentifizierung des Benutzers in Aleph
    # - Verlange Bestätigung der Bestellung
    #
    $q->delete('action');

    print $q->h1($PleaseConfirm{$lng}),
        qq|<div style='padding-left:20px'>|,
        $q->br,
        $q->start_form(-method=>'POST',-name=>'BES',-action=>$q->url()),
        back_button(),
        ok_button();
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>$YourOrder{$lng}</b></td></tr>|;
    foreach my $field ( @Buch ) {
        print $table->td( $Buch{$field}, $q->param($field) || ' ' );
    }
    print $table->footer;

    # --- print borrower data
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>$YourData{$lng}</b></td></tr>|;
    foreach my $field ( @User ) {
        print $table->td( $User{$field}, $q->param($field) || ' ' );
    }
    print $table->footer;

    # -- print user input as hidden fields

    foreach my $field ( @Buch ) {
        print $q->hidden( $field, $q->param($field) );
    }

    foreach my $field ( @User ) {
        print $q->hidden( $field, $q->param($field) );
    }
    
    print $q->hidden('lng',$q->param('lng') );
    print $q->hidden('sys',$q->param('lib') );
    print $q->hidden('lib',$q->param('sys') );
    print $q->hidden('action','confirm');
    
    print $q->br,
        back_button(),
        ok_button(),
        $q->end_form;
    print qq|</div>|;
}

# ------------------
sub print_confirm_uid {
# ------------------
    # - Zeige die Benutzereingabe
    # - Authentifiziere den Benutzer in Aleph
    # - Verlange Bestätigung der Bestellung
    #

    print $q->h1($PleaseConfirm{$lng}),
        qq|<div style='padding-left:20px'>|,
        $q->br,
        $q->start_form(-method=>'POST',-name=>'BES',-action=>$q->url()),
        back_button(),
        ok_button();
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>$YourOrder{$lng}</b></td></tr>|;
    foreach my $field ( @Buch ) {
        print $table->td( $Buch{$field}, $q->param($field) || ' ' );
    }
    print $table->footer;

    # -- hole Benutzerinfo von Aleph (UTF-8)
    my $uid = $q->param('uid') || ' ';
    my $pwd = $q->param('pwd') || ' ';
    $q->delete('action');
    $q->delete('pwd');
    my $bor = ava::aleph::borrower->new({
        library  => 'DSV51',
        uid      => $uid,
        pwd      => $pwd,
        host     => 'aleph.unibas.ch',
        charset  => 'utf8',
    });
    if ( $bor->login and $bor->info ) {
        # -- borrower info found
        $q->param('-name' => 'uid', '-value' => $bor->{info}->{userid}); # use 'official' (Z303) user id
        # --- print borrower data
        my $table = CgiCms_Table->new(typ=>'grau');
        print $table->header(colgroup => [200,'*']),
            qq|<tr><td colspan="2"><b>$YourData{$lng}</b></td></tr>|,
            $table->td('Benutzernummer',$q->param('uid'));
        foreach my $field ( @User ) {
            print $table->td( $User{$field}, $bor->{info}->{$field});
        }
        print $table->footer;
        print $q->hidden('uid', $q->param('uid')),
            $q->hidden('action','confirm');
    }
    else {
        # -- borrower info not found
        print_retype_pwd($bor->err);
        print $q->hidden('action','submit');
    }
    # -- print user input as hidden fields
    foreach my $field ( @Buch ) {
        print $q->hidden( $field, $q->param($field) );
    }
    foreach my $field ( @User ) {
        # aus irgendwelchen Gruenden konvertiert $q->hidden hier
        # den Inhalt der Felder in UTF-8. Wir machen deshalb unsere
        # eigenen Hidden Fields
        my $val = $bor->{info}->{$field};
        $val =~ s/\n/&#10;/g;
        $val =~ s/\"/&quot;/g;
        print qq|<input type="hidden" name="$field" value="$val">|;
    }
    print $q->hidden('lng',$q->param('lng') );
    print $q->hidden('lib',$q->param('lib') );
    print $q->hidden('sys',$q->param('sys') );
    print $q->br,
        back_button(),
        ok_button(),
        $q->end_form;
}
# ------------------
sub mail_local_bes {
# ------------------
    # - konstruiert und speichert eine Auftragsnummer
    # - formatiert die Bestellung als HTML-Seite für die Fernleihstelle
    # - sendet die HTML-Seite als Attachment (oder dumpt sie);
    #
    my $nc = LWP::Simple::get($CounterURL{$q->param('lib')});
    unless ( $nc =~ s/^ok\|// ) {
        $nc = '?';
    }
    my $AUFTRAGSNUMMER;
    if ( $q->param('uid') ) {
        $AUFTRAGSNUMMER = strftime("%Y.%m.%d-",localtime) .$q->param('uid') .'-' .$q->param('lib') .'-' .$nc;
    } else {
        $AUFTRAGSNUMMER = strftime("%Y.%m.%d-",localtime) .$q->param('name') .'-' .$q->param('lib') .'-'  .$nc; 
    }

    $Config->{AUFTRAGSNUMMER} = $AUFTRAGSNUMMER;

    my $to      = $PaperEmail{$q->param('lib')};
    my $from    = $SubjectSender{$lng} . ' <' .$PaperEmail{($q->param('lib'))} .'>';
    my $subject = $SubjectSender{$lng} . ' ' . $AUFTRAGSNUMMER;
    my $fname   = 'han-bestellung-' .$AUFTRAGSNUMMER .'.html';
    my $html    = format_local_bes();

    if ( $DoMail ) {
        if ( $Testing ) {
            $to = $TestEmail;
        }
        my $client = Net::Domain::hostfqdn;
        my $sender;
        ref($sender = new Mail::Sender {
            smtp => $EmailSMTP,
            from => $from,
            to => $to,
            subject => $subject,
            client => $client,
        }) or cannot_mail_msg($sender);
        $sender->OpenMultipart({
            description => $subject,
            ctype       => 'text/html',
            encoding    => 'quoted-printable',
        });
        $sender->Body;
        $sender->SendEnc($html);
        $sender->Close;
        if ( $sender->{error} ) {
           cannot_mail_msg($sender->{error});
        }
    }
    else {
        $html =~ s|</?html>||g;
        $html =~ s|<!DOCTYPE .*$||;
        my $vorspann = <<EOD;
From:     $from
To:       $to
Subject:  $subject
Template: $MailTemplate{$q->param('$lib')}
EOD
        print '<pre>', CGI::escapeHTML($vorspann), '</pre><hr />', $html;
    }
}

# ------------------
sub format_local_bes {
# ------------------
    # Formatiert die Bestellung als HTML-Seite.
    local $_;
    my %stv;
    # baue eine Liste der Stellvertreter (%stv) mit den Inhalten,
    # die ins Template eingefuegt werden sollen:
    $stv{besno} = $Config->{AUFTRAGSNUMMER};
    $stv{submitDate} = strftime("%A, %d. %B %Y %H:%M:%S",localtime);
    foreach my $key ( @User ) {
        $_ = $q->param($key);
        s|\n|<br/>|g;

        $stv{$key} = $_ || '';
    }
    foreach my $key ( @Buch ) {
        $_=$q->param($key);
        $stv{$key} = $_ || '';
    }
    $stv{sys} = $q->param('sys');
    $stv{uid} = $q->param('uid');
    $stv{time} = '';
    $stv{newspaper} = '';
    $stv{brochure} = '';
    $stv{report} = '';
    $stv{misc_content} = '';
    # hole das Template und ersetze die Stellvertreter mit Inhalten
    open(F,"<$MailTemplate{$q->param('lib')}") or die "cannot read $MailTemplate{$q->param('lib')}: $!";
    { local $/; $_ = <F>; }
    close F;
    foreach my $key ( keys %stv ) {
        if ( $key eq 'email' && $stv{$key} !~ /\s/ && $stv{$key} =~ /\w\@\w/ ) {
            $stv{$key} = "<a href=\"mailto:$stv{$key}\">$stv{$key}</a>";
        } else {
            $stv{$key} =~ s/\<br\/\>/, /g;
            $stv{$key} = CGI::escapeHTML($stv{$key});
        }
        s/%%$key%%/$stv{$key}/g;
    }
    $_;
}
# ------------------
sub mail_receipt {
# ------------------
    # Schicke eine Bestätigungssmail an den Benutzer.
    # Bei zweifelhafter Emailadresse: zeige die Bestätigung als Text.
    #
    { 
       print $q->header(-type=>'text/html; charset=UTF-8');
       open(F,"<$HeaderTemplate") or die "cannot read $HeaderTemplate: $!";
       local $/;
       $_ = <F>;
       print $_;
    }

    print $q->h1($OrderSent{$lng});
    
    print qq|<div style='padding-left:20px'>|;
    my $mailmsg = format_receipt();
    my $mail_to = $q->param('email');
    if ( $mail_to && $mail_to !~ /\s/ && $mail_to =~ /\w\@\w/ ) {
        my $to = $q->param('email');
        my $from    = $LibraryNameHeader{$lng}{$q->param('lib')} . ' <' . $PaperEmail{$q->param('lib')} .'>';
        my $localhost = Net::Domain::hostfqdn();
        if ( $DoMail ) {
            Encode::from_to($mailmsg,'utf-8','iso-8859-1');
            my $Mailer = Mail::Sender->new({
                from =>     $from,
                to =>       $to,
                subject =>  $SubjectSender{$lng},
                smtp =>     'smtp.unibas.ch',
                client =>   $localhost,
                charset =>  'ISO-8859-1',
                encoding => '8BIT',
            });
            if ( ref($Mailer) &&  ref( $Mailer->MailMsg({ msg => $mailmsg })) ) {
                print $q->p($Confirmation{$lng});
            }
        } else {
            $mailmsg = <<EOD;
From:    $from
To:      $to
Subject: $SubjectSender{$lng}

$mailmsg
EOD
            print '<pre>', CGI::escapeHTML($mailmsg), '</pre><hr/>';
        }
    } else {
        print '<pre>', CGI::escapeHTML($mailmsg), '</pre><hr/>';
        print qq|<input style="width:100px;font-weight:bold" type="button" id="bes_butt1" value=$ButtonPrint{$lng} name="b1" onClick="window.print()" />|;
    }
    print qq|</div>|;
    print $q->xhtml_footer;
    
    #print $q->p( $q->internal_link(
    #        url=> $q->url,
    #        text=>'zurück zum Bestellformular',
    #        target=>'_self',
    #        ));
}
# ------------------
sub format_receipt {
# ------------------
    # formatiere die Bestätigungs-Email
    #
    my $AUFTRAGSNUMMER = $Config->{AUFTRAGSNUMMER};
    my $SIGNATURE = $Signature{$lng}{$q->param('lib')};

    my $LIBRARYNAME = $LibraryNameEmail{$lng}{$q->param('lib')};
    unless ($lng eq 'eng') {
        if ($LIBRARYNAME =~ /rchiv/ ) {
            $LIBRARYNAME = 'im ' . $LIBRARYNAME;
            $LIBRARYNAME =~ s/Schweizerisches/Schweizerischen/
        } else {
            $LIBRARYNAME = 'in der ' . $LIBRARYNAME
        }
    }

    my $LIBRARYNOTE = $LibraryEmailNotes{$lng}{$q->param('lib')};
    my $DATUM = strftime("%d.%m.%Y %H:%M:%S",localtime);
    my $txt;
    if ($lng eq 'ger') {
        $txt =  <<EOD;
Besten Dank für Ihre Lesesaalbestellung $LIBRARYNAME.

Die Konsultation der gewünschten Dokumente kann aus rechtlichen oder konservatorischen Gründen 
bzw. aufgrund von Vorgaben des Bestandseigentümers (Deposita) nur eingeschränkt möglich sein. 
Falls es Einschränkungen gibt, erhalten Sie von uns eine Mitteilung.

$LIBRARYNOTE

Auftragsnummer: $AUFTRAGSNUMMER
Datum: $DATUM

EOD
}
    elsif ($lng eq 'eng') {
        $txt =  <<EOD;
Thank you for your reading room order in the $LIBRARYNAME.

Die Konsultation der gewünschten Dokumente kann aus rechtlichen oder konservatorischen Gründen
bzw. aufgrund von Vorgaben des Bestandseigentümers (Deposita) nur eingeschränkt möglich sein.
Falls es Einschränkungen gibt, erhalten Sie von uns eine Mitteilung.

$LIBRARYNOTE

Auftragsnummer: $AUFTRAGSNUMMER
Datum: $DATUM

EOD
}
foreach my $field ( @Buch ) {
   if ( $q->param($field) ) {
       $txt .= $Buch{$field} .': ' .$q->param($field) ."\n";
   }
}

if ($lng eq 'ger') {
    $txt .= <<EOD;

Wir danken für Ihren Auftrag.

$SIGNATURE
EOD
} elsif ($lng eq 'eng') {
    $txt .= <<EOD;

Wir danken für Ihren Auftrag.

$SIGNATURE
EOD
}
$txt;
}
# ------------------
sub print_retype_pwd {
# ------------------
    # nach Fehler (falsche uid/pwd oder Kommunikationsstoerung)
    # erneuter Versuch zur Eingabe von uid/pwd
    my $err = shift;
    my $uid = $q->param('uid');
    $q->delete('uid');
    if ($lng eq 'ger') {
    print<<EOD;
<h2 style='padding-left:0px'>Verarbeitungsfehler</h2>
<p style='padding-left:0px'>Ihre Benutzerdaten im Bibliothekskatalog IDS Basel / Bern konnten nicht gelesen werden.<br/>
Meldung: <strong>$err</strong>.</p>
<p style='padding-left:0px'>Bitte versuchen Sie es erneut:</p>
<br/>
<br/>
<label for="bes_uid">Ausweis-/Benutzernummer<span class="rot">*</span></label>
<input style="width:150px" type="text" value="$uid" name="uid" id="bes_uid" size="50"/>
<br/>
<label for="bes_pwd">Passwort<span class="rot">*</span></label>
<input style="width:150px" class="short" type="password" name="pwd" id="bes_pwd"/>

EOD
    } elsif ($lng eq 'eng') {

    print<<EOD;
<h2 style='padding-left:0px'>Verarbeitungsfehler</h2>
<p style='padding-left:0px'>Ihre Benutzerdaten im Bibliothekskatalog IDS Basel / Bern konnten nicht gelesen werden.<br/>
Meldung: <strong>$err</strong>.</p>
<p style='padding-left:0px'>Bitte versuchen Sie es erneut:</p>
<br/>
<br/>
<label for="bes_uid">Ausweis-/Benutzernummer<span class="rot">*</span></label>
<input style="width:150px" type="text" value="$uid" name="uid" id="bes_uid" size="50"/>
<br/>
<label for="bes_pwd">Passwort<span class="rot">*</span></label>
<input style="width:150px" class="short" type="password" name="pwd" id="bes_pwd"/>

EOD
    }
}
# ------------------
sub cannot_mail_msg {
# ------------------
    my $errcode=shift;
    if ( $lng eq 'ger') {
         print '<h2>&Uuml;bermittlung misslungen</h2><p>Die Bestellung ist zur Zeit nicht möglich.',
        'Bitte versuchen Sie es zu einem sp&auml;teren Zeitpunkt.</p>';
    } elsif ($lng eq 'eng') {
         print '<h2>&Uuml;bermittlung misslungen</h2><p>Die Bestellung ist zur Zeit nicht möglich.',
        'Bitte versuchen Sie es zu einem sp&auml;teren Zeitpunkt.</p>';
    }
    if ( $errcode ) {
        print "<pre>ERROR: ", $Mail::Sender::Errors[$errcode], "</pre>";
    }
    else {
        print "<pre>ERROR: cannot retrieve template</pre>";
    }
    print_footer();
    exit;
}
# ------------------
sub ok_button {
# ------------------
    $q->submit(
        -id     => 'okb1',
        -style  => 'width:100px;font-weight:bold',
        -value  => $ButtonContinue{$lng},
    );
}
# ------------------
sub back_button {
# ------------------
    $q->button(
        -id=>'backButton',
        -value  => $ButtonBack{$lng},
        -style  => 'width:100px;font-weight:bold',
        -onClick=>'javascript:history.back();'
    );
}
# ------------------
sub init_data {
# ------------------
    # Bequeme art, diverse globale Variablen zu initialisieren.
    # Die Reihenfolge der einzelnen Felder steuert die Reihenfolge der Anzeige.
    my %buch = (
       'ger' => [
           sig       => 'Signatur',
           title     => 'Titel',
           libname   => 'Institution',
           visit     => 'Konsultationsdatum',
           bem       => 'Bemerkung',
       ],
       'eng' => [
           sig       => 'Call no.',
           title     => 'Title',
           libname   => 'Institution',
           visit     => 'Consultation date',
           bem       => 'Note',
       ]
    );
    my %user = (
        'ger' => [
            name     => 'Name',
            address  => 'Adresse',
            phone    => 'Telefon',
            email    => 'E-Mail',
        ],
        'eng' => [
            name     => 'Name',
            address  => 'Adresse',
            phone    => 'Telefon',
            email    => 'E-Mail',
        ]
    );
    while ( @{$buch{$lng}} ) {
        my $field = shift @{$buch{$lng}};
        $Buch{$field} = shift @{$buch{$lng}};
        push(@Buch,$field);
    };
    while ( @{$user{$lng}} ) {
        my $field = shift @{$user{$lng}};
        $User{$field} = shift @{$user{$lng}};
        push(@User,$field);
    }
}
