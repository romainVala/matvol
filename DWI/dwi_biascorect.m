function fo = dwi_biascorect(fi_4D,par)

if ~exist('fi_4D'), fi_4D='';end

if ~exist('par'),  par=''; end

def_par.bval = 'bvals';
def_par.bvec = 'bvecs';
def_par.mask = '';
def_par.method = 'ants'  % or fsl
def_par.prefix = 'm_';
def_par.sge=0;

%sur login1 faire 
% module load MRtrix3/no_gui_19_03_2018
% module load ANTs/2.2.0

par = complet_struct(par,def_par);
par.jobname='biascor';


if nargin ==0 && nargout==1
    varargout{1} = par;
    return
end

fo = addprefixtofilenames(fi_4D,par.prefix);

dti_dir = get_parent_path(fi_4D);
fbvec = get_subdir_regex_files(dti_dir,par.bvec,1);
fbval = get_subdir_regex_files(dti_dir,par.bval,1);


for k=1:length(fi_4D)
    cmd{k} = sprintf('dwibiascorrect ');
    
    if ~isempty(par.mask)
        cmd{k} = sprintf('%s -mask %s', cmd{k}, par.mask);
    end
    cmd{k} = sprintf('%s -%s -fslgrad %s %s  %s %s \n', cmd{k},...
        par.method,fbvec{k},fbval{k},fi_4D{k},fo{k});
    
end

do_cmd_sge(cmd,par)
