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


defpar.sge=0;
defpar.jobname = 'antsNL';
defpar.walltime = '02:00:00';
defpar.prefix = 'aw_';
defpar.mask = '';
defpar.method = 'default'; %affine smooth, default, precise, large
defpar.noaffine = 0;
defpar.dorigid = 0;
defpar.refmask='';
defpar.reslice = 1;
defpar.interp = 2; % 1 : Nearest Neighbor  |  2 : 3rd order B-Spline Interpolation

par = complet_struct(par,defpar);

switch par.method
    
    case 'smooth'
        metric='MI['; metric2 = ',1,32]';         regul='Gauss[3,1]';        ttype='SyN[0.25]';        iters='10x50x20x0';
    case 'precise'
        metric='MI['; metric2 = ',1,32]';        regul='Gauss[3,0]';        ttype='SyN[0.25]';        iters='10x50x50x20';
    case 'elastic'
        metric='MI['; metric2 = ',1,32]';        regul='Gauss[0.5,3]';        ttype='Elast[1.5]';        iters='30x20x10';
    case 'exp'
        metric='MI['; metric2 = ',1,32]';        regul='Gauss[0.5,3]';        ttype='Exp[0.25,10]';        iters='30x20x10';
    case 'large'
        metric='CC['; metric2 = ',1,4]';        regul='Gauss[3,0]';        ttype='SyN[0.25]';        iters='100x100x100x20';
    case 'default'
        metric='CC['; metric2 = ',1,2]';        regul='Gauss[3,0]';        ttype='SyN[0.25]';        iters='10x50x50x20';
    case 'affine'
        metric='CC['; metric2 = ',1,2]';        regul='Gauss[3,0]';        ttype='SyN[0.25]';        iters='0x0x0x0';
        
end

[ppmov fname_mov ] = get_parent_path(fmov); fname_mov = change_file_extension(fname_mov,'');
[pp fname_ref ] = get_parent_path(fref); fname_ref = change_file_extension(fname_ref,'');

fo = addprefixtofilenames(fmov,par.prefix);

for k=1:length(fmov)
    
    transform = fullfile(ppmov{k},sprintf('%s%s_to_%s',par.prefix,fname_mov{k},fname_ref{k}));
    
    metricstr = sprintf('%s%s,%s%s',metric,fref{k},fmov{k},metric2);
    
    cmd = sprintf('ANTS 3 -m %s -o %s -i %s -t %s -r %s --use-Histogram-Matching --affine-metric-type MI -v --MI-option 32x16000 ',metricstr,transform,iters,ttype,regul);
    
    if par.noaffine
        cmd = sprintf('%s --number-of-affine-iterations  0x0x0',cmd);
    else
        cmd = sprintf('%s --number-of-affine-iterations 10000x10000x10000',cmd);
    end
    
    if par.dorigid
        cmd = sprintf('%s --do-rigid',cmd);
    end
    
    if ~isempty(par.refmask)
        cmd = sprintf('%s -x %s',cmd,par.refmask{k});
    end
    
    if par.reslice %apply the transform
        cmd = sprintf('%s\n WarpImageMultiTransform 3 %s %s -R %s',cmd,fmov{k},fo{k},fref{k});
        switch par.interp
            case 1
                cmd = sprintf('%s --use-NN',cmd);
            case 2
                cmd = sprintf('%s --use-BSpline',cmd);
        end
        if strcmp(par.method,'affine')
            cmd = sprintf('%s %sAffine.txt',cmd,transform);
        else
            cmd = sprintf('%s %sWarp.nii.gz %sAffine.txt',cmd,transform,transform);
        end
        
    end
    
    job{k} = cmd;
end

do_cmd_sge(job,par)