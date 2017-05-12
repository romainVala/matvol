function ants_warp(fmov,fref,par)
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


defpar.sge=1;
defpar.jobname = 'antsNL';
defpar.walltime = '12:00:00';
defpar.prefix = 'aw_';
defpar.mask = '';
defpar.method = 's'; %   r: rigid        a: rigid + affine        s: rigid + affine + deformable syn
                     %    b: rigid + affine + deformable b-spline syn
defpar.histo = 0;
defpar.nb_thread = 1;

par = complet_struct(par,defpar);

if length(fref)==1
    fref = repmat(fref,size(fmov));
end



[ppmov fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');
[pp fname_ref ] = get_parent_path(fref); fname_ref = change_file_extension(fname_ref,'');


for k=1:length(fmov)
    
    transform = fullfile(ppmov{k},sprintf('%s%s_to_%s',par.prefix,fname_mov{k},fname_ref{k}));
        
    cmd = sprintf('antsRegistrationSynrr.sh -d 3 -f %s -m %s -o %s -t %s',fref{k},fmov{k},transform,par.method);
    cmd = sprintf('%s -n %d',cmd,par.nb_thread);
    if par.histo
        cmd = sprintf('%s -j 1',cmd);
    end

    job{k} = cmd;
end

do_cmd_sge(job,par)