# install all the things necessary because xcorr randomly stopped working.
touch .software
echo "matlab" > .software
sudo apt update
sudo apt install -y libXcomposite1
sudo apt install -y libnss3
sudo apt install -y libxi6
sudo apt install -y libxcursor1
sudo apt install -y libasound2
sudo apt install -y libXdamage1
sudo apt install -y libXtst6
sudo apt install -y libXrandr2
