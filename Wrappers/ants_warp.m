function job=ants_warp(fmov,fref,par)
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
defpar.do_rigid = 1;
defpar.do_affine = 1;
defpar.do_NL = 1;

defpar.ra_convergence ='[1000x500x250x100,1e-6,10]';
defpar.ra_shrink_factors = '12x8x4x2';
defpar.ra_smoothing_sigmas = '4x3x2x1vox'; 
defpar.ra_metric = 'MI';
defpar.ra_metricp = '1,32,Regular,0.25';

defpar.nl_convergence ='[100x100x70,1e-6,10]';
defpar.nl_shrink_factors = '10x6x4';
defpar.nl_smoothing_sigmas = '5x3x2vox'; 
defpar.nl_metric = 'CC';
defpar.nl_metricp = '1,5';
defpar.mask = '';
defpar.histo = 0;
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
    
    transform = sprintf('%s%s_to_%s',par.prefix,fname_mov_noex{k},fname_ref{k});
    
    cmd = sprintf('cd %s\n',ppmov{k});
    cmd = sprintf('%s export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=%d\n',cmd,par.nb_thread);
    
    cmd = sprintf('%s antsRegistration --dimensionality 3 --float 0 ',cmd);
    cmd = sprintf('%s --interpolation Linear --winsorize-image-intensities [0.005,0.995] ',cmd);
    cmd = sprintf('%s --output [y%s,%sWarped.nii.gz] ',cmd,transform,transform);
    cmd = sprintf('%s --use-histogram-matching %d ',cmd,par.histo);
    cmd = sprintf('%s --initial-moving-transform [%s,%s,1] ',cmd,fref{k},fname_mov{k});
    
    if ~isempty(par.mask)
        cmd = sprintf('%s -x [%s]',cmd,par.mask{k})
    end
    
    if par.do_rigid
        cmd = sprintf('%s --transform Rigid[0.1] ',cmd);
        cmd = sprintf('%s --metric %s[%s,%s,%s]',cmd,par.ra_metric,fref{k},fname_mov{k},par.ra_metricp);
        cmd = sprintf('%s --convergence %s --shrink-factors  %s --smoothing-sigmas %s ',cmd,par.ra_convergence,par.ra_shrink_factors,par.ra_smoothing_sigmas);
    end
 
    if par.do_affine
        cmd = sprintf('%s --transform Affine[0.1] ',cmd);
        cmd = sprintf('%s --metric %s[%s,%s,%s]',cmd,par.ra_metric,fref{k},fname_mov{k},par.ra_metricp);
        cmd = sprintf('%s --convergence %s --shrink-factors  %s --smoothing-sigmas %s ',cmd,par.ra_convergence,par.ra_shrink_factors,par.ra_smoothing_sigmas);
    end

    if par.do_NL
        cmd = sprintf('%s --transform SyN[0.1,3,0] ',cmd);
        cmd = sprintf('%s --metric %s[%s,%s,%s]',cmd,par.nl_metric,fref{k},fname_mov{k},par.nl_metricp);
        cmd = sprintf('%s --convergence %s --shrink-factors  %s --smoothing-sigmas %s ',cmd,par.nl_convergence,par.nl_shrink_factors,par.nl_smoothing_sigmas);

    end
    

    job{k} = cmd;
end

do_cmd_sge(job,par)