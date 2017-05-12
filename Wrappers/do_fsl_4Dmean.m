function out = do_fsl_4Dmean(fin,outname,par)
%function out = do_fsl_add(fin,outname)
%fin is either a cell or a matrix of char
%outname is the name of the fin volumes sum
%


if ~exist('par'),par ='';end
defpar.sge=0;
defpar.software = 'fsl'; %to set the path
defpar.software_version = 5; % 4 or 5 : fsl version
defpar.jobname = 'fslmean';
defpar.checkorient=1;

par = complet_struct(par,defpar);


out = outname;

fin  = cellstr(char(fin));
outname = cellstr(char(outname));

if length(fin)~=length(outname)
    error('the 2 cell input must have the same lenght')
end


for k=1:length(fin)
    
    cmd = sprintf('fslmaths %s -Tmean %s',fin{k},outname{k});
    
    fprintf('writing %s \n',outname{k})
    unix(cmd);
    
end


