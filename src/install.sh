
sudo python -m pip install --upgrade pip
sudo apt-get install python-pip
sudo pip install graphviz
sudo pip install pydotplus
sudo pip install --user numpy scipy matplotlib ipython jupyter pandas sympy nose
sudo apt-get install parallel
sudo apt-get install graphviz
wget -O z3.zip https://github.com/Z3Prover/z3/archive/master.zip
unzip z3.zip -d z3/
cd z3/z3-master
python scripts/mk_make.py --python
cd build
make
sudo make install
cd ../..
