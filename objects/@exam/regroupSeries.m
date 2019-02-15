function varargout = regroupSeries( examArray, par )
% REGROUPSERIES similar from countSeries, but using sequence paramters instead of the serie.tag
%
% Syntax : [Table, Group] = examArray.regroupSeries(par)
%          [Table, Group] = examArray.regroupSeries
%                           examArray.regroupSeries(par)
%                           examArray.regroupSeries
%
% Notes : accepted list of parameters comes from serie.seq2str method
%


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

defpar.serie_regex = '.*';
defpar.param_list  = '';   % use default list from seq2str

par = complet_struct(par,defpar);


%% Count the series

% Fetch sequence parameters
serieArray                                          = examArray.getSerie(par.serie_regex,'tag',0);
[seq_param_str, seq_param_struct, requested_param ] = serieArray.seq2str(par.param_list); %#ok<ASGLU>
nick                                                = reshape({serieArray.nick},size(serieArray));

% Concat : id = seqeunce.nick + seq_param_str
id = strcat(nick,':',seq_param_str);
id(~cellfun(@isempty,regexp(id,'^\s?:\s?$'))) = {''};

% Initialize, with the firt exam
param_str = id(1,:);
param_str = unique(param_str);
param_str(cellfun(@isempty,param_str)) = []; % remove empty tags
NrSerie   = zeros( numel(examArray), numel(param_str));

% Count the series, using the 'nick' (initial tag, no increment)
for ex = 1 : numel(examArray)
    
    serie_param        = id(ex,:);
    serie_unique_param = unique(serie_param);
    
    % addSerie, when tags are not found, adds an empty serie (for diagnostic purpose)
    % empty serie means serie WITH tag, and WITHOUT nick
    % but in this partical regroupSeries function, we count the tags
    % so here we need an exeption to discard the exams with only empty series
    if isempty(char(serie_param))
        continue
    end
    
    param_str = unique([param_str(:)' serie_unique_param],'stable'); % concatenate previous nicks and new nicks, and keep only unique ones in the same order
    
    param_str(cellfun(@isempty,param_str)) = [];             % remove empty tags
    
    for n = 1 : length(param_str)
        found_tags_idx = ~cellfun( @isempty, regexp(serie_param,param_str{n}) );
        N = sum( found_tags_idx );
        NrSerie(ex,n) = N;
    end
    
end


%% Reorder : alphabetical

[param_str,nick_order] = sort(param_str);
NrSerie = NrSerie(:,nick_order);


%% Make groups according to NrSeries

ExamName = matlab.lang.makeUniqueStrings({examArray.name}');

[~,IA,IC] = unique(NrSerie,'rows');

Group = struct;

for i = 1 : length(IA)
    Group(i).idx   = i==IC;
    Group(i).array = NrSerie(Group(i).idx,:);
    Group(i).name  = ExamName(Group(i).idx);
    Group(i).N     = size(Group(i).array,1);
    Group(i).Nrep  = repmat(Group(i).N,[Group(i).N,1]);
    
    Group(i).param_str = param_str(logical(Group(i).array(1,:)))';
    
    idx_array = find(Group(i).array(1,:));
    if isempty(idx_array)
        Group(i).table = table; % empty table
    else
        clear tmp_struct
        found_nick = cell(size(idx_array));
        for seq_idx = 1 : length(idx_array)
            found_idx = strcmp(Group(i).param_str{seq_idx}, id);
            found_idx = find(found_idx);
            found_idx = found_idx(1);
            tmp_struct(seq_idx) = complet_struct( struct('N',Group(i).array(1,idx_array(seq_idx))), seq_param_struct{found_idx}); %#ok<AGROW>
            found_nick{seq_idx} = nick{found_idx};
        end
        Group(i).table = struct2table(tmp_struct,'AsArray',1,'RowNames',matlab.lang.makeUniqueStrings(found_nick));
    end
    
end

% Finaly
[ ~ , order ]   = sort( [Group.N] );
Group           = Group(order);
OrderedNrSerie  = [cat(1,Group.Nrep) cat(1,Group.array)];
OrederdExamName = cat(1,Group.name);


%% Fetch serie nick, to use it as row name

nick = nick(:);
id   = id(:); % same dimension

final_nick = cell(size(param_str));
for p = 1 : length(param_str)
    res = strcmp(param_str{p},id);
    assert(~isempty(res))
    final_nick{p} = nick{find(res,1)};
end
final_nick = matlab.lang.makeUniqueStrings(final_nick);


%% Convert the num array to a table

Table                          = array2table(OrderedNrSerie);
Table.Properties.RowNames      = OrederdExamName;
Table.Properties.VariableNames = [ {'NrExam'} final_nick ];


%% Output

if nargout > 0
    varargout{1} = Table;
    varargout{2} = Group;
else
    disp(Table)
end


end % end
