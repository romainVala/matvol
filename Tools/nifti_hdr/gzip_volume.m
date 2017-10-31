function fo = gzip_volume(f,par)

if ~exist('par','var'),par ='';end
defpar.sge=0;
defpar.jobname='zip';

par = complet_struct(par,defpar);

if isempty(f)
    return
end

f = cellstr(char(f));

ind_to_remove=[];
cmd = cell(size(f));
for i=1:length(f)

  if ~strcmp(f{i}(end-1:end),'gz')
      
    cmd{i} = sprintf('gzip -f %s',f{i});

    fo{i} = [f{i} '.gz'];
    
  else
    fo{i} = f{i};
    ind_to_remove(end+1)=i;
  end
  
end

cmd(ind_to_remove)=[];

if ~isempty(cmd)
    do_cmd_sge(cmd,par);
end
