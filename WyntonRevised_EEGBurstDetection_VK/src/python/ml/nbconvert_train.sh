if [ "$HOSTNAME" = groenig-0 ]; then
    /data/scratch/tzhan/anaconda2/bin/jupyter nbconvert --to script train.ipynb
else
    jupyter nbconvert --to script train.ipynb
fi
sed -i '/get_ipython()/d' train.py
sed -i '/^# In\[ \]:/d' train.py
sed -i '1N;N;/^\n\n$/d;P;D' train.py 
sed -i '/^$/N;/^\n$/D' train.py

