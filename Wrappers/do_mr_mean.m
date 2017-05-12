function out = do_mr_mean(fo,outname,par)
%compute the mean with mrcalc, warning all files load in memory

if ~exist('par'),par ='';end

defpar.sge=0;
defpar.nthreads = 10; 

%defpar

par = complet_struct(par,defpar);

if iscell(outname)
    if length(fo)~=length(outname)
        error('the 2 cell input must have the same lenght')
    end
    
    
    for k=1:length(outname)
        do_mr_mean(fo(k),outname{k},par);
    end
    return
end

%remove extention
[pp ff] = fileparts(outname);

fo = cellstr(char(fo));

[pp ffo]=get_parent_path(fo);
 
cmd = sprintf('cd %s;mrmath -nthreads %d ',pp{1},par.nthreads);

for k=1:length(fo)
    cmd = sprintf('%s ',cmd,fo{k});
end

cmd = sprintf('%s mean %s',cmd,outname);


job{1}=cmd;

do_cmd_sge(job,par);
