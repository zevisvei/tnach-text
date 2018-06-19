for file in htm/*; do echo $file; echo enco_$file; iconv -f WINDOWS-1255 -t UTF-8//IGNORE $file -o enco_$file; done
