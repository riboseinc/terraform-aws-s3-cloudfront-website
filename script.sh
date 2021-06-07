# Adapted from https://tinyapps.org/blog/nix/201701240700_convert_asciidoc_to_markdown.html
# Using asciidoctor 1.5.6.1 and pandoc 2.0.0.1
# Install pandoc and asciidoctor

sudo apt install asciidoctor
sudo wget https://github.com/jgm/pandoc/releases/download/2.0.0.1/pandoc-2.0.0.1-1-amd64.deb
sudo dpkg -i pandoc-2.0.0.1-1-amd64.deb

# Convert asciidoc to docbook using asciidoctor

asciidoctor -b docbook README.adoc

# README.xml will be output into the same directory as README.adoc

# Convert docbook to markdown

pandoc -f docbook -t gfm README.xml -o README.md

# Unicode symbols were mangled in README.md. Quick workaround:

iconv -t utf-8 README.xml | pandoc -f docbook -t gfm | iconv -f utf-8 > README.md

# Pandoc inserted hard line breaks at 72 characters. Removed like so:

pandoc -f docbook -t gfm --wrap=none # don't wrap lines at all

pandoc -f docbook -t gfm --columns=120 # extend line breaks to 120
