function [out job] = do_fsl_mult(fos,outname,par)
%function out = do_fsl_mult(fo,outname)
%fo is either a cell or a matrix of char
%outname is the name of the fo volumes sum
%

if ~exist('par'),par ='';end

defpar.fsl_output_format = 'NIFTI';
defpar.sge=0;
defpar.jobname='fsl_mult';


par = complet_struct(par,defpar);


if iscell(outname)
    if length(fos)~=length(outname)
        error('the 2 cell input must have the same lenght')
    end
    
else
    outname = {outname};
end

for ns=1:length(outname)
    
    fo = cellstr(char(fos(ns)));
    
    cmd = sprintf('\n export FSLOUTPUTTYPE=%s;\n fslmaths %s',par.fsl_output_format,fo{1});
    
    for k=2:length(fo)
        cmd = sprintf('%s -mul %s',cmd,fo{k});
    end
    
    cmd = sprintf('%s %s \n',cmd,outname{ns});
    
%    fprintf('writing %s \n',outname)
    
    out{ns} = [outname{ns} '.nii.gz'];
    
    job(ns) = {cmd};
 
end

job = do_cmd_sge(job,par);
