function  do_qualicati(fin,dout,par)

if ~exist('par'),par ='';end

defpar.jobname = 'qualicati';
defpar.repo = '/network/lustre/iss01/cenir/software/irm/brainvisa_src/casa_distro_new';
defpar.run_script = '/casa/src/qualicati/bug_fix/python/qualiCATI/Scripts/pipeline.py';
defpar.sge=1;

par = complet_struct(par,defpar);


cmd=repmat({},size(fin));

for k=1:length(fin)
    cmd{k} = sprintf('casa_distro -r %s run python %s -f %s %s\n',...
        par.repo,par.run_script,dout{k},fin{k});
end


do_cmd_sge(cmd,par);

