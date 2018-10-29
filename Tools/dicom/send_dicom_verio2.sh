#export DCMTK=/usr/cenir/src/dcmtk
#export LD_LIBRARY_PATH=$DCMTK/lib
export DCMDICTPATH=/network/lustre/iss01/cenir/software/irm/dcmtk/dicom.dic


storescu -aet CENIR03  -aec IRM2_SEC 192.168.6.6 104 $*
