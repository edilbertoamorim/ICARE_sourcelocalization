echo $HOSTNAME
for var in "$@"
do
	echo "starting training"
    echo $var
	case $HOSTNAME in
  		(*groenig*) /data/scratch/tzhan/anaconda2/bin/python train.py $var 2>&1 | tee logs/run$var.log;;
  		(*vcuda*) /data/scratch/tzhan/anaconda2/bin/python train.py $var 2>&1 | tee logs/run$var.log;;
  		(*) python train.py $var 2>&1 | tee logs/run$var.log;;
	esac
done
