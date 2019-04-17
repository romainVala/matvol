function [fo job] = nifti_reg(fmov,fref,par,jobappend)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil
%      moving: image that is going to be registered
%       reference: fixed images
%       transform: prefix of the transformation,suffixes will be added automatically
%
%       opts: dictionary to add different options to the registration
%       "dorigid" : True -> restrict the registration to rigid tranformations instead of affine
%       "verbose" : True -> verbose mode
%       "refmask" : <file> -> Include a mask of the reference image to drive the registration
%       "noaffine : True -> directly do non-linear registration (images should previously be registered


if ~exist('par','var'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end


defpar.sge=1;
defpar.jobname = 'nireg';
defpar.walltime = '12:00:00';
defpar.prefix = 'nr_';

defpar.do_affine = 1;
defpar.do_NL = 1;
defpar.mask = '';
defpar.nl_args = '' ; % mouse '-ln 4 -lp 2 -pad 0 --lncc -5 '; % crane -be 0.05 -sx -10
defpar.nl_aff_args ='';

defpar.nb_thread = 1;

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end

if ~isempty(par.mask)
    if length(par.mask)==1
        par.mask = repmat(par.mask,size(fmov));
    end
end

[ppmov fname_mov ] = get_parent_path(fmov); fname_mov_noex = change_file_extension(fname_mov,'');
[pp fname_ref ] = get_parent_path(fref); fname_ref = change_file_extension(fname_ref,'');


for k=1:length(fmov)
    %reg_f3d  -ln 4 -lp 3 -aff outputAffine.txt -res outputf3d_Result.nii -rmask ../../../template/dill_mask.nii --lncc -5 -pad 0

    transform = sprintf('%s%s_to_%s',par.prefix,fname_mov_noex{k},fname_ref{k});
    
    cmd = sprintf('cd %s\n',ppmov{k});
    
    fo{k} = fullfile(ppmov{k},[transform '.nii.gz']);
    
    if par.do_affine
        cmd = sprintf('%s reg_aladin -flo %s -ref %s ',cmd,fname_mov{k},fref{k});
        cmd = sprintf('%s %s ',cmd,par.nl_aff_args);
        cmd = sprintf('%s -aff aff_%s.txt -res aff_%s.nii.gz -omp %d \n',cmd,transform,transform,par.nb_thread);
    end
    
    if par.do_NL
        cmd = sprintf('%s reg_f3d -flo %s -ref  %s',cmd,fname_mov{k},fref{k});
        cmd = sprintf('%s %s ',cmd,par.nl_args);
        cmd = sprintf('%s -aff aff_%s.txt -res %s.nii.gz -cpp ycpp_%s.nii.gz -omp %d ',cmd,transform,transform,transform,par.nb_thread);
    end
    
    if ~isempty(par.mask)
        cmd = sprintf('%s -rmask %s ',cmd,par.mask{k})
    end    

    job{k} = sprintf('%s\n',cmd);
end

job = do_cmd_sge(job,par,jobappend);