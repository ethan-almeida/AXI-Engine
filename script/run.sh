#!/bin/bash
set -e

PROJECT_NAME="axi-engine"

SCRIPT_DIR="$(realpath "$(dirname "$0")")" 
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"
cd "$PROJECT_ROOT"

TOP_MODULE="tbench_top"
OBJ_DIR="obj_dir"
BINARY="$OBJ_DIR/V$TOP_MODULE"

UVM_HOME="${UVM_HOME:-$HOME/1800.2-2017-1.0/src}"
RTL_DIR="rtl"
TB_DIR="tb"

RTL_SRC=$(find "$RTL_DIR" -name "*.sv" -type f 2>/dev/null || true)
UVM_SRC=$(find "$TB_DIR" -name "*.sv" -type f 2>/dev/null || true)
TOP_SRC="tb_top.sv"

test_name=""
run_count=0
clean_mode=false
zip_mode=false

while getopts "t:r:czh" opt; do
    case $opt in
        t) test_name="$OPTARG" ;;
        r) run_count="$OPTARG" ;;
        c) clean_mode=true ;;
        z) zip_mode=true ;;
        h) 
            echo "Usage: $0 [flags]"
            echo "-t <test_name>: this flag is to run a specific test"
            echo "-c: this flag is to clean the project of all auto-generated files and directories"
            echo "-z: this flag compresses the project into a zip file"
            echo "-h: this flag is a help menu to look at the descriptions of the flags"
            exit 0
            ;;
        *) echo "Invalid syntax. Please use -h for help" && exit 1;;
    esac
done

clean() {
    echo "cleaning project files..."
    rm -rf "$OBJ_DIR"
    rm -f *.vcd *.log
    echo "project has been cleaned"
}

zip_project() {
    echo "zipping project..."
    zip -r $PROJECT_NAME.zip . \
        -x "obj_dir/*" \
        -x "*.zip" \
        -x "*.vcd" \
        -x "*.log" \
        -x ".git/*" 2>/dev/null
    echo "Archive created: $PROJECT_NAME.zip"
}

build() {
    echo "Building simulation..."
    verilator --binary -j 0 \
        -Wall \
        -Wno-EOFNEWLINE \
        -Wno-DECLFILENAME \
        -Wno-IMPORTSTAR \
        -Wno-WIDTHTRUNC \
        --top-module "$TOP_MODULE" \
        +incdir+"$UVM_HOME" \
        +define+UVM_NO_DPI \
        "$UVM_HOME/uvm_pkg.sv" \
        $UVM_SRC \
        $RTL_SRC \
        "$TOP_SRC"
    echo "Build complete."
}

run_test() {
    local tname="$1"
    echo "running test: $tname"
    "$BINARY" +UVM_TESTNAME="$tname"
}

run_multiple() {
    local count="$1"
    echo "Running $count iteration(s)..."
    for ((i=1; i<=count; i++)); do
        echo "--- Run $i of $count (seed $i) ---"
        if "$BINARY" +UVM_SEED="$i" +UVM_TESTNAME="${test_name:-my_test}" 2>&1 | tee "run_$i.log"; then
            echo "  Run $i: PASS"
        else
            echo "  Run $i: FAIL"
        fi
    done
}

if $clean_mode; then
    clean
fi

if $zip_mode; then
    zip_project
fi

if [[ -n "$test_name" || "$run_count" -gt 0 ]]; then
    if [[ ! -f "$BINARY" ]]; then
        build
    fi

    if [[ "$run_count" -gt 0 ]]; then
        run_multiple "$run_count"
    elif [[ -n "$test_name" ]]; then
        run_test "$test_name"
    fi
fi

if ! $clean_mode && ! $zip_mode && [[ -z "$test_name" && "$run_count" -eq 0 ]]; then
    echo "No action specified. Use -h for help."
    exit 1
fi
