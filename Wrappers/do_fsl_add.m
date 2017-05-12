function [out job] = do_fsl_add(fos,outnames,par)
%function out = do_fsl_add(fo,outname)
%fo is either a cell or a matrix of char
%outname is the name of the fo volumes sum
%


if ~exist('par'),par ='';end

defpar.sge=0;
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'fslmerge';
defpar.checkorient=1;

par = complet_struct(par,defpar);

if iscell(outnames)
    if length(fos)~=length(outnames)
        error('the 2 cell input must have the same lenght')
    end
else
    outnames = {outnames};    
    fos = {char(fos)}; % just to be sure : one cell of all volume to be summed
end

for ns=1:length(outnames)
    
    fo = cellstr(char(fos(ns)));
    outname = outnames{ns};
    
    fo = cellstr(char(fo));
    
    delete_tmp=[];
    
    if par.checkorient
        for k=2:length(fo)
            if compare_orientation(fo(1),fo(k)) == 0
                fprintf('\ndifferent orientation do reslice\n')
                ppp.outfilename = {tempname};
                
                fo(k) = do_fsl_reslice(fo(k),fo(1),ppp);
                delete_tmp=[delete_tmp k];
                %error('volume %s and %s have different orientation or dimension',fo{1},fo{k})
                %return
            end
        end
    end
    
    cmd = sprintf('fslmaths %s',fo{1});
    
    for k=2:length(fo)
        cmd = sprintf('%s -add %s',cmd,fo{k});
    end
    
    cmd = sprintf('%s %s',cmd,outname);
    
    %fprintf('writing %s \n',outname)
    job{ns} = cmd;
    out{ns} = [outname '.nii.gz'];
end
do_cmd_sge(job,par);


if ~isempty(delete_tmp)
    do_delete(fo(delete_tmp),0)
end


