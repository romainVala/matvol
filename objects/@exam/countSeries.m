function varargout = countSeries( examArray, serie_regex )
% COUNTSERIES more compact than explore, but only display the number of series
% regex : allow you to select series with regexp
%
% Syntax : [Table, Group] = examArray.countSeries('regex_of_serie')
%          [Table, Group] = examArray.countSeries
%                           examArray.countSeries('regex_of_serie')
%                           examArray.countSeries
%

if nargin < 2
    serie_regex = '.*';
end


%% Count the series

% Initialize, with the firt exam
nick = {examArray(1).getSerie(serie_regex,'tag',0).nick};
nick = unique(nick);
nick(cellfun(@isempty,nick)) = []; % remove empty tags
NrSerie = zeros( numel(examArray), numel(nick));

% Count the series, using the 'nick' (initial tag, no increment)
for ex = 1 : numel(examArray)
    
    serieArray = examArray(ex).getSerie(serie_regex,'tag',0);
    
    exam_tags  = {serieArray.tag};
    exam_nicks = unique({serieArray.nick});
    exam_path  = {serieArray.path};
    valid_path = ~cellfun( @isempty, exam_path );
    
    % addSerie, when tags are not found, adds an empty serie (for diagnostic purpose)
    % empty serie means serie WITH tag, and WITHOUT nick
    % but in this partical countSeries function, we count the tags
    % so here we need an exeption to discard the exams with only empty series
    if isempty(char(exam_nicks))
        continue
    end
    
    nick = unique([nick(:)' exam_nicks],'stable'); % concatenate previous nicks and new nicks, and keep only unique ones in the same order
    nick(cellfun(@isempty,nick)) = [];             % remove empty tags
    
    for n = 1 : length(nick)
        found_tags_idx = ~cellfun( @isempty, regexp(exam_tags,nick{n}) );
        N = sum ( found_tags_idx & valid_path );
        NrSerie(ex,n) = N;
    end
    
end


%% Reorder : alphabetical

[nick,nick_order] = sort(nick);
NrSerie = NrSerie(:,nick_order);


%% Sort NrSerie matrix

ExamName = {examArray.name}';
idxkeep = non_unique( ExamName ); % non unique ? then add random chars in the end
while sum(idxkeep) > 0
    random_chars      = regexprep(cellstr(num2str(randi(9,[sum(idxkeep) 8]))),' ',''); % generate random numbers, and convert them into char
    ExamName(idxkeep) = strcat(ExamName(idxkeep),'_',random_chars);                    % concat name with random chars
    idxkeep           = non_unique( ExamName );                                        % update the measure of non-unique
end
for ex = 1 : numel(examArray)
    examArray(ex).name = ExamName{ex};
end
ExamName = {examArray.name}'; % now we have unique names

[~,IA,IC] = unique(NrSerie,'rows');

Group = struct;

for i = 1:length(IA)
    Group(i).idx   = i==IC;
    Group(i).array = NrSerie(Group(i).idx,:);
    Group(i).name  = ExamName(Group(i).idx);
    Group(i).N     = size(Group(i).array,1);
    Group(i).Nrep  = repmat(Group(i).N,[Group(i).N,1]);
end

[ ~ , order ]   = sort( [Group.N] );
Group           = Group(order);
OrderedNrSerie  = [cat(1,Group.Nrep) cat(1,Group.array)];
OrederdExamName = cat(1,Group.name);


%% Convert the num array to a table

Table                          = array2table(OrderedNrSerie);
Table.Properties.RowNames      = OrederdExamName;
Table.Properties.VariableNames = [ {'NrExam'} nick ];


%% Output

if nargout > 0
    varargout{1} = Table;
    varargout{2} = Group;
else
    disp(Table)
end


end % end

function idxkeep = non_unique( in )

[~,idxu,idxc] = unique(in);
[count, ~, idxcount] = histcounts(idxc,numel(idxu));
idxkeep = count(idxcount)>1;

end
