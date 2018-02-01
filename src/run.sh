#mchname='deadlock1U.mch'
#mchname='dining-philosophers.mch'

# Working examples:
#mdl_name='example1_dining_philosophers'

echo Note: Filenames should not contain any \'-\'!
#mdl_name='example_robotcleaner'
mdl_name='example_artist'
#mdl_name='dining_philosophers'
#mdl_name='report'
#mdl_name='report_init'
#mdl_name='revset'
#mdl_name='NormalisationTest'
#mdl_name='Ancestors'
#mdl_name='EnumTest'
tmp_folder='tmpfile'
num_change=2
num_epoch=100
max_cost=3
subgraph_size=10
no_dead=false
no_ass=false




revision_option="No"
mc_opt=" "

if [ ${no_dead} == true ]; then
  revision_option=${revision_option}"Dead"
  mc_opt=${mc_opt}" -nodead"
fi

if [ ${no_ass} == true ]; then
  revision_option=${revision_option}"Ass"
  mc_opt=${mc_opt}" -noass"
fi



if [ ${revision_option} == "No" ]; then
  revision_option=Default
fi


echo ${revision_option}
echo ${mc_opt} 

p=qq/ee/pp/qq/afsdsad.13.dwfq.32
q=${p##*/}
echo $q
r=${q%.*.*}
echo $r

rm -r ${tmp_folder}
mkdir ${tmp_folder}

#./../ProB/probcli -model_check -nodead -save allstate -his historytmp -his_option show_states -spdot statespace.txt -l pl.log -ll -c ${mch_name}


echo Checking the original machine \'${mdl_name}.mch\'. Results are in \'${tmp_folder}\'.

mkdir ${tmp_folder}/0
cp ${mdl_name}.mch ${tmp_folder}/0/${mdl_name}_original.mch

#tttt='revset'
#./../ProB/probcli -model_check -nodead -noinv -noass -p MAX_INITIALISATIONS 100 -mc_mode bf -spdot ${tttt}.dot ${tttt}.mch

#exit 1;

false && {
cp history.tmp tmpfile/0/report.trace
./../ProB/probcli -bmc ${subgraph_depth} -noinv -nodead -noass -nogoal -save ${tmp_folder}/0/${mdl_name}.allstate -his ${tmp_folder}/0/${mdl_name}.history -spdot ${tmp_folder}/0/${mdl_name}.statespace.dot -pp ${tmp_folder}/0/${mdl_name}.mch -l ${tmp_folder}/0/${mdl_name}.pl.log -c ${tmp_folder}/0/${mdl_name}_original.mch || exit 1;

exit 1 

./../ProB/probcli -model_check -p MAX_INITIALISATIONS 300 -bf -save ${tmp_folder}/0/${mdl_name}.allstate -his ${tmp_folder}/0/${mdl_name}.history -spdot ${tmp_folder}/0/${mdl_name}.statespace.dot -pp ${tmp_folder}/0/${mdl_name}.mch -l ${tmp_folder}/0/${mdl_name}.pl.log -c ${tmp_folder}/0/${mdl_name}_original.mch || exit 1;

exit 1;

}
./../ProB/probcli -model_check -df ${mc_opt} -save ${tmp_folder}/0/${mdl_name}.allstate -his ${tmp_folder}/0/${mdl_name}.history -spdot ${tmp_folder}/0/${mdl_name}.statespace.dot -pp ${tmp_folder}/0/${mdl_name}.mch -l ${tmp_folder}/0/${mdl_name}.pl.log -c ${tmp_folder}/0/${mdl_name}_original.mch || exit 1;

cp ${tmp_folder}/0/${mdl_name}_original.prob ${tmp_folder}/0/${mdl_name}.prob

new_mdl_name=${mdl_name}

for j in $(seq 1 ${num_epoch}) ; do
    let p=j-1
    echo $p
    echo ppppppppp
    

  if test -s ${tmp_folder}/${p}/${new_mdl_name}.history ; then
    # If there is a faulty path...
    echo A faulty path found in ${new_mdl_name}.
    echo ------ Epoch $j start: ------

    old_mdl_name=${new_mdl_name}

    # Produce a state isolation.
    #python src/python/process_state_space.py ${tmp_folder}/${p}/${old_mdl_name}.statespace.dot ${tmp_folder}/${p}/${old_mdl_name}.statespace.plain ${tmp_folder}/${p}/${old_mdl_name}.isocomp ${tmp_folder}/${p}/${old_mdl_name}.faultystate || exit 1;

    python src/python/state_space_analysis.py ${tmp_folder}/${p}/${old_mdl_name}.statespace.dot ${tmp_folder}/${p}/${old_mdl_name}.mch ${tmp_folder}/${p}/${old_mdl_name}.history ${tmp_folder}/${p}/${old_mdl_name}.temp ${tmp_folder}/${p}/${old_mdl_name}.ftrans || exit 1;


    python src/python/machine_repair_basic.py ${tmp_folder}/${p}/${old_mdl_name}.mch ${tmp_folder}/${p}/${old_mdl_name}.rev.mch ${max_cost} ucons.pred ${tmp_folder}/${p}/${old_mdl_name}.ftrans rev_epoch_${j} ${revision_option} || exit 1;

    mkdir ${tmp_folder}/${j}
    cp ${tmp_folder}/${p}/${old_mdl_name}.rev.mch ${tmp_folder}/${j}/${old_mdl_name}_original.mch

    # Check the new machine.
    echo Checking the revision...
    ./../ProB/probcli -model_check ${mc_opt} -df -save ${tmp_folder}/${j}/${old_mdl_name}.allstate -his ${tmp_folder}/${j}/${old_mdl_name}.history -spdot ${tmp_folder}/${j}/${old_mdl_name}.statespace.dot -pp ${tmp_folder}/${j}/${old_mdl_name}.mch -l ${tmp_folder}/${j}/${old_mdl_name}.pl.log -c ${tmp_folder}/${j}/${old_mdl_name}_original.mch || exit 1;


continue

exit 1;

    # Produce a state revision.
    python src/python/revise_by_z3.py ${tmp_folder}/${p}/${old_mdl_name}.mch ${tmp_folder}/${p}/${old_mdl_name}.faultystate ${max_cost} ${tmp_folder}/${p}/${old_mdl_name}.revcomp || exit 1;

    mkdir ${tmp_folder}/${j}

    echo Repairing the machine. Results are in \'${tmp_folder}/${j}\'.
    #./src/prolog/runRepairProb.pl ${tmp_folder}/${p}/${old_mdl_name}.prob ${tmp_folder}/${p}/${old_mdl_name}.history ${tmp_folder}/${p}/${old_mdl_name}.isocomp ${tmp_folder}/${p}/${old_mdl_name}.revcomp ${num_change} ${tmp_folder}/${j} ${old_mdl_name}


    echo Making the outgoing subgraph of \'${tmp_folder}/${p}/${old_mdl_name}.prob\'. Results are in \'${tmp_folder}\'.

    old_subgraph=${tmp_folder}/${p}/${old_mdl_name}.prob.sub.statespace.dot

    ./../ProB/probcli -bf -mc ${subgraph_size} -noinv -nodead -noass -nogoal -spdot ${old_subgraph} -pp ${tmp_folder}/${p}/${old_mdl_name}.prob.sub.mch ${tmp_folder}/${p}/${old_mdl_name}.prob.sub.prob || exit 1;

    python src/python/process_state_space.py ${old_subgraph} ${old_subgraph}.plain || exit 1;



    #gcc src/c/repair_main.c -o repair_mai
    #./repair_main


    rm compute_stategraph_difference
    gcc compute_stategraph_difference.c -o compute_stategraph_difference -lm

    
    #false &&
    {
    for i in ${tmp_folder}/${j}/${old_mdl_name}.*.sub.prob ; do

      new_prob_name=${i##*/}
      subfname=${new_prob_name%.*}
      new_mdl_name=${subfname%.*}


      echo Making the outgoing subgraph of \'${i}\'. Results are in \'${tmp_folder}\'.

      new_subgraph=${tmp_folder}/${j}/${new_mdl_name}.sub.statespace.dot
      ./../ProB/probcli -bf -mc ${subgraph_size} -noinv -nodead -noass -nogoal -spdot ${new_subgraph} -pp ${tmp_folder}/${j}/${new_mdl_name}.sub.mch ${tmp_folder}/${j}/${new_mdl_name}.sub.prob || exit 1;

      python src/python/process_state_space.py ${new_subgraph} ${new_subgraph}.plain || exit 1;

      ./compute_stategraph_difference ${old_subgraph}.plain ${new_subgraph}.plain

#exit 1

    done;
    }

    false &&
    {
    for i in ${tmp_folder}/${j}/${old_mdl_name}.*.sub.prob ; do

      new_prob_name=${i##*/}
      subfname=${new_prob_name%.*}
      new_mdl_name=${subfname%.*}


      echo Checking \'${i}\'. Results are in \'${tmp_folder}\'.

      ./../ProB/probcli -model_check -save ${tmp_folder}/${j}/${new_mdl_name}.allstate -his ${tmp_folder}/${j}/${new_mdl_name}.history -spdot ${tmp_folder}/${j}/${new_mdl_name}.statespace.dot -pp ${tmp_folder}/${j}/${new_mdl_name}.mch -l ${tmp_folder}/${j}/${new_mdl_name}.pl.log -c ${i} || exit 1;

      echo $new_mdl_name
    done ;
    }


    echo ------ End of Epoch $j. ------
  else
    # If no faulty path exists, then break.
    cp ${tmp_folder}/${p}/${new_mch_name} ${tmp_folder}/${p}/final_${mdl_name}.mch
    echo Model ${mdl_name} has been repaired. Results are in ${tmp_folder}/result.${mdl_name}.mch
    break

  fi 

done


false && 
{
python src/python/process_state_space.py ${tmp_folder}/${mch_name}.statespace.dot ${tmp_folder}/${mch_name}.statespace.plain ${tmp_folder}/${mch_name}.isocomp || exit 1;

echo Generating new machines. Results are in \'${tmp_folder}\'.
./src/prolog/runRepairProb.pl ${prob_name} ${tmp_folder}/${mch_name}.history ${tmp_folder}/${mch_name}.isocomp ${num_change} ${tmp_folder}


#gcc src/c/repair_main.c -o repair_main
#./repair_main


for i in ${tmp_folder}/*.prob ; do
  echo Checking \'${i}\'. Results are in \'${tmp_folder}\'.
  ./../ProB/probcli -model_check -save ${i}.allstate -his ${i}.history -spdot ${i}.statespace.dot -l ${i}.pl.log -c ${i} -pp ${i}.mch || exit 1;

done ;
}

## ./../ProB/probcli deadlock1.mch -model_check -noinv > checkresult1



