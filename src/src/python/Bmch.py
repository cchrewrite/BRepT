import sys
import pydotplus
import pydot
import time
import os

from graphviz import Graph

# Gnenrate a IF-THEN substitution for state revision.
# fstate --- A faulty state.
# cstate --- A correct state.
def gen_if_then_subs(fstate,cstate):
    subs = gen_subs(fstate,cstate)
    res = "IF %s THEN %s END"%(fstate,subs)
    return res


# Generate substitution from State X to State Y.
# x --- State X
# y --- State Y
def gen_subs(x,y):
    p = x.split("&")
    q = y.split("&")
    res = ""
    for i in xrange(len(p)):
        if p[i].replace(" ","") != q[i].replace(" ",""):
            sub = q[i].replace("=",":=")
            res = res + sub + " ; "
    if res == "":
        print "WARNING: No substitution procuded. Return \"skip\"."
        return "skip"
    else:
        res = res[0:len(res)-3]
        return res

# Generate a revision set.
# mch --- A B-machine. fstate --- A faulty state.
# max_cost --- The max cost of revision. rev_opt --- Revision option.
# file_annotation --- The annotation of temp files.
def generate_revision_set(mch, fstate, max_cost, rev_opt, file_annotation):
    revsetfilename = file_annotation + ".revset"
    revsetfile = open(revsetfilename,"w")
    sm = generate_revision_set_machine(mch, fstate, max_cost, rev_opt)
    for item in sm:
        revsetfile.write("%s\n"%item)
    revsetfile.close()

    bth = 2048#65536
    print "Info: The maximum search breadth (including duplicate search when free variables exist) of the SMT solver is %d."%bth
    #mkgraph = "./../ProB/probcli -model_check -nodead -noinv -noass -p MAX_INITIALISATIONS %d -mc_mode bf -spdot %s.statespace.dot %s"%(bth,revsetfilename,revsetfilename)

    mkgraph = "./../ProB/probcli -model_check -nodead -noinv -noass -disable-timeout -p MAX_INITIALISATIONS %d -mc_mode bf -spdot %s.statespace.dot %s"%(bth,revsetfilename,revsetfilename)

    os.system(mkgraph)

    revset,numrev = extract_state_revision_from_file("%s.statespace.dot"%revsetfilename, max_cost)

    return revset,numrev


# Get the grand type ( bool / number / set / symbol ) of a value.
def get_grand_type(v):
    x = v.replace(" ","")
    if x == "TRUE" or x == "FALSE": return "BOOL"
    try:
        t = int(x)
        return "NUMBER"
    except ValueError:
        t = -1
    if x[0] == "{": return "SET"
    return "SYMBOL"


# Generate state differences.
# fst --- A faulty state ; dt --- The type of differences.
# dt can be "absolute" or "euclidean"
def generate_state_difference(fst, dt):
    fs = sentence_to_label(fst)
    res = ""
    if dt == "absolute":
        for i in xrange(len(fs) / 2):
            u = i * 2
            vt = get_grand_type(fs[u+1])
            if vt == "BOOL" or vt == "SYMBOL":
                diff = "card ( { %s } - { %s } )"%(fs[u],fs[u+1])
            elif vt == "SET":
                diff = "( card ( %s - %s ) + card ( %s - %s ) )"%(fs[u],fs[u+1],fs[u+1],fs[u])
            else: # The case of "NUMBER":
                diff = "max ( { %s - %s , %s - %s } )"%(fs[u],fs[u+1],fs[u+1],fs[u])
            res = res + diff + " + "
        res = res[0:len(res) - 3]
        return res
    else: 
        print "Error: The type of difference is invalid!"
        return None

# Generate restrictions of state differences.
# fst --- A faulty state ; dt --- The type of differences; md --- The max cost of diffrences.
# dt can be "absolute" or "euclidean"
def gen_sdr(fst, dt, md):
    sd = generate_state_difference(fst, dt)
    res = ""
    for i in xrange(md):
        y = sd + " = %d"%(i+1)
        res = res + y + " or "
    res = " ( " + res[0:len(res)-4] + " ) "
    return res

# Generate a list of operations for state selection.
# fst --- A faulty state ; dt --- The type of differences; md --- The max cost of diffrences.
# dt can be "absolute" or "euclidean"
def gen_ope_ss(fst, dt, md):
    res = []
    res.append("OPERATIONS")
    diff = generate_state_difference(fst, dt)
    for cost in xrange(md + 1):
        x = []
        x.append("cost_is_%d = "%cost)
        x.append("PRE")
        x.append("%s = %d"%(diff,cost))
        x.append("THEN")
        x.append("skip")
        if cost == md:
            x.append("END")
        else:
            x.append("END;")
        res = res + x
    return res

# Get a label and remove all line breaks:
def get_label_pretty(x):
    res = x.get_label()
    res.replace("\n","")
    return res

# Print a B-machine to a file.
def print_mch_to_file(mch,filename):
    fp = open(filename,"w")
    for item in mch:
        fp.write("%s\n"%item)
    fp.close()
    return 0


# Generate a time annotation.
def time_annotation():
    x = time.time()
    x = int(x * 1000)
    x = "_%s"%str(x)
    return x

# Add a new operation to a B-machine:
# mch --- A B-machine. ope --- An operation.
def add_new_operation(mch,ope):
    mchlen = len(mch)
    i = 0
    while i < mchlen and get_first_token(mch[i]) != "OPERATIONS":
        i = i + 1
    res = mch[0:i+1] + ope + mch[i+1:mchlen]

    return res

# Create a new operation.
# precond -- A pre-condition. opename --- An operation name. revstate --- A state revision.
def create_new_operation(precond,opename,revstate):
    res = []
    res.append("%s = "%opename)
    res.append("PRE")
    res.append("%s"%precond)
    res.append("THEN")
    subst = state_to_substitution(revstate)
    res.append(subst)
    res.append("END;")
    return res

# Convert a state to substitution.
def state_to_substitution(st):
    res = st.replace("=",":=")
    res = res.replace("&",";")
    return res

# Extract revisions of a state.
# fname --- The filename of a state graph in the Dot format.
# mcost --- The max cost.
def extract_state_revision_from_file(fname,mcost):
    print "Extracting revisions of states from %s."%fname
    pp = pydotplus.graphviz.graph_from_dot_file(fname) 
    nlist = pp.get_node_list()
    elist = pp.get_edge_list()
    res = []
    lres = 0
    for cost in xrange(mcost + 1):
        edge_name = "\"cost_is_%d\""%cost
        res_sub = []
        for i in xrange(len(elist)):
            #if elist[i].get_label() == "\"INITIALISATION\"" or elist[i].get_label() == "\"INITIALIZATION\"":
            if elist[i].get_label() == edge_name:
                uname = elist[i].get_destination()
                for j in xrange(len(nlist)):
                    if nlist[j].get_name() == uname:
                        slabel = nlist[j].get_label()
                        break
                y = proc_state_label(slabel)
                rstate = label_to_sentence(y)
                res_sub.append(rstate)
        res.append(res_sub)
        lres = lres + len(res_sub)
        print "Cost = %d: %d state revisions are found."%(cost,len(res_sub))
    #print "Totally %d state revisions are found."%lres
    return res, lres

# A simple function for computing the difference between two states.
# st1 and st2 are two states.
def state_diff_simple(st1,st2):
    x = sentence_to_label(st1)
    y = sentence_to_label(st2)
    res = 0.0
    for i in xrange(len(x)):
        if x[i].replace(' ','') != y[i].replace(' ',''):
            res = res + 1.0
    return res

# Get variable names of a pretty-printed B-Machine.
def get_var_names(mch):
    mchlen = len(mch)
    i = 0
    while i < mchlen and not("VARIABLES" in mch[i]):
        i = i + 1
    if i == mchlen:
        print "Warning: No VARIABLES or ABSTRACT_VARIABLES token found in this B-machine."
        return []
    j = i + 1
    while j < mchlen and not("INVARIANT" in mch[j]) and not("PROPERTIES" in mch[j]):
        j = j + 1
    if j == mchlen:
        print "Warning: No INVARIANT token found in this B-machine."
        return []

    res = []
    k = i + 1
    while k < j:
        res.append(get_first_token(mch[k]))
        k = k + 1

    return res


# Split a line of B-code into tokens.
def b_code_split(x):
    y = '' + x
    y = y.replace('(',' ( ')
    y = y.replace(')',' ) ')
    y = y.replace(',',' , ')
    y = y.replace('={',' = { ')
    y = y.replace('}=',' } = ')
    y = y.replace('{',' { ')
    y = y.replace('}',' } ')
    y = y.replace(';',' ; ')
    y = y.split()
    return y


   
# Replace all occurance of Token tp with Token tq. "blk" is a block of code.
def replace_token(blk, tp, tq):
    res = []
    for item in blk:
        x = b_code_split(item)
        for i in xrange(len(x)):
            if x[i] == tp:
                x[i] = ' ' + tq
            else:
                x[i] = ' ' + x[i]
        y = ''.join(x)
        res.append(y)
    return res

# Make a list of "init" variables.
def make_init_var_list(vlist):
    res = []
    for x in vlist:
        y = x + '_init'
        res.append(y)
    return res

# Replace all occurance of a list of variables with their "init" variables.
# blk --- A block of code. vlist --- A list of variables.
def replace_var_with_init(blk,vlist):
    rlist = make_init_var_list(vlist)
    res = blk[:]
    for i in xrange(len(vlist)):
        res = replace_token(res,vlist[i],rlist[i])
    return res

# Get all pre-conditions from a B-Machine.
# mch --- A pretty-printed B-Machine.
def get_all_precond(mch):
    res = []
    i = 0
    while get_first_token(mch[i]) != "OPERATIONS":
        i = i + 1
    mchlen = len(mch)
    while i < mchlen:
        if get_first_token(mch[i]) == "PRE":
            j = i + 1
            y = ''
            while get_first_token(mch[j]) != "THEN":
                y = y + ' ' + mch[j]
                j = j + 1
            res.append(y)
            i = j + 1
        else:
            i = i + 1
    if res == []:
        print "Warning: No pre-condition found! Return [\'TRUE\']."
        return ['TRUE']
    return res

# Generation a B-disjunction of predicates.
# plist --- A list of predicates.
def gen_b_disj(plist):
    if len(plist) == 1:
        return plist[0]
    res = ""
    for p in plist:
        res = res + "( " + p + " ) or "
    res = res[0:len(res)-3]
    return res

# Get invariants of a B-Machine.
# mch --- A pretty-printed B-Machine.
def get_invariants(mch):
    res = []
    i = 0
    while get_first_token(mch[i]) != "INVARIANT":
        i = i + 1
    mchlen = len(mch)
    j = i + 1
    while j < mchlen:
        tt = get_first_token(mch[j])
        # Based on the syntax of <The B-book>, p.273.
        if tt == "ASSERTIONS": break
        if tt == "DEFINITIONS": break
        if tt == "INITIALIZATION": break
        if tt == "INITIALISATION": break
        if tt == "OPERATIONS": break
        if tt == "END": break
        res.append(mch[j])
        j = j + 1
    if res == []:
        print "Warning: No invariant found! Return [\'TRUE\']."
        return ['TRUE']
    return res



# Get assertions of a B-Machine.
# mch --- A pretty-printed B-Machine.
def get_assertions(mch):
    res = []
    i = 0
    mchlen = len(mch)
    while i < mchlen:
        if get_first_token(mch[i]) == "ASSERTIONS": break
        i = i + 1
    j = i + 1
    while j < mchlen:
        tt = get_first_token(mch[j])
        # Based on the syntax of <The B-book>, p.273.
        if tt == "DEFINITIONS": break
        if tt == "INITIALIZATION": break
        if tt == "INITIALISATION": break
        if tt == "OPERATIONS": break
        if tt == "END": break
        res.append(mch[j])
        j = j + 1
    if res == []:
        print "Warning: No assertion found! Return \'None\'."
        return None
    return res




# Convert a list of variables to a sequence.
def var_list_to_seq(vlist):
    res = ""
    for v in vlist:
        res = res + v + " , "
    res = res[0:len(res)-2]
    return res

# Generate a revision condition (in ANY-WHERE-THEN-END format).
# mch --- A pretty-printed B-machine.
# ex_list --- A list of extra conditions.
# rev_opt --- Revision Option.
def generate_revision_condition(mch, ex_list, rev_opt):
    var_list = get_var_names(mch)
    ope_var_list = get_all_ope_var(mch)
    inv_list = get_invariants(mch)
    ass_list = get_assertions(mch)
    precon_list = get_all_precond(mch)
    precon_disj = gen_b_disj(precon_list)

    vseq = var_list_to_seq(var_list)
    rlist = make_init_var_list(var_list)
    rseq = var_list_to_seq(rlist)

    any_seq = rseq

    if ope_var_list != []:
        ope_vseq = var_list_to_seq(ope_var_list)
        any_seq = any_seq + " , " + ope_vseq

    rev_list = ["ANY %s WHERE"%any_seq]
    rev_list = rev_list + inv_list
    if not("Ass" in rev_opt) and not(ass_list == None):
        rev_list.append(" & ")
        rev_list = rev_list + ass_list
    rev_list.append(" & ")
    rev_list = rev_list + ex_list
    if not("Dead" in rev_opt):
        rev_list.append(" & ( " + precon_disj + " )")
    rev_list = replace_var_with_init(rev_list,var_list)
    rev_list.append("THEN")
    rev_list.append("%s := %s"%(vseq,rseq))
    rev_list.append("END")

    return rev_list


# Generate a revision set machine.
# mch --- A pretty-printed B-machine.
# fst --- A faulty state.
# mcost --- The max cost.
# rev_opt --- Revision Option.
def generate_revision_set_machine(mch, fst, mcost, rev_opt):
    diff_cond = gen_sdr(fst,"absolute",mcost)
    rev_cond = generate_revision_condition(mch, [diff_cond], rev_opt)
    diff_ope = gen_ope_ss(fst, "absolute", mcost)
    
    res = []
    i = 0
    mchlen = len(mch)
    while i < mchlen:
        tt = get_first_token(mch[i])
        # Based on the syntax of <The B-book>, p.273.
        if tt == "INITIALIZATION": break
        if tt == "INITIALISATION": break
        res.append(mch[i])
        i = i + 1
    res.append("INITIALISATION")
    res = res + rev_cond
    res = res + diff_ope
    res.append("END")
    return res

    



# Add a pre-condition condition to an operation.
# mch --- A pretty-printed B-Machine. ope --- The name of an operation which will be changed. cond --- A pre-condition.
def add_precond_to_mch(mch,ope,cond):
    y = []
    i = 0
    while get_first_token(mch[i]) != "OPERATIONS":
        y.append(mch[i])
        i = i + 1
    mchlen = len(mch)
    while i < mchlen:
        if get_first_token(mch[i]) == ope:
            if get_first_token(mch[i+1]) == "PRE":
                y.append(mch[i])
                y.append(mch[i+1])
                y.append(cond + " &")
                i = i + 2
            else:
                flag = 1
                j = i + 2
                while flag > 0:
                    jt = get_first_token(mch[j])
                    if jt == "END":
                        flag = flag - 1
                    # Based on the syntax of <The B book.> pp 266
                    elif jt == "BEGIN" or jt == "PRE" or jt == "IF" or jt == "CHOICE" or jt == "ANY":
                        flag = flag + 1
                    j = j + 1
                y.append(mch[i])
                y.append("PRE")
                y.append(cond)
                y.append("THEN")
                k = i + 1
                while k < j:
                    y.append(mch[k])
                    k = k + 1
                if y[-1] == "END;":
                    y[-1] = "END"
                    y.append("END;")
                else:
                    y.append("END")
                i = j
        else:
            y.append(mch[i])
            i = i + 1
    return y



# Add a IF-THEN substitution to an operation.
# mch --- A pretty-printed B-Machine. ope --- The name of an operation which will be changed. subs --- A IF-THEN substitution.
def add_if_then_subs_to_mch(mch,ope,subs):
    y = []
    i = 0
    while get_first_token(mch[i]) != "OPERATIONS":
        y.append(mch[i])
        i = i + 1
    mchlen = len(mch)
    while i < mchlen:
        if get_first_token(mch[i]) == ope:
            y.append(mch[i])
            j = i + 1
            jt = get_first_token(mch[j])
            while not(jt == "BEGIN" or jt == "PRE" or jt == "IF" or jt == "CHOICE" or jt == "ANY"):
                y.append(mch[j])
                j = j + 1
                jt = get_first_token(mch[j])
            y.append(mch[j])
            j = j + 1
            flag = 1
     
            while flag > 0:
                jt = get_first_token(mch[j])
                if jt == "END":
                    flag = flag - 1
                # Based on the syntax of <The B book.> pp 266
                elif jt == "BEGIN" or jt == "PRE" or jt == "IF" or jt == "CHOICE" or jt == "ANY":
                    flag = flag + 1
                y.append(mch[j])
                j = j + 1
            k = len(y) - 1
            while get_first_token(y[k]) != "END":
                k = k - 1
            y = y[0:k] + [" ; ",subs] + y[k:len(y)]

            i = j
        else:
            y.append(mch[i])
            i = i + 1
    return y



# Get the first token of a sentence:
def get_first_token(x):
    y = '' + x
    y = y.replace('(',' ')
    y = y.replace(',',' ')
    y = y.replace('=',' ')
    y = y.replace(';',' ')
    y = y.split()
    if len(y) > 0:
        return y[0]
    else:
        return None


# Get all operation declarations.
# mch --- A pretty-printed B-Machine.
def get_all_ope_decl(mch):
    y = []
    i = 0
    while get_first_token(mch[i]) != "OPERATIONS":
        i = i + 1
    mchlen = len(mch)
    i = i + 1
    while i < mchlen:
        if mch[i].split() == []:
            i = i + 1
            continue
        if get_first_token(mch[i]) == "END": break
        y.append(mch[i])
        i = i + 1
        while mch[i].split() == []:
           i = i + 1
        i = i + 1
        flag = 1
        while flag != 0:
            jt = get_first_token(mch[i])
            if jt == "END":
                flag = flag - 1
            elif jt == "BEGIN" or jt == "PRE" or jt == "IF" or jt == "CHOICE" or jt == "ANY":
                flag = flag + 1
            i = i + 1 
    return y


# Get all operation variables:
# mch --- A pretty-printed B-Machine.
def get_all_ope_var(mch):
    x = get_all_ope_decl(mch)
    y = []
    for item in x:
        n,p,q = proc_trans_decl(item)
        y = y + p
        y = y + q
    return y

# Process the declaration of a transition.
# In general, the declaration x is in one of the following formats:
# "ope ="
# "ope(in_1,in_2,...,in_n) ="
# "out_1,out_2,...,out_m <-- ope ="
# "out_1,out_2,...,out_m <-- ope(in_1,in_2,...,in_n) ="
def proc_trans_decl(x):
    lenx = len(x)
    invarlist = []
    outvarlist = []
    for i in xrange(lenx):
        if x[i:i+3] == "<--":
            y = x[0:i-1]
            y = y.replace(',',' ')
            outvarlist = y.split()
            x = x[i+3,lenx]
            lenx = len(x)
            break
    x = x.replace('=',' ')
    x = x.replace(',',' ')
    x = x.replace('(',' ')
    x = x.replace(')',' ')
    x = x.split()
    opename = x[0]
    invarlist = x[1:len(x)]
    return opename, invarlist, outvarlist

# Convert a set of state labels to a B-sentence.
def label_to_sentence(x):
    if len(x) == 0:
        return "TRUE"
    else:
        res = ""
        for i in xrange(len(x)):
            if i % 2 == 0:
                res = res + x[i]
            else:
                res = res + " = %s & "%x[i]
        res = res[0:len(res)-3]
        return res


# Convert a B-sentence to a set of labels.
# It is an anti-function of "label_to_sentence(x)".
def sentence_to_label(x):
    if x == "TRUE":
        return []
    else:
        res = []
        y = x.split(' & ')
        for item in y:
            vs = item.split(' = ')
            res = res + vs
        return res

# Process state labels (a dot label --> a set of state labels):
def proc_state_label(x):
    if x != None:
        y = "" + x
        y = y.replace('\|-\>',' , ')
        y = y.replace('\\n',' ')
        y = y.replace('\\{',' { ')
        y = y.replace('\\}',' } ')
        y = y.replace('"','')
        y = y.replace("'","")
        y = y.replace('=','')
        y = y.replace(',',' ')
        y = y.replace('\\',' ')
    else:
        y = 'None'

    y = y.split()
    y = merge_set_label(y)

    return y

# Merge set labels:
def merge_set_label(y):
    i = 0
    maxlen = len(y)
    res = []
    while i < maxlen:
        if y[i] == '{':
            flag = 1
            j = i + 1
            sval = '{ '
            while flag > 0:
                if y[j] == '{':
                    flag = flag + 1
                    sval = sval + '{ '
                elif y[j] == '}':
                    flag = flag - 1
                    sval = sval + '}, '
                else:
                    sval = sval + y[j] + ' , '
                j = j + 1
            sval = sval.replace(', }',' }')
            sval = sval[0:len(sval)-2] 
            res.append(''.join(sval))
            
            i = j
        else:
            res.append(y[i])
            i = i + 1
    return res
"""
# Compute MaxLabelLength.
maxlabellength = 0;
qq = pp.get_edge_list()
for i in xrange(len(qq)):
    x = qq[i].get_source()
    if x == 'root':
        edge_src = -1
    else:
        edge_src = int(x)
    edge_dest = int(qq[i].get_destination())
    y = qq[i].get_label()
    if y != None:
        y = y.replace('"','')
        y = y.replace("'","")
    else:
        y = 'None'
    if len(y) > maxlabellength:
        maxlabellength = len(y)

cfile.write("%d "%maxlabellength)

# Compute NumVble and MaxVbleLength.
numvble = 0;
maxvblelength = 0;
qq = pp.get_node_list()
for i in xrange(len(qq)):
    x = qq[i].get_name()
    if x == 'root':
        node_idx = -1
    elif x == 'graph':
        node_idx = -2
    else:
        node_idx = int(x)
    y = qq[i].get_label()
    y = proc_state_label(y)
    if len(y)/2 > numvble:
        numvble = len(y)/2

    for j in xrange(len(y)):
        if j % 2 == 0:
            if len(y[j]) > maxvblelength:
                maxvblelength = len(y[j])
cfile.write("%d %d\n"%(numvble,maxvblelength))


qq = pp.get_edge_list()
for i in xrange(len(qq)):
    x = qq[i].get_source()
    if x == 'root':
        edge_src = -1
    else:
        edge_src = int(x)
    edge_dest = int(qq[i].get_destination())
    y = qq[i].get_label()
    if y != None:
        y = y.replace('"','')
        y = y.replace("'","")
    else:
        y = 'None'


    cfile.write("%d %d %s\n"%(edge_src,edge_dest,y))


qq = pp.get_node_list()
for i in xrange(len(qq)):
    x = qq[i].get_name()
    if x == 'root':
        node_idx = -1
    elif x == 'graph':
        node_idx = -2
    else:
        node_idx = int(x)
    y = qq[i].get_label()
    y = proc_state_label(y)
    cfile.write("%d %d"%(node_idx,len(y)/2))
    for j in xrange(len(y)):
        if j % 2 == 1:
            try:
                t = int(y[j])
                cfile.write(" %d"%t)
            except ValueError:
                cfile.write(" %s"%y[j])
        else:
            
            cfile.write(" %s"%y[j])
    cfile.write("\n")


    # If the number of input parameters is 2, then skip the generation of isolation components and faulty states.
    if len(sys.argv) == 3:
        continue


    # Output isolation component:


    if qq[i].get_shape() == "doubleoctagon":
        x = qq[i].get_name()
        rr = pp.get_edge_list()
        for k in xrange(len(rr)):
            q = rr[k].get_destination()
            if q == x:
                p = rr[k].get_source()
                for u in xrange(len(qq)):
                    if qq[u].get_name() == p:
                        break
                break
        y = qq[u].get_label()
        y = proc_state_label(y)
        print y

        negstr = "[negation,pos(0,0,0,0,0,0),"
        conjstr = "[conjunct,pos(0,0,0,0,0,0),"
        equstr = "[equal,pos(0,0,0,0,0,0),"
        idenstr = "[identifier,pos(0,0,0,0,0,0),"
        intstr = "[integer,pos(0,0,0,0,0,0),"

        initstr = "initialisation(pos(0,0,0,0,0,0),sequence(pos(0,0,0,0,0,0),["
        assstr = "assign(pos(0,0,0,0,0,0),[identifier(pos(0,0,0,0,0,0),"

        resstr = ""
        init_resstr = ""

        for j in xrange(len(y)):
            
            if j % 2 == 1:
                try:
                    t = int(y[j])
                    tmpstr = tmpstr + intstr + "%d]]"%t
                    init_tmpstr = init_tmpstr + "[integer(pos(0,0,0,0,0,0),%d)])"%t
                except ValueError:
                    if y[j] == "TRUE":
                        t = "[boolean_true,pos(0,0,0,0,0,0)]]"
                        init_t = "[boolean_true(pos(0,0,0,0,0,0))])"
                    elif y[j] == "FALSE":
                        t = "[boolean_false,pos(0,0,0,0,0,0)]]"
                        init_t = "[boolean_false(pos(0,0,0,0,0,0))])"
                    else:
                        print ("Warning: Cannot analyse %s!"%y[j])
                        t = "%s-Error!"%y[j]
                        init_t = "%s-Error!"%y[j]
                    tmpstr = tmpstr + "%s"%t
                    init_tmpstr = init_tmpstr + "%s"%init_t
            else:
                tmpstr = equstr + idenstr + "%s],"%y[j]
                init_tmpstr = assstr + "%s)],"%y[j]
            if j >= 3 and j % 2 == 1:
                resstr = conjstr + resstr + "," + tmpstr + "]"
                init_resstr = init_resstr + "," + init_tmpstr
            elif j == 1:
                resstr = tmpstr
                init_resstr = init_tmpstr

        resstr = negstr + resstr + "]."
        init_resstr = initstr + init_resstr + "]))."

        print "Print the isolation component to: ", sys.argv[3]
        isocompfile = open(sys.argv[3],'w')
        print(resstr)
        isocompfile.write(resstr)

        print "Print the initialisation form of the isolation component to: ", sys.argv[3]
        isocompfile = open(sys.argv[3] + ".init",'w')
        print(init_resstr)
        isocompfile.write(init_resstr)



    # Output the faulty state:


    if qq[i].get_shape() == "doubleoctagon":
        x = qq[i].get_name()
        y = qq[i].get_label()
        y = proc_state_label(y)

        print "The faulty state is", y
        print "Print the faulty state to: ", sys.argv[4]
        fsfile = open(sys.argv[4],'w')
        for j in xrange(len(y)):
            fsfile.write(y[j] + '\n')

cfile.close()

if len(sys.argv) == 5:
    isocompfile.close()
    fsfile.close()
"""
"""
import os
from graphviz import Source
spfile = open('statespace.txt', 'r')
text=spfile.read()
print text[4]
Source(text)
#print text
"""
