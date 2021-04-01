#!/usr/bin/perl -T

=for doku

Bestellformular für SWA-Dossierbestellungen
- http://www.ub.unibas.ch/cgi-bin/cms/cms_dossierbestellung.pl
eingebunden in:
-Noch zu definieren 

Programmlogik
- verifiziert Benutzereingabe und authentifiziert Benuzter im Bibliothekssystem
- schickt Bestellung als Email mit HTML-Attachment an die ILL-Stellen (UTF-8)
- schickt eine Bestätigung an den Absender (sofern Email vorhanden)

Autor:  basil.marti@unibas.ch
basiert auf cms_fernleihebestellung.pl von Andres von Arx

history:
  24.02.2015: v.1
  
=cut

use strict;
use Encode;
use POSIX qw(strftime);
use Net::Domain();
use Mail::Sender; $Mail::Sender::NO_X_MAILER = 1;

use ava::aleph::borrower;
use lib qw( /export/www/cgi-bin/cms );
use lib qw( /home/vonarx/www/cgi-bin/cms );
use CgiCms;
use Data::Dumper;

# CGI security
umask 077;
$ENV{PATH}='/bin:/usr/bin';
delete ENV{qw(IFS CDPATH ENV BASH_ENV)};
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

my $TestEmail       = '';
my $EmailSMTP       = 'smtp.unibas.ch';
my $CounterURL      = "http://intranet.ub.unibas.ch/php/admin/counter.php?next=";
my %Bestellformular  = (
   'SA' => 'cms_dossierbestellung_formular_sach.html',
   'FV' => 'cms_dossierbestellung_formular_firm.html',
   'PV' => 'cms_dossierbestellung_formular.html'
);
my $BestellformularBlank = 'cms_dossierbestellung_formular_blank.html';
my $MailTemplate    = 'cms_dossierbestellung_mail_template.html';
my $HeaderTemplate  = 'cms_dossierbestellung_header_template.html';

my $LibraryName     = 'UB Wirtschaft - SWA, Basel';
my $LibraryNameHeader     = 'UB Wirtschaft - SWA, Basel';
my $LibraryInfoLink = 'http://www.ub.unibas.ch/ub-wirtschaft-swa/';
my $LibraryNotes    = 'Bestellungen werden in der Regel zwischen 9 und 16 Uhr innerhalb einer halben Stunde bereitgestellt.';
my $PaperEmail      = '';
my $Signature       = 'UNIVERSITÄT BASEL
   UB Wirtschaft - SWA
   Information und Fernleihe
   info-ubw-swa@unibas.ch'; 
my $CounterURL      = $CounterURL . 'BES_DOS_A125';
# -----------------------
# CGI handling
# -----------------------
my $q = CgiCms->new;
my(%Buch, @Buch, %User, @User, %Selection, @Selection, $Config);

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
        if ( $q->param('uid') && $q->param('d')) {
           print_confirm_uid();
        }
        else {
           print_confirm();
        }
	print qq|</div>|
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
    my $sig = $q->param('sig'); 
    my $title = $q->param('title') =~ s/Dokumentensammlung\..*/Dokumentensammlung]/sr;
    my $form = $q->param('form');

    if ($sig && $title && $form) {

        print $q->header(-type=>'text/html; charset=UTF-8');
        #open(F,"<$Bestellformular{$q->param('form')}") or die "cannot read $Bestellformular{$q->param('form')}: $!";
        open(F,"<$Bestellformular{$form}") or die "cannot read $Bestellformular{$form}: $!";
        local $/;
        $_ = <F>;

        s|%%MYSIG%%|$sig|g;
        s|%%MYTITLE%%|$title|g;
        s|%%MYURL%%|$url|g;

        s|%%MYLIBNAME%%|$LibraryName|g;
        s|%%MYLIBNOTES%%|$LibraryNotes|g;
        s|%%MYLIBLINK%%|$LibraryInfoLink|g;
        print $_;

    } elsif (!$sig && !$title && !$form) {
        
        print $q->header(-type=>'text/html; charset=UTF-8');
        open(F,"<$BestellformularBlank") or die "cannot read $BestellformularBlank: $!";
        local $/;
        $_ = <F>;

        s|%%MYURL%%|$url|g;
        s|%%MYLIBNAME%%|$LibraryName|g;
        s|%%MYLIBNOTES%%|$LibraryNotes|g;
        s|%%MYLIBLINK%%|$LibraryInfoLink|g;
        print $_;
    }
}

# ------------------
sub print_confirm {
# ------------------
    # - Zeige die Benutzereingabe
    # - keine Authentifizierung des Benutzers in Aleph
    # - Verlange Bestätigung der Bestellung
    #
    $q->delete('action');
    print $q->h1('Bitte bestätigen Sie Ihre Eingabe:'),
        qq|<div style='padding-left:20px'>|,
        $q->br,
        $q->start_form(-method=>'POST',-name=>'BES',-action=>$q->url()),
        back_button(),
        ok_button();
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>Ihre Bestellung:</b></td></tr>|;
    foreach my $field ( @Buch ) {
        print $table->td( $Buch{$field}, $q->param($field) || ' ' );
    }
    if ($q->param('newspaper') || $q->param('brochure') || $q->param('report') || $q->param('misc_content')) {
	print $table->td('Teile der Dokumentensammlung',' ' );
    	foreach my $field ( @Selection ) {
		if ($q->param($field)) {
        		print $table->td(' ', $q->param($field)) ;
         	}
	}
    }

    print $table->footer;

    # --- print borrower data
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>Ihre persönlichen Daten</b></td></tr>|;
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

    foreach my $field ( @Selection ) {
        print $q->hidden( $field, $q->param($field) );
    }

    print $q->hidden('action','confirm');
    
    print $q->br,
        back_button(),
        ok_button(),
        $q->end_form;
}

# ------------------
sub print_confirm_uid {
# ------------------
    # - Zeige die Benutzereingabe
    # - Authentifiziere den Benutzer in Aleph
    # - Verlange Bestätigung der Bestellung
    #
    print $q->h1('Bitte bestätigen Sie Ihre Eingabe:'),
        qq|<div style='padding-left:20px'>|,
        $q->br,
        $q->start_form(-method=>'POST',-name=>'BES',-action=>$q->url()),
        back_button(),
        ok_button();
    my $table = CgiCms_Table->new(typ=>'grau');
    print $table->header(colgroup => [200,'*']),
        qq|<tr><td colspan="2"><b>Ihre Bestellung:</b></td></tr>|;
    foreach my $field ( @Buch ) {
        print $table->td( $Buch{$field}, $q->param($field) || ' ' );
    }
    if ($q->param('newspaper') || $q->param('brochure') || $q->param('report') || $q->param('misc_content')) {
	print $table->td('Teile der Dokumentensammlung',' ' );
    	foreach my $field ( @Selection ) {
		if ($q->param($field)) {
        		print $table->td(' ', $q->param($field)) ;
         	}
	}
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
            qq|<tr><td colspan="2"><b>Ihre persönlichen Daten</b></td></tr>|,
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
    foreach my $field ( @Selection ) {
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
    my $nc = LWP::Simple::get($CounterURL);
    unless ( $nc =~ s/^ok\|// ) {
        $nc = '?';
    }

    my $AUFTRAGSNUMMER;
    if ( $q->param('uid') ) {
        $AUFTRAGSNUMMER = strftime("%Y.%m.%d-",localtime) .$q->param('uid') .'-' .$nc;
    } else {
        $AUFTRAGSNUMMER = strftime("%Y.%m.%d-",localtime) .$q->param('name') .'-' .$nc;
    }

    $Config->{AUFTRAGSNUMMER} = $AUFTRAGSNUMMER;
    
    my $to      = $PaperEmail;
    my $from    = 'Lesesaalbestellung Dokumentensammlung <' .$PaperEmail .'>';
    my $subject = 'Lesesaalbestellung Dokumentensammlung ' . $AUFTRAGSNUMMER;
    my $fname   = 'dossier-' .$AUFTRAGSNUMMER .'.html';
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
Template: $MailTemplate
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
        $_ = $q->param($key);
        $stv{$key} = $_ || '';
    }
    foreach my $key ( @Selection ) {
        $_ = $q->param($key);
        $stv{$key} = $_ || '';
    }
    $stv{uid} = $q->param('uid');
    # hole das Template und ersetze die Stellvertreter mit Inhalten
    open(F,"<$MailTemplate") or die "cannot read $MailTemplate: $!";
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
    s/\*\*//g;
    $_;
}
# ------------------
sub mail_receipt {
# ------------------
    # Schicke eine Bestägigungsmail an den Benutzer.
    # Bei zweifelhafter Emailadresse: zeige die Bestätigung als Text.
    #
    {
       print $q->header(-type=>'text/html; charset=UTF-8');
       open(F,"<$HeaderTemplate") or die "cannot read $HeaderTemplate: $!";
       local $/;
       $_ = <F>;
       print $_;
    }
    print $q->h1('Ihre Bestellung wurde übermittelt');
    print qq|<div style='padding-left:20px'>|;
    my $mailmsg = format_receipt();
    my $mail_to = $q->param('email');
    if ( $mail_to && $mail_to !~ /\s/ && $mail_to =~ /\w\@\w/ ) {
        my $to = $q->param('email');
        my $from    = 'UB Wirtschaft <' .$PaperEmail .'>';
        my $subject = 'UB Wirtschaft: Bestellung Dokumentensammlung';
        my $localhost = Net::Domain::hostfqdn();
        if ( $DoMail ) {
            Encode::from_to($mailmsg,'utf-8','iso-8859-1');
            my $Mailer = Mail::Sender->new({
                from =>     $from,
                to =>       $to,
                subject =>  $subject,
                smtp =>     'smtp.unibas.ch',
                client =>   $localhost,
                charset =>  'ISO-8859-1',
                encoding => '8BIT',
            });
            if ( ref($Mailer) &&  ref( $Mailer->MailMsg({ msg => $mailmsg })) ) {
                print $q->p('Sie erhalten eine Bestätigung per E-Mail.');
            }
        } else {
            $mailmsg = <<EOD;
From:    $from
To:      $to
Subject: $subject

$mailmsg
EOD
            print '<pre>', CGI::escapeHTML($mailmsg), '</pre><hr/>';
        }
    } else {
        print '<pre>', CGI::escapeHTML($mailmsg), '</pre><hr/>';
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
    my $SIGNATURE = $Signature;
    my $LIBRARYNAME = ${LibraryName};
    my $DATUM = strftime("%d.%m.%Y %H:%M:%S",localtime);
    my $txt = <<EOD;
Besten Dank für Ihre Bestellung in der $LIBRARYNAME.
Wir werden die gewünschte Dokumentensammlung für Sie bereitstellen.

Auftragsnummer: $AUFTRAGSNUMMER
Datum: $DATUM

EOD
    foreach my $field ( @Buch ) {
        if ( $q->param($field) ) {
            $txt .= $Buch{$field} .': ' .$q->param($field) ."\n";
        }
    }
    if ($q->param('newspaper') || $q->param('brochure') || $q->param('report') || $q->param('misc_content')) {
	$txt .= 'Bestellte Teile der Dokumentensammlung: ';
	foreach my $field ( @Selection ) {
		if ($q->param($field)) {
			$txt .= $q->param($field) . ', '
		}
	}
	$txt .= "\n";
    }
    
    $txt .= <<EOD;

Wir danken für Ihren Auftrag.

$SIGNATURE
EOD
    $txt;
}
# ------------------
sub print_retype_pwd {
# ------------------
    # nach Fehler (falsche uid/pwd oder Kommunikationsstoeung)
    # erneuter Versuch zur Eingabe von uid/pwd
    my $err = shift;
    my $uid = $q->param('uid');
    $q->delete('uid');
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
# ------------------
sub cannot_mail_msg {
# ------------------
    my $errcode=shift;
    print '<h2>&Uuml;bermittlung misslungen</h2><p>Die Bestellung ist zur Zeit nicht möglich.',
        'Bitte versuchen Sie es zu einem sp&auml;teren Zeitpunkt.</p>';
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
        -value  => 'weiter >>',
    );
}
# ------------------
sub back_button {
# ------------------
    $q->button(
        -id=>'backButton',
        -value  => '<< zurück',
        -style  => 'width:100px;font-weight:bold',
        -onClick=>'javascript:history.back();');
}
# ------------------
sub init_data {
# ------------------
    # Bequeme art, diverse globale Variablen zu initialisieren.
    # Die Reihenfolge der einzelnen Felder steuert die Reihenfolge der Anzeige.
    my @buch = (
        sig       => 'Signatur',
        title     => 'Titel',
        time      => 'Zeitraum',
        visit     => 'Konsultationsdatum',
        bem       => 'Bemerkung',
    );
    my @user = (
        name     => 'Name',
        address  => 'Adresse',
        phone    => 'Telefon',
        email    => 'E-Mail',
    );
    my @selection = (
        newspaper     => 'Zeitungsauschnitte',
        brochure      => 'Broschüren',
        report        => 'Jahresberichte',
        misc_content  => 'Anderes',
    );
    while ( @buch ) {
        my $field = shift @buch;
        $Buch{$field} = shift @buch;
        push(@Buch,$field);
    }
    while ( @user ) {
        my $field = shift @user;
        $User{$field} = shift @user;
        push(@User,$field);
    }
    while ( @selection ) {
        my $field = shift @selection;
        $Selection{$field} = shift @selection;
        push(@Selection,$field);
    }
}
