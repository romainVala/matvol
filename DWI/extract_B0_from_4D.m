function fo = extract_B0_from_4D(fi_4D,par)

if ~exist('fi_4D'), fi_4D='';end

if ~exist('par'),  par=''; end

def_par.bval = 'bvals';
def_par.bvec = 'bvecs';

def_par.B0_prefix = 'B0_mean_';
def_par.sge=0;

par = complet_struct(par,def_par);
par.jobname='extract_B0';


if nargin ==0 && nargout==1
    varargout{1} = par;
    return
end

fo = addprefixtofilenames(fi_4D,par.B0_prefix);

dti_dir = get_parent_path(fi_4D);
fbvec = get_subdir_regex_files(dti_dir,par.bvec,1);
fbval = get_subdir_regex_files(dti_dir,par.bval,1);


for k=1:length(fi_4D)
   cmd{k} = sprintf('dwiextract %s - -fslgrad %s %s -bzero | mrmath - mean %s -axis 3\n',...
       fi_4D{k},fbvec{k},fbval{k},fo{k});
 
end

do_cmd_sge(cmd,par)
