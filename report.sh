dune exec --instrument-with bisect_ppx fancy_index/main.exe

dune exec ./src/report/main.exe -- html -o _coverage --ignore-missing-files
dune exec ./src/report/main.exe -- html --tree -o _coverage_tree --ignore-missing-files
dune exec ./src/report/main.exe -- html -o _coverage_dark --ignore-missing-files --theme dark
dune exec ./src/report/main.exe -- html --tree -o _coverage_dark_tree --ignore-missing-files --theme dark

echo "See file://$(pwd)/_coverage/index.html"
echo "See file://$(pwd)/_coverage_tree/index.html"
echo "See file://$(pwd)/_coverage_dark/index.html"
echo "See file://$(pwd)/_coverage_dark_tree/index.html"
