function job = do_fsl_dtifit(f4D_to_fit,par,jobappend)
%function job = do_fsl_dtifit(f4D_to_fit,par,jobappend)

if ~exist('f4D_to_fit')
    f4D_to_fit=get_subdir_regex_files();
end

if ~exist('par','var'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.sujname='';
defpar.bvec = 'bvec';
defpar.bval = 'bval';
defpar.mask = 'nodif_brain_mask';
%
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'dti_fit';
defpar.sge=0;
defpar.walltime      = '00:20';
%see also default params from do_cmd_sge

par = complet_struct(par,defpar);

par.bvec = get_file_from_same_dir(f4D_to_fit,par.bvec,1);
par.bval = get_file_from_same_dir(f4D_to_fit,par.bval,1);
par.mask  = get_file_from_same_dir(f4D_to_fit,par.mask,1);

if isempty(par.sujname)
    [p sujname] = get_parent_path(f4D_to_fit);
    par.sujname = change_file_extension(sujname,'');
end

par.sujname = add_same_file_path(f4D_to_fit,par.sujname);


for nbs=1:length(f4D_to_fit)
    cmd = sprintf('dtifit -k %s -o %s -m %s -r %s -b %s;\n',f4D_to_fit{nbs},par.sujname{nbs},...
        par.mask{nbs},par.bvec{nbs},par.bval{nbs});
    
    cmd = sprintf('%s \n fslmaths %s_FA -mul %s_V1 %s_FAcolor ',cmd,par.sujname{nbs},par.sujname{nbs},par.sujname{nbs})
    job{nbs} = cmd;
    
end

job = do_cmd_sge(job,par,jobappend)


function B = add_same_file_path(A,B)
%if first element of B is not a fullfile path
%add the dir path of A to the file name B 

if ischar(B) 
    B = repmat({B},size(A));
end

if strcmp(B{1},'/')
    return
else
    
    dir = get_parent_path(A);
    for k = 1:length(A)
        B{k} = fullfile(dir{k},B{k});
    end
end
