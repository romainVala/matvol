function data = readSeqParam( jsonArray, redo, par )
%READSEQPARAM
% Important : for more details about the parameters, see also get_sequence_param_from_json

if ~exist('par','var')
    par = ''; % for defpar
end

defpar.pct = 0;% Parallel Computing Toolbox

par = complet_struct(par,defpar);


path = jsonArray.getPath;

% Skip if already done
if ~redo
    for j = 1 : numel(jsonArray)
        if numel(fieldnames(jsonArray(j).serie.sequence))
            path{j} = '';
        end
    end
end

data = get_sequence_param_from_json(path,par);

% Store or load the seq param in the serie
for j = 1 : numel(path)
    if isempty(path{j})
        data{j} = jsonArray(j).serie.sequence;
    else
        jsonArray(j).serie.sequence = data{j};
    end
end

end % function
