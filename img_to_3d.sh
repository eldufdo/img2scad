# Author: David Thaller
# License: WTFPL
#!/bin/sh

echo "Image to 3d converter"
which librecad &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "Error: Librecad must be installed - e.g. apt-get install librecad"
    exit 1
fi
which potrace &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "Error: potrace must be installed - e.g. apt-get install potrace"
    exit 1
fi
which openscad &> /dev/null
if [ "$?" -ne 0 ]; then
    echo "Error: Openscad must be installed - e.g. apt-get install openscad"
    exit 1
fi
if [ "$#" -ne 1 ]; then
    echo "Error: There must be exactly one parameter - the image filename"
    exit 1
fi

FILE=$1
if [ ! -f $FILE ]; then
	echo "Error: File not found"
	exit 1
fi

echo "Converting the image to pbm format ..." 
FILENAME=`echo $FILE | cut -d'.' -f1`
convert $FILE $FILENAME.pbm
if [ ! -f $FILENAME.pbm ]; then
    echo "Error: could not convert image to *.pbm format"
    exit 1
fi
echo "Done"
echo "Tracing pbm image and generate dxf ..."
cat $FILENAME.pbm | potrace -b dxf > $FILENAME.dxf
if [ ! -f $FILENAME.dxf ]; then
    echo "Error: could not trace image and export to dxf format"
    exit 1
fi
echo "Done"
echo "Starting librecad with generated dxf..."
librecad $FILENAME.dxf &> /dev/null
echo "Done"
echo "\$scale=1;
\$height=5;
\$border=0.5;
\$cookie_outline_mult=4;

\$action = \"fill\";
//\$action = \"border\";
//\$action = \"cookie\";

module extrusion(\$offset=0) {
    linear_extrude(height=\$height) {
        scale(\$scale) {
            offset(\$offset)
                import(\"$FILENAME.dxf\");
        }
    }
}

module border() {
    difference() {
        extrusion(\$border);
        scale([1,1,2]) {
            translate([0,0,-1]) 
                extrusion();
        }
    }
}

module cookie() {
    difference() {
        resize([0,0,1]) {
            extrusion(\$cookie_outline_mult*\$border);
        }
        resize([0,0,1.2]) {
            translate([0,0,-0.1]) {
                extrusion(-\$cookie_outline_mult*\$border);
            }
        }
    }
    border();
}


if (\$action == \"fill\") {
    extrusion();
} else if (\$action == \"border\") {
	border();
} else if (\$action == \"cookie\") {
	cookie();
}

" > $FILENAME.scad
rm *.pbm &> /dev/null
rm *.dxf~ &> /dev/null
openscad $FILENAME.scad

