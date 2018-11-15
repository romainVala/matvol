function data = readSeqParam( jsonArray, redo, pct )
%READSEQPARAM
% Important : for more details about the parameters, see also get_sequence_param_from_json

path = jsonArray.getPath;

% Skip if already done
if ~redo
    for j = 1 : numel(jsonArray)
        if ~isempty(jsonArray(j).serie.sequence)
            path{j} = '';
        end
    end
end

data = get_sequence_param_from_json(path,pct);

% Store or load the seq param in the serie
for j = 1 : numel(path)
    if isempty(path{j})
        data{j} = jsonArray(j).serie.sequence;
    else
        jsonArray(j).serie.sequence = data{j};
    end
end

end % function
