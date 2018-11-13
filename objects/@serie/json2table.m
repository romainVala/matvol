function Table = json2table( serieArray, par )
% Syntax  : uses serie/readSeqParam then tansform into table
% Example : table = serieArray.json2table('json$');
%
% See also serie/getJson


%% Check inputs

if nargin < 2
    par = '';
end

defpar            = struct;

% common
defpar.verbose    = 1;

% getJson
defpar.regex      = 'json$';
defpar.type       = 'tag';

% get_sequence_param_from_json
defpar.pct        = 0;
defpar.all_fields = 2;

par = complet_struct(par,defpar);


%% Fetch json objects

jsonArray = serieArray.getJson(par.regex,par.type,par.verbose);


%% json2table from @serie

data_cellArray   = jsonArray.readSeqParam(par.all_fields,par.pct);
data_structArray = cell2mat(data_cellArray); % cell array of struct cannot be converted to table
data_structArray = reshape( data_structArray, [numel(data_structArray) 1]); % reshape into single row structArray
 
Table = struct2table( data_structArray );

examArray = [serieArray.exam];
Table.Properties.RowNames = {examArray.name}; % RowNames


end % function
