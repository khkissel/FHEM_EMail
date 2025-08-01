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