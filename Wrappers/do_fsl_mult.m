function [out, job] = do_fsl_mult(fos,outname,par)
%function out = do_fsl_mult(fo,outname)
%fo is either a cell or a matrix of char
%outname is the name of the fo volumes sum
%

%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if iscell(outname)
    if length(fos)~=length(outname)
        error('the 2 cell input must have the same lenght')
    end
    
else
    outname = {outname};
end


%% defpar

defpar.fsl_output_format = 'NIFTI';
defpar.sge               = 0;
defpar.jobname           = 'fsl_mult';
defpar.redo              = 0;

par = complet_struct(par,defpar);


%% Prepare Prepare command using fslmaths

skip = [];

for ns=1:length(outname)
    
    if ~par.redo   &&   exist(outname{ns},'file')
        skip = [skip ns]; %#ok<AGROW>
        fprintf('[%s]: skiping subj %d because %s exist \n',mfilename,ns,outname{ns});
    end
    
    fo = cellstr(char(fos(ns)));
    
    cmd = sprintf('\n export FSLOUTPUTTYPE=%s;\n fslmaths %s',par.fsl_output_format,fo{1});
    
    for k=2:length(fo)
        cmd = sprintf('%s -mul %s',cmd,fo{k});
    end
    
    cmd = sprintf('%s %s \n',cmd,outname{ns});
    
    %    fprintf('writing %s \n',outname)
    
    out{ns,1} = [outname{ns} '.nii.gz']; %#ok<AGROW>
    
    job(ns) = {cmd}; %#ok<AGROW>
    
end

% Skip the empty jobs
job(skip) = [];

if ~isempty(job)
    job = do_cmd_sge(job,par);
end

end % function
