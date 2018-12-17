function MyTable = json2table( serieArray, par )
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

% Skip empty serie
serieArray    = shiftdim(serieArray,1); % meaningful after the (:)
%integrity_ser = ~cellfun(@isempty,serieArray.getPath);
serieArray    = serieArray(:);
%integrity_ser = integrity_ser(:);
%serieArray    = serieArray(integrity_ser==1);

jsonArray = serieArray.getJson(par.regex,par.type,par.verbose);

% Skip empty jsons
integrity = ~cellfun(@isempty,jsonArray.getPath);
jsonArray = jsonArray(:);
integrity = integrity(:);
jsonArray = jsonArray(integrity==1);


%% Read sequence parameters + first level fields

data_cellArray = jsonArray.readSeqParam(par);


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
    d = setxor(list,f); % non-commin fields
    for dm = 1 : length(d)
        data_cellArray{i}.(d{dm}) = NaN; % create the missing field
    end
    data_cellArray{i} = orderfields(data_cellArray{i}, list); % fields need to be in the same order for conversion
end


%% Transform the cell of struct to array of struct, then into a table

data_structArray = cell2mat(data_cellArray); % cell array of struct cannot be converted to table
data_structArray = reshape( data_structArray, [numel(data_structArray) 1]); % reshape into single row structArray

MyTable = struct2table( data_structArray, 'AsArray', 1 );

if par.add_empty_line
    index    = 1:length(integrity);
    indexok  = index(integrity==1);
    indexbad = index(integrity==0);
    padding  = num2str(length(num2str(length(index))));
    MyTable.Properties.RowNames = cellstr(strsplit(num2str(indexok,[' %.' padding 'd'])));
    if ~isempty(indexbad)
        Table_missing = MyTable(1,:);
        for nbcol=1:width(MyTable)
            if iscell(MyTable(1,:).(MyTable.Properties.VariableNames{nbcol}))
                Table_missing{1,nbcol}={''};
            else
                Table_missing{1,nbcol}=NaN;
            end
        end
        Table_missing = repmat(Table_missing,[length(indexbad),1]);
        Table_missing.Properties.RowNames = cellstr(strsplit(num2str(indexbad,[' %.' padding 'd'])));
        
        MyTable = [MyTable;Table_missing]; %need to have the same datatype for each collumn
        MyTable = sortrows(MyTable,'RowNames');
    end
end


%% Use the serie.path as RowNames for the Table

id_str = serieArray.getPath;
id_str = id_str(:); % in column

integrity_ser = cellfun(@isempty,id_str);integrity_ser=find(integrity_ser);
for ii =1:length(integrity_ser)
    id_str{integrity_ser(ii)} =  serieArray(integrity_ser(ii)).exam.path; end


split_raw = regexp(id_str,filesep,'split'); % split the path around '/'
for e = 1 : length(split_raw)
    split_nice(e,1:length(split_raw{e})) = split_raw{e}; %#ok<AGROW>
end

% First and last one are always empty
split_nice(:,1)   = [];
split_nice(:,end) = [];

% Which part of the path is not common ?
for col = 1 : size(split_nice,2)
    if length(unique(split_nice(:,col))) > 1
        break
    end
end

% Concatenate the non-common parts of the path
aa=split_nice(:,col:end);
iaa=cellfun(@isempty,aa); aa(iaa)={'None'}; %because empty series are getting exam path or serie path of different level
split_final = fullfile(aa); % only the non-common part of the path
id_str = repmat({''},[ size(split_final,1) 1 ]);
for c = 1 : size(split_final,2)
    if c == 1
        id_str = strcat(id_str,split_final(:,c));
    else
        id_str = strcat(id_str,filesep,split_final(:,c));
    end
end

MyTable = [id_str MyTable];
MyTable.Properties.VariableNames{1} = 'path'; % column name


end % function
