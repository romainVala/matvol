function data = readSeqParam( jsonArray, par )
%READSEQPARAM
% Important : for more details about the parameters, see also get_sequence_param_from_json


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

defpar.pct  = 0; % Parallel Computing Toolbox
defpar.redo = 0;

par = complet_struct(par,defpar);


%% Go

path = jsonArray.getPath;

% Skip if already done
for j = 1 : numel(jsonArray)
    
    if ~isempty(jsonArray(j).path) % json.path exists
        if ~par.redo   &&   numel(fieldnames(jsonArray(j).serie.sequence)) % already done ?
            path{j} = '';
        end
    else
        path{j} = ''; % no path ? then skip
    end
    
end

[pp ff ex] = fileparts(path{1});
if strcmp(ex,'.json')
    data = get_sequence_param_from_json(path,par);
elseif strcmp(ex,'.csv')
    data = read_res(path,par);
end

% Store or load the seq param in the serie
for j = 1 : numel(jsonArray)
    if ~isempty(jsonArray(j).path) % json.path exists
        if isempty(path{j}) % Use seq param already parsd, or empty struct
            data{j} = jsonArray(j).serie.sequence;
        else
            jsonArray(j).serie.sequence = data{j}; % save freshly parsed seq param
        end
    end
end


end % function
