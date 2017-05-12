function fo = do_fsl_copy_header(fref,fchange)
%function fo = do_fsl_copy_header(fref,fchange)


if ~exist('par'),par ='';end

defpar.sge=0;
defpar.d=1; % if true : do not copy image dimensions
par = complet_struct(par,defpar);

job={};
for k=1:length(fref)
    ffchange = cellstr(char(fchange(k)));
    for kk=1:length(ffchange)
        cmd = sprintf('fslcpgeom %s %s',fref{k},ffchange{kk});
        if par.d
            cmd = sprintf('%s -d\n',cmd);
        else
            cmd = sprintf('%s \n',cmd);
        end
        
        job{end+1} = cmd;
    end
    
end

do_cmd_sge(job,par)


