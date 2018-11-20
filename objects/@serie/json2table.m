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
defpar.regex      = 'j';
defpar.type       = 'tag';

% get_sequence_param_from_json
defpar.pct  = 0;
defpar.redo = 0;
defpar.add_empty_line=1;

par = complet_struct(par,defpar);


%% Fetch json objects

jsonArray = serieArray.getJson(par.regex,par.type,par.verbose);

% Skip empty jsons
integrity = ~cellfun(@isempty,jsonArray.getPath);
jsonArray = jsonArray(:);
integrity = integrity(:);
jsonArray = jsonArray(integrity==1);


%% Read sequence parameters + first level fields

data_cellArray = jsonArray.readSeqParam(par.redo, par);


%% In case of multiple json (ex: multi-echo), combine the content as vector

for d = 1 : numel(data_cellArray)
    if numel(data_cellArray{d}) > 1
        fields = fieldnames(data_cellArray{d});
        new_data = struct;
        for f = 1 : numel(fields)
            switch class(data_cellArray{d}(1).(fields{f}))
                case 'double'
                    new_data.(fields{f}) = [data_cellArray{d}.(fields{f})];
                case 'char'
                    new_data.(fields{f}) = char({data_cellArray{d}.(fields{f})});
                case 'cell'
                    new_data.(fields{f}) = {data_cellArray{d}.(fields{f})};
                otherwise
                    new_data.(fields{f}) = {data_cellArray{d}.(fields{f})};
            end
        end
        data_cellArray{d} = new_data;
    end
end


%% In case of different fields, fill the empty ones with NaN

N = numel(data_cellArray);

% Print all fields name inside a cell, for comparaison
names = cell( N, 0 );
for i = 1 : N
    fields = fieldnames(data_cellArray{i});
    ncol = length(fields);
    names(i,1:ncol) = fields;
end

% Fortmat the cell of fieldnames and only keep the unique ones
names = names(:); % change from 2d to 1d
names( cellfun(@isempty,names) ) = []; % remove empty
list = unique(names,'stable');

% Compare current structure fields with the definitive 'list' of fields
for i = 1 : N
    f = fieldnames(data_cellArray{i});
    d = setxor(fields,f); % non-commin fields
    for dm = 1 : length(d)
        data_cellArray{i}.(d{dm}) = NaN; % create the missing field
        data_cellArray{i} = orderfields(data_cellArray{i}, list); % fields need to be in the same order for conversion
    end
end


%% Transform the cell of struct to array of struct, then into a table

data_structArray = cell2mat(data_cellArray); % cell array of struct cannot be converted to table
data_structArray = reshape( data_structArray, [numel(data_structArray) 1]); % reshape into single row structArray

Table = struct2table( data_structArray );

if par.add_empty_line
    index = 1:length(integrity);
    indexok = index(integrity==1);
    indexbad = index(integrity==0);
    
    Table.Properties.RowNames = cellstr(strsplit(num2str(indexok,' %.5d')));
    
    Table_missing = Table(1,:);
    for nbcol=1:width(Table)
        if iscell(Table(1,:).(Table.Properties.VariableNames{nbcol}))
            Table_missing{1,nbcol}={''};
        else
            Table_missing{1,nbcol}=NaN;
        end
    end
    Table_missing = repmat(Table_missing,[length(indexbad),1]);
    Table_missing.Properties.RowNames = cellstr(strsplit(num2str(indexbad,' %.5d')));    
    
    Table = [Table;Table_missing]; %need to have the same datatype for each collumn
    Table = sortrows(Table,'RowNames');
    
end

if par.add_empty_line
    examArray = [serieArray.exam]; %include empty series
else
    examArray = [jsonArray.exam];
end

exam_name1 = {examArray.name}';
if length(unique(exam_name1)) == length(exam_name1) % easy method, use exam.anem
    Table.Properties.RowNames = exam_name1; % RowNames
    
else % harder method, use exam.path but crop it
    exam_name3 = examArray.print;
    c = 0;
    % Remove beguining of the path when it's common to all
    while 1
        c = c + 1;
        line = exam_name3(:,c);
        if length(unique(line))>1
            break
        end
    end
    exam_name3 = cellstr(exam_name3(:,c:end));
    Table.Properties.RowNames = exam_name3; % RowNames
    
end


end % function
