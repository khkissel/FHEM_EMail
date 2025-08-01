# $Id: 98_EMail.pm 15331 2025-08-01 13:48:20Z khkissel $

#################################################################
#
#  Copyright notice
#
#  (c) 2025 Karlheinz Kissel (kh.kissel@t-online.de)
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
#################################################################
# $Id: 98_EMail.pm 15331 2025-08-01 13:48:20Z khkissel $

package main;

use strict;
use warnings;
use Net::SMTP;       # Used for STARTTLS ( e.g port 587)
use Net::SMTP::SSL;  # Used for SSL/TLS (e.g. port 465)
use FHEM::Meta;

# Versionsnummer des Moduls
# Version 0.9.0 – gespeichert am 01.08.2025 15:48:10

$FHEM::EMail::VERSION = "0.9.0";


my %email_sets = (
   send    => "send"
);


sub EMail_Initialize {
	my ($hash) = @_;
	$hash->{DefFn}    = 'EMail_Define';
	$hash->{SetFn}    = 'EMail_Set';
	$hash->{AttrList} = 'SMTPServer SMTPPort SMTPProtocol:TLS,SSL';
}

sub EMail_Define {
	my ($hash, $def) = @_;
	my @args = split("[ \t]+", $def);
	return "Usage: define <name> EMail <username> <password>" if (int(@args) != 4);

	return $@ unless ( FHEM::Meta::SetInternals($hash) );

	my ($name, $type, $username, $pass) = @args;

	$hash->{USERNAME} = $username;

	# Encrypt password
	my $password = EMail_encrypt($pass);
	Log3 $name, 3, "$name: encrypt $pass to $password" if($pass ne $password);

	$hash->{DEF} = "$username $password";

	$hash->{helper}{username} = $username;
	$hash->{helper}{password} = $password;

	return undef;
}


sub EMail_Set($@) {
	my ($hash, @args) = @_;
	my $name = $hash->{NAME};

	# Return without any further action if the module is disabled
	return undef if ( IsDisabled($name) );

	$hash->{Modulversion} = $FHEM::EMail::VERSION;

	shift @args;  # Remove device

	my $cmd = shift @args;

	if(!$email_sets{$cmd}) {
		my @cList = values %email_sets;
		return "Unknown argument $cmd, choose one of " . join(" ", @cList);
    }

	my @parsed_args = parse_quoted_args(@args);

	my $sender = $hash->{USERNAME};
	(my $recipient, my $subject, my $msg) = @parsed_args;

	Log3 $hash->{NAME}, 5, "$hash->{NAME}: Sender: $sender - Recipient: $recipient - Subject: $subject - Message: $msg - args: " . Dumper(@parsed_args);

	return "Error: Too many arguments." if (scalar(@parsed_args) > 3);

	return "Error: Recipient, Subject or Message missing." unless $recipient && $subject && $msg;

	my $smtp_server = AttrVal($hash->{NAME}, "SMTPServer", "");
	my $smtp_port = AttrVal($hash->{NAME}, "SMTPPort", "");
	my $smtp_protocol = AttrVal($hash->{NAME}, "SMTPProtocol", "");

	my $username       = $hash->{USERNAME};
	my $password    = EMail_decrypt($hash->{helper}{password});

	unless ($smtp_server) {
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: SMTPServer not defined.";
		return "Error: SMTPServer not defined.";
	}

	unless ($smtp_port) {
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: SMTPPort not defined.";
		return "Error: SMTPPort not defined.";
	}

	unless ($smtp_protocol) {
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: SMTPProtocol not defined";
		return "Error: SMTPProtocol not defined.";
	}

	unless ($username) {
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: Username is missing.";
		return "Error: Username is missing.";
	}

	unless ($password) {
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: Password is missing.";
		return "Error: Password is missing.";
	}

	Log3 $hash->{NAME}, 5, "$hash->{NAME}: SMTP-Aufruf mit folgender Eingabe: Sender: $sender - Recipient: $recipient - subject: $subject - Message: $msg";

	my $smtp_client; # Declare the SMTP client object

	eval {
		if ($smtp_protocol eq "TLS") {
			# For STARTTLS, use Net::SMTP and then call starttls()
			$smtp_client = Net::SMTP->new(
				$smtp_server,
				Port    => $smtp_port,
				Timeout => 10,
				# Debug   => 1, # Uncomment for detailed debugging output
			) or die "Failed to create Net::SMTP object: $!";

			# Initiate STARTTLS handshake
			$smtp_client->starttls()
				or die "STARTTLS handshake failed: " . $smtp_client->code() . " " . $smtp_client->message();

		} elsif ($smtp_protocol eq "SSL") {
			# For implicit SSL/TLS, use Net::SMTP::SSL directly
			$smtp_client = Net::SMTP::SSL->new(
				$smtp_server,
				Port    => $smtp_port,
				Timeout => 10,
				# Debug   => 1, # Uncomment for detailed debugging output
			) or die "Failed to create Net::SMTP::SSL object: $!";

		} else {
			die "Unsupported SMTP protocol: $smtp_protocol. Only TLS or SSL are supported.";
		}

		# Authenticate with the SMTP server
		$smtp_client->auth($username, $password)
			or die "Authentication failed: " . $smtp_client->code() . " " . $smtp_client->message();

		# Set sender and recipient
		$smtp_client->mail($sender)
			or die "Failed to set sender ($sender): " . $smtp_client->code() . " " . $smtp_client->message();
		$smtp_client->to($recipient)
			or die "Failed to set recipient ($recipient): " . $smtp_client->code() . " " . $smtp_client->message();

		# Send the email data
		$smtp_client->data();
		$smtp_client->datasend("From: $sender\n");
		$smtp_client->datasend("To: $recipient\n");
		$smtp_client->datasend("Subject: $subject\n");
		$smtp_client->datasend("\n$msg\n"); # Separate headers from body with a blank line
		$smtp_client->dataend()
			or die "Failed to send email data: " . $smtp_client->code() . " " . $smtp_client->message();

		$smtp_client->quit; # Close the connection gracefully

	}; # End eval block

	# --- Error Handling ---
	if ($@) {
		my @error = split(/ at /, $@, 2);
		Log3 $hash->{NAME}, 3, "$hash->{NAME}: $error[0]";
		return $error[0];
	} else {
		return "EMail sent successfully to $recipient.";
	}
}

sub EMail_encrypt($) {
  my ($decoded) = @_;
  my $key = getUniqueId();
  my $encoded;

  return $decoded if( $decoded =~ /crypt:/ );

  for my $char (split //, $decoded) {
    my $encode = chop($key);
    $encoded .= sprintf("%.2x",ord($char)^ord($encode));
    $key = $encode.$key;
  }
  return "crypt:" if(!$encoded);
  return 'crypt:'.$encoded;
}

sub EMail_decrypt($) {
  my ($encoded) = @_;
  my $key = getUniqueId();
  my $decoded;

  return $encoded if( $encoded !~ /crypt:/ );
  return "" if($encoded eq "crypt:");

  $encoded = $1 if( $encoded =~ /crypt:(.*)/ );

  for my $char (map { pack('C', hex($_)) } ($encoded =~ /(..)/g)) {
    my $decode = chop($key);
    $decoded .= chr(ord($char)^ord($decode));
    $key = $decode.$key;
  }

  return $decoded;
}


sub parse_quoted_args {
    my @args = @_;
    my @parsed;
    my $collecting = 0;
    my $buffer = '';
    my $quote = '';

    foreach my $arg (@args) {
        if (!$collecting) {
            # Check if the argument starts with a quote
            if ($arg =~ /^(['"])(.*)$/) {
                $quote = $1;
                my $content = $2;

                # Check if the quoted string ends immediately (e.g., "Subject")
                if ($content =~ s/(.*)$quote$//) {
                    # This handles cases like "Subject" or 'SingleWord'
                    # The $1 captures the content *before* the closing quote was removed by s///
                    push @parsed, $1; # Add content without quotes
                    $collecting = 0;
                    $buffer = '';
                    $quote = '';
                } else {
                    # It's the start of a multi-word quoted phrase (e.g., "Test)
                    $collecting = 1;
                    $buffer = $content; # Start buffer with content (without opening quote)
                }
            } else {
                # If not collecting and not starting a quote, just add the argument as is (e.g., "Word")
                push @parsed, $arg;
            }
        }
        # If currently collecting a quoted phrase
        elsif ($collecting) {
            # Check if the current argument ends with the expected quote (e.g., "Subject")
            if ($arg =~ /(.*)$quote$/) {
                $buffer .= ' ' . $1; # Append content and remove closing quote
                push @parsed, $buffer;
                $buffer = '';
                $collecting = 0;
                $quote = ''; # Reset quote type
            } else {
                # Continue collecting words within the quoted phrase (e.g., "Teil")
                $buffer .= ' ' . $arg;
            }
        }
    }

    # If we finished processing arguments but were still collecting (unclosed quote)
    push @parsed, $buffer if $collecting && $buffer ne '';

    return @parsed;
}

1;



=pod
=encoding utf8
=item device
=item summary Sending emails via SMTP
=item summary_DE Versenden von EMails via SMTP

=begin html

<a id="EMail">
<h3>EMail</h3>
<p style="color: black;">The FHEM EMail module enables the sending of emails  via the Simple Mail Transfer Protocol (SMTP). It supports both Transport Layer Security (TLS) and Secure Sockets Layer (SSL) encryption for secure communication with the mail server.</p>
<ul>
	<a id="EMail-define">
	<h4>Define</h4>
	<ul style="color: black;">
		<pre><code>define myEMailDevice EMail sender@example.com password</code></pre>
		The <b>define</b> command is used to create an instance of the EMail module. <b>myEMailDevice</b> should be replaced with a chosen name for the device,
		<b>sender@example.com</b> with the sender's email address, and <b>password</b> with the corresponding password for the SMTP server. After the definition is done,
		the password will be stored encrypted.
		<br>
	</ul>
	<br>
	<a id="EMail-set">
	<h4>Set</h4>
	<ul style="color: black;">
		<pre><code>set myEMailDevice EMail &lt;Recipient&gt; "&lt;Subject&gt;" "&lt;Message&gt;"</code></pre>
		The <b>set</b> command is used to send emails via the defined device. The command requires the recipient, subject, and message. It is important to note that
		the <b>subject</b> and <b>message</b> must be enclosed in quotation marks if they contain spaces or special characters.<br>
		<br>
		Example:
		<pre><code>set myEMailDevice EMail recipient@example.com "FHEM Status Report" "All systems are running smoothly."</code></pre>
		<br><br>
	</ul>
	<a id="EMail-attr">
	<h4>Attributes</h4>
	<p style="color: black;">The functionality of the EMail module can be customized through attributes that allow the detailed configuration of how the connection to the SMTP server is established:</p>
	<ul style="color: black;">
		<li><a id="EMail-attr-SMTPServer"></a>
			<b><code>SMTPServer</code></b>
			<br>
			specifies the hostname or IP address of the SMTP server to be used for email transmission.<br>
		</li>
		<li><a id="EMail-attr-SMTPPort"></a>
			<b><code>SMTPPort</code></b>
			<br>
			sets the port through which the connection to the SMTP server is established. Common ports include <b>587</b> for TLS (STARTTLS) and <b>465</b> for SSL.<br>
		</li>
		<li><a id="EMail-attr-SMTPProtocol"></a>
			<b><code>SMTPProtocol</code></b>
			<br>
			determines the protocol used for encryption. Valid values are <b>TLS</b> or <b>SSL</b>. <b>TLS</b> is often recommended for newer SMTP servers, while <b>SSL</b> is utilized for older implementations.<br>
		</li>
	</ul>
</ul>

=end html

=begin html_DE

<a id="EMail">
<h3>EMail</h3>
<p style="color: black;">Das FHEM EMail-Modul erm&ouml;glicht das Senden von E-Mails &uuml;ber das Simple Mail Transfer Protocol (SMTP). Es unterst&uuml;tzt sowohl Transport Layer Security (TLS) als auch Secure Sockets Layer (SSL)-Verschl&uuml;sselung f&uuml;r eine sichere Kommunikation mit dem Mailserver.</p>
<ul>
	<a id="EMail-define">
	<h4>Define</h4>
	<ul style="color: black;">
		<pre><code>define myEMailDevice EMail absender@example.com password</code></pre>
		Der <b>define</b>-Befehl wird verwendet, um eine Instanz des EMail-Moduls zu erstellen. <b>myEMailDevice</b> sollte durch einen gew&auml;hlten Namen f&uuml;r das Ger&auml;t,
		<b>absender@example.com</b> durch die E-Mail-Adresse des Absenders und <b>password</b> durch das entsprechende Passwort f&uuml;r den SMTP-Server ersetzt werden. Nach der Definition wird das Passwort verschl&uuml;sselt gespeichert.
		<br>
	</ul>
	<br>
	<a id="EMail-set">
	<h4>Set</h4>
	<ul style="color: black;">
		<pre><code>set myEMailDevice EMail &lt;Empf&auml;nger&gt; "&lt;Betreff&gt;" "&lt;Nachricht&gt;"</code></pre>
		Der <b>set</b>-Befehl wird verwendet, um E-Mails &uuml;ber das definierte Ger&auml;t zu senden. Der Befehl erfordert den Empf&auml;nger, den Betreff und die Nachricht. Es ist wichtig zu beachten, dass der <b>Betreff</b> und die <b>Nachricht</b> in Anf&uuml;hrungszeichen eingeschlossen werden m&uuml;ssen, wenn sie Leerzeichen oder Sonderzeichen enthalten.
		<br><br>
		Beispiel:
		<pre><code>set myEMailDevice EMail empf&auml;nger@example.com "FHEM Statusbericht" "Alle Systeme laufen reibungslos."</code></pre>
		<br>
	</ul>
	<a id="EMail-attr">
	<h4>Attribute</h4>
	<p style="color: black;">Die Funktionalit&auml;t des EMail-Moduls kann durch einige Attribute angepasst werden, die eine detaillierte Konfiguration der Verbindung zum SMTP-Server erm&ouml;glichen:</p>
	<ul style="color: black;">
		<li><a id="EMail-attr-SMTPServer"></a>
			<b><code>SMTPServer</code></b>
			<br>
			gibt den Hostnamen oder die IP-Adresse des SMTP-Servers an, der f&uuml;r den E-Mail-Versand verwendet werden soll.
		</li>
		<li><a id="EMail-attr-SMTPPort"></a>
			<b><code>SMTPPort</code></b>
			<br>
			legt den Port fest, &uuml;ber den die Verbindung zum SMTP-Server hergestellt wird. G&auml;ngige Ports sind <b>587</b> f&uuml;r TLS (STARTTLS) und <b>465</b> f&uuml;r SSL.
		</li>
		<li><a id="EMail-attr-SMTPProtocol"></a>
			<b><code>SMTPProtocol</code></b>
			<br>
			bestimmt das f&uuml;r die Verschl&uuml;sselung verwendete Protokoll. G&uuml;ltige Werte sind <b>TLS</b> oder <b>SSL</b>. <b>TLS</b> wird oft f&uuml;r neuere SMTP-Server empfohlen, w&auml;hrend <b>SSL</b> f&uuml;r &auml;ltere Implementierungen verwendet wird.
			<br>
		</li>
	</ul>
</ul>

=end html_DE

=for :application/json;q=META.json 98_EMail.pm
{
  "abstract": "Sending of emails  via the Simple Mail Transfer Protocol (SMTP)",
  "x_lang": {
    "de": {
      "abstract": "Senden von E-Mails &uuml;ber das Simple Mail Transfer Protocol (SMTP)"
    }
  },
  "keywords": [
    "EMail",
    "SMP"
  ],
  "version": "v0.9.1",
  "release_status": "stable",
  "author": [
    "Kh. Kissel <kh.kissel@t-online.de>",
    null
  ],
  "x_fhem_maintainer": [
    "khk123"
  ],
  "x_fhem_maintainer_github": [
    "khkissel"
  ],
  "prereqs": {
    "runtime": {
      "requires": {
        "FHEM": 5.00918799,
        "perl": 5.014,
        "FHEM::Meta": 0,
		"Net::SMTP": 0,
		"Net::SMTP::SSL": 0
      },
      "recommends": {
      },
      "suggests": {
      }
    }
  }
}

=end :application/json;q=META.json

=cut
