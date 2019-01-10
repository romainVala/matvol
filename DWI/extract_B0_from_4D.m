function [fo , job] = extract_B0_from_4D(fi_4D,par)

if ~exist('fi_4D'), fi_4D='';end

if ~exist('par'),  par=''; end

def_par.bval = 'bvals';
def_par.bvec = 'bvecs';

def_par.B0_prefix = 'meanB0_';
def_par.B04D_prefix = 'B0_4D';
def_par.do4D=0;
def_par.sge=0;

par = complet_struct(par,def_par);
par.jobname='extract_B0';


if nargin ==0 && nargout==1
    varargout{1} = par;
    return
end

if isfield(par,'fout')
    fo = par.fout;
else
    fo = addprefixtofilenames(fi_4D,par.B0_prefix);
end
if isfield(par,'fout4D')
    fo4D = par.fout4D;
else
    fo4D =  addprefixtofilenames(fi_4D,def_par.B04D_prefix);
end

dti_dir = get_parent_path(fi_4D);
if iscell(par.bval)
    fbval = par.bval;
    fbvec = par.bvec;
else
    
    fbvec = get_subdir_regex_files(dti_dir,par.bvec,1);
    fbval = get_subdir_regex_files(dti_dir,par.bval,1);
end
    
for k=1:length(fi_4D)
    %test if only one b0
    Bvals = load(fbval{k});
    if length(Bvals) == 1 %dwiextract does not work so just copy
        cmd{k} = sprintf('cp  %s %s \n',fi_4D{k},fo4D{k});
    else
        
        if par.do4D;
            cmd{k} = sprintf('dwiextract %s -bzero -fslgrad %s %s %s ;\n mrmath %s mean %s -axis 3\n',...
                fi_4D{k},fbvec{k},fbval{k},fo4D{k},fo4D{k},fo{k});
            
        else
            cmd{k} = sprintf('LD_LIBRARY_PATH=;dwiextract %s - -fslgrad %s %s -bzero | mrmath - mean %s -axis 3\n',...
                fi_4D{k},fbvec{k},fbval{k},fo{k});
        end
    end
end

job = do_cmd_sge(cmd,par);
