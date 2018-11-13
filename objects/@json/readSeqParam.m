function data = readSeqParam( jsonArray, varargin )
%READSEQPARAM
% Important : for more details about the parameters, see also get_sequence_param_from_json

path = jsonArray.getPath;

data = get_sequence_param_from_json(path,varargin{:});

end % function
