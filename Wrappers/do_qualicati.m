function  do_qualicati(fin,dout,par)

if ~exist('par'),par ='';end

defpar.jobname = 'qualicati';
defpar.sge=1;

par = complet_struct(par,defpar);


cmd=repmat({},size(fin));

for k=1:length(fin)
    cmd{k} = sprintf('casa_distro run python /casa/src/qualicati/bug_fix/python/qualiCATI/Scripts/pipeline.py -f %s %s\n',...
        dout{k},fin{k});
end


do_cmd_sge(cmd,par);

