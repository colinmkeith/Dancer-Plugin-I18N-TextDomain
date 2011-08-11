
package t::lib::createCatalog;

use File::Basename;
use File::Path;

use vars qw(@ISA @EXPORTER);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(createCatalog);


sub createCatalog {
  my($catalogFile, $msgfmtCmd) = @_;
  my $poFile = substr($catalogFile, 0, -3) . '.po';

  my $dirname  = dirname($catalogFile);
  -d $dirname || File::Path::make_path($dirname, { verbose=>0, mode=>0700 });

  open(my $PO, '>', $poFile) || return "Error creating .po ($poFile): $!";

  print $PO <<'EOF';
msgid "hello world"
msgstr "__('hello world') OK"

msgid "hello {name}"
msgstr "__x('hello {name }') returns 'hello {name}' OK"

msgid "hello world singular"
msgid_plural "hello worlds plural"
msgstr[0] "__n('hello world singular') OK"
msgstr[1] "__n('hello worlds plural') OK"

msgid "hello {name} singular"
msgid_plural "hello {name} plural"
msgstr[0] "__n('hello {name } singular') == hello world OK"
msgstr[1] "__n('hello {name } plural') == hello worlds OK"

EOF

  close($PO);


  if($msgfmtCmd) {
    system("$msgfmtCmd $poFile -o $catalogFile");
  } else {
    require Locale::Msgfmt;
    Local::Msgfmt::msgfmt({in => $poFile, out => $catalogFile});
  }

  -s $catalogFile || return "Error creating .mo ($catalogFile): $!";

  return 0;
}

1;

# vim: set foldmethod=marker filetype=perl:
