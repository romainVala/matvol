function out = unzip_volume(in,par)
% UNZIP_VOLUME uses gunzip (linux) to unzip volumes if needed.
% If the target file is not zipped (do not have .gz extension), skip it.


%% Check input paramerters

if ~exist('par','var'),par ='';end

defpar.sge     = 0;
defpar.jobname = 'zip';
defpar.pct     = 0; % Parallel Computing Toolbox

par = complet_struct(par,defpar);


% Ensure the inputs are cellstrings, to avoid dimensions problems
in = cellstr(char(in));


%% Prepare unzip command

if isempty(in)
    return
end

ind_to_remove=[];
cmd = cell(size(in));
for i=1:length(in)
    
    if ~isempty(in{i}) && strcmp(in{i}(end-1:end),'gz')
        cmd{i} = sprintf('gunzip -f %s',in{i});
        out{i,1} = in{i}(1:end-3); %#ok<*AGROW>
        
    else
        out{i,1} = in{i};
        ind_to_remove(end+1)=i;
    end
    
end

cmd(ind_to_remove)=[];


%% Execute unzip command

if ~isempty(cmd)
    do_cmd_sge(cmd,par);
end


end % function
