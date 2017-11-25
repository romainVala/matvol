function out = unzip_volume(in,par)
% UNZIP_VOLUME uses gunzip (linux) to unzip volumes if needed.
% If the target file is not zipped (do not have .gz extension), skip it.


% Ensure the inputs are cellstrings, to avoid dimensions problems
in = cellstr(char(in));

if ~exist('par','var'),par ='';end
defpar.sge=0;
defpar.jobname='zip';

par = complet_struct(par,defpar);

if isempty(in)
    return
end


ind_to_remove=[];
cmd = cell(size(f));
for i=1:length(f)
    
    if ~isempty(in{i}) && strcmp(in{i}(end-1:end),'gz')
        cmd{i} = sprintf('gunzip -f %s',in{i});
        out{i} = in{i}(1:end-3); %#ok<*AGROW>
        
    else
        out{i} = in{i};
        ind_to_remove(end+1)=i;
    end
    
end

cmd(ind_to_remove)=[];

if ~isempty(cmd)
    do_cmd_sge(cmd,par);
end

end % function
