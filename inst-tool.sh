#!/bin/bash
#

echo "NB ARGS: $#" >> log.txt
echo "TOOLEXEC: $@" >> log.txt

ddDir=$(cat /tmp/__ddDir 2>/dev/null)

compileASM() {
    echo "# COMPILING ASM"
    ddDir="$1-datadog"
    echo $ddDir > /tmp/__ddDir
    cd /Users/francois.mazeau/go/src/github.com/DataDog/dd-trace-go/internal/appsec
    wdir=$(go build -work -a -tags appsec . 2>&1 | cut -d '=' -f 2)
    rm -f /tmp/__dd_aggregate_cfg
    echo "# WDIR: $wdir"
    echo "# Aggregating all appsec importfg"
    for i in $wdir/*
    do
        cat $i/importcfg >> /tmp/__dd_aggregate_cfg
    done
    cp -R $wdir/b001 $ddDir
    cat $1/importcfg > /tmp/__toto
    echo "packagefile gopkg.in/DataDog/dd-trace-go.v1/internal/appsec=$ddDir/_pkg_.a" >> /tmp/__toto
    cp /tmp/__toto $1/importcfg
    echo "# DONE"
    echo "# PARENT PID: $PPID"
    touch /tmp/__compiled
}

for i in $@
do
    if [[ $i =~ "/b001/" ]]
    then
        echo "# FOUND b001 folder in $i"
        found=true
        workdir=$(dirname $i)
    fi
    [[ $i =~ "main.go" ]] && $(cat /Users/francois.mazeau/go/src/github.com/DataDog/instrumentation/customMain/main.go > $i)
    if [[ $i =~ "importcfg.link" ]]
    then
        echo "# Adding appsec deps to final importcfg.link"
        old=$(cat $i)
        cp $i /tmp/__link_file
        echo "packagefile gopkg.in/DataDog/dd-trace-go.v1/internal/appsec=$ddDir/_pkg_.a" > $i
        cat /tmp/__dd_aggregate_cfg | sed "s/^.*importmap.*$//g">> $i #duplicate fmt here, probably very bad
        cat /tmp/__link_file >> $i
        cat $i | sort | uniq > /tmp/__final
        cp /tmp/__final $i
        rm -f /tmp/__link_file
    fi
    cmd="$cmd $i"
done

# TODO: check if file is main.go and replace with custom main that calls appsec to verify POC works

[[ $found == "true" ]] && [[ ! -e /tmp/__compiled ]] && compileASM $workdir

$cmd
