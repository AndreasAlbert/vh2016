TAG="v2"
CMSSW_VERSION="CMSSW_11_2_0_pre7"
INPUT=$(readlink -e ./input)
WDIR="./${TAG}_${CMSSW_VERSION}/"
mkdir -p ${WDIR}
WDIR=$(readlink -e ${WDIR})

pushd ${WDIR}
scramv1 project CMSSW ${CMSSW_VERSION}
cd ${CMSSW_VERSION}/src
eval `scram runtime -sh`

PYDIR=${CMSSW_BASE}/src/Configuration/GenProduction/python/
mkdir -p ${PYDIR}

for GP in ${INPUT}/*tgz; do
    NAME=$(basename $GP | sed "s/.tgz//")
    FRAGMENT=${PYDIR}/${NAME}_cff.py
    cp ${INPUT}/fragment.py ${FRAGMENT}
    sed -i "s|@GRIDPACK|$(readlink -e ${GP})|" ${FRAGMENT}
    
done

cd ${CMSSW_BASE}/src
scram b -j4

cd $WDIR

NEVENTS=10000
NTHREADS=4
SEED=${RANDOM}

# JHU
for FRAGMENT in ${CMSSW_BASE}/src/Configuration/GenProduction/python/*JHU*_cff.py; do
    NAME=$(basename ${FRAGMENT} | sed "s/_cff.py//")
    cmsDriver.py Configuration/GenProduction/python/$(basename $FRAGMENT) \
    --fileout file:NANOGEN_${NAME}.root \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAOD \
    --conditions auto:mc \
    --step LHE,GEN,NANOGEN \
    --nThreads ${NTHREADS} \
    --era Run2_2017  \
    --python_filename wmLHEG_${NAME}_cfg.py \
    --no_exec \
    --customise_commands 'process.load("FWCore.MessageService.MessageLogger_cfi")' \
    --customise_commands 'process.MessageLogger.destinations = ["cout", "cerr"]' \
    --customise_commands 'process.MessageLogger.cerr.FwkReport.reportEvery = 100' \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="${SEED}" \
    -n ${NEVENTS};

    RUNNER="run_${NAME}.sh"
    echo "cd ${CMSSW_RELEASE_BASE}/src" > ${RUNNER}
    echo 'eval `scram runtime -sh`' >> ${RUNNER}
    echo "cd ${WDIR}" >> ${RUNNER}
    echo "cmsRun  wmLHEG_${NAME}_cfg.py" >> ${RUNNER}

done


# POWHEG



curl -s -k https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIIFall17wmLHEGS-03386 -o ${CMSSW_BASE}/src/Configuration/GenProduction/python/ZH_ph_cff.py

curl -s -k https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIIFall17wmLHEGS-03384 -o ${CMSSW_BASE}/src/Configuration/GenProduction/python/WminusH_ph_cff.py

curl -s -k https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIIFall17wmLHEGS-03385 -o ${CMSSW_BASE}/src/Configuration/GenProduction/python/WplusH_ph_cff.py


# JHU
for FRAGMENT in ${CMSSW_BASE}/src/Configuration/GenProduction/python/*ph*_cff.py; do
    NAME=$(basename ${FRAGMENT} | sed "s/_cff.py//")
    cmsDriver.py Configuration/GenProduction/python/$(basename $FRAGMENT) \
    --fileout file:NANOGEN_${NAME}.root \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAOD \
    --conditions auto:mc \
    --step LHE,GEN,NANOGEN \
    --nThreads ${NTHREADS} \
    --era Run2_2017  \
    --python_filename wmLHEG_${NAME}_cfg.py \
    --no_exec \
    --customise_commands 'process.load("FWCore.MessageService.MessageLogger_cfi")' \
    --customise_commands 'process.MessageLogger.destinations = ["cout", "cerr"]' \
    --customise_commands 'process.MessageLogger.cerr.FwkReport.reportEvery = 100' \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="${SEED}" \
    -n ${NEVENTS};

    RUNNER="run_${NAME}.sh"
    echo "cd ${CMSSW_RELEASE_BASE}/src" > ${RUNNER}
    echo 'eval `scram runtime -sh`' >> ${RUNNER}
    echo "cd ${WDIR}" >> ${RUNNER}
    echo "cmsRun  wmLHEG_${NAME}_cfg.py" >> ${RUNNER}

done