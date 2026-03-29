#!/bin/bash
# Referencing https://docs.kicad.org/9.0/en/cli/cli.html
CURR_PATH=$(dirname "$0")

KICAD_PROJECT=$(find . -name *kicad_pro)
PROJECT_PATH=${KICAD_PROJECT[0]%.kicad_pro}
SCH_PATH="${PROJECT_PATH}.kicad_sch"
PCB_PATH="${PROJECT_PATH}.kicad_pcb"

EXPORT_PATH="$(realpath -m "${PROJECT_PATH}/../outputs")"

rm -rf $EXPORT_PATH

# TODO: would be nice to make it do more than 1 project
# PDFs are good for a single file for reading, SVGs better for larger documentation

# Documentation essentials: schematic & pcb PDFs
kicad-cli sch export pdf $SCH_PATH -o "${EXPORT_PATH}/schematics.pdf"

EXPORT_LAYERS="B.Cu,F.Cu,B.SilkS,F.SilkS,Edge.Cuts,B.Fab,F.Fab,User.Drawings"
kicad-cli pcb export pdf $PCB_PATH -o "${EXPORT_PATH}/layout.pdf" -l $EXPORT_LAYERS

# SVGs: schematic & pcb svgs
SVG_PATH="${EXPORT_PATH}/svgs"
kicad-cli sch export svg $SCH_PATH -o "$SVG_PATH"
kicad-cli pcb export svg $PCB_PATH -o "${SVG_PATH}/pcb.svg" --mode-single -l $EXPORT_LAYERS # Can split to mutliple pages using --mode-multi

# Production: BOM, gerbers, drill files
kicad-cli sch export bom $SCH_PATH -o "${EXPORT_PATH}/bom.csv" --group-by "Part Number,Reference,Value,Footprint,\${DNP}" \
--ref-range-delimiter --fields "Reference,Value,Part Number,Footprint,\${DNP}"
kicad-cli pcb export gerbers $PCB_PATH -o "${EXPORT_PATH}/gerbers" --board-plot-params
kicad-cli pcb export drill $PCB_PATH -o "${EXPORT_PATH}/gerbers" --excellon-separate-th

# Testpoint locations
kicad-cli sch export netlist $SCH_PATH -o ${EXPORT_PATH}/temp_netlist.kicadsexpr #temp file
EXTRACTED_TEST_POINTS=$(grep -P 'node \(ref "(TP|JP)\d' -A 1 ${EXPORT_PATH}/temp_netlist.kicadsexpr)
TEST_POINTS=$(echo "$EXTRACTED_TEST_POINTS" | grep -oP 'node[^"]+"\K[^"]+|name[^"]"\K[^"]+')

mapfile -t lines <<< "$TEST_POINTS"
echo "Reference,Net" >> "${EXPORT_PATH}/test_points.csv"
for ((i=0; i<${#lines[@]}; i+=2)); do
    echo "${lines[i]},${lines[i+1]}" >> "${EXPORT_PATH}/test_points.csv"
done
rm ${EXPORT_PATH}/temp_netlist.kicadsexpr

# Positions for PnP production
kicad-cli pcb export pos $PCB_PATH --format csv --units mm --side front -o "${EXPORT_PATH}/positions/top-pos.csv"
kicad-cli pcb export pos $PCB_PATH --format csv --units mm --side back -o "${EXPORT_PATH}/positions/bottom-pos.csv"
POSITION_CSV_COLUMNS="Designator,Value,Footprint,Mid X,Mid Y, Rotation,Layer"
sed -i "1s/.*/$POSITION_CSV_COLUMNS/" "${EXPORT_PATH}/positions/top-pos.csv"
sed -i "1s/.*/$POSITION_CSV_COLUMNS/" "${EXPORT_PATH}/positions/bottom-pos.csv"

# Mounting: PCB cutout, 3D model
kicad-cli pcb export dxf $PCB_PATH -o $EXPORT_PATH --layers "Edge.Cuts" --out mm --drill-shape-opt 2
mv "${EXPORT_PATH}"/*.dxf "${EXPORT_PATH}/cutout.dxf"

kicad-cli pcb export step --include-tracks --include-pads --include-zones \
 --include-inner-copper --include-silkscreen --include-soldermask --grid-origin --no-dnp $PCB_PATH \
 -o "${EXPORT_PATH}/3d_model.step"