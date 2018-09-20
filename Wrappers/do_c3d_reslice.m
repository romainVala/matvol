function [ fo, job ] = do_c3d_reslice(src,ref,par,jobappend) % prefix,interp_fsl)
%function fo = do_fsl_reslice(src,ref,prefix)
%if iscell(prefix) prefix is then the matrix output

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

%-interpolation <NearestNeighbor|Linear|Cubic|Sinc|Gaussian> [param]`
%
%Specifies the interpolation used with **-resample** and other commands. Default is **Linear**. Gaussian interpolation takes as the parameter the standard deviation of the Gaussian filter (e.g, 1mm). Gaussian interpolation is very similar in result to first smoothing an image with a Gaussian filter and then reslicing it with linear interpolation, but is more accurate and has less aliasing artifacts. It is also slower, and should only be used with small sigmas (a few voxels across).
%Shorthand 0 can be used for *NearestNeighbor*, 1 for *Linear* and 3 for *Cubic*. For example:
%    c3d -int 3 test.nii -resample 200x200x200% -o cubic_supersample.nii


defpar.prefix = 'rfsl_';
defpar.interpol = 'Linear'; %  <NearestNeighbor|Linear|Cubic|Sinc|Gaussian> [param]
defpar.trans_mat = '';
defpar.sge = 0;
defpar.jobname='c3d_reslice';
defpar.output_format = 'NIFTI_GZ';
defpar.outfilename='' ;

par = complet_struct(par,defpar);

prefix=par.prefix;

nbj=1;


if isempty(par.outfilename)
    fo = addprefixtofilenames(src,prefix);
else
    fo = par.outfilename;
end

switch par.output_format
    case 'NIFTI_GZ'
        fo=change_file_extension(fo,'.nii.gz');
end

for k=1:length(ref)
    ff = cellstr(src{k});
    ffo = cellstr(fo{k});
    
    for kk=1:length(ff)
        cmd = sprintf('c3d  %s %s -reslice-identity -o %s  -interpolation %s ',...
            ref{k},ff{kk},ffo{kk},par.interpol);
        
        job{nbj} = cmd;
        nbj=nbj+1;
    end
    
end


job = do_cmd_sge(job,par,jobappend);

end % function
