function varargout = countSeries( examArray )
% COUNTSERIES more compact than explore, but only display the number of series

% Initialization
nick = {examArray(1).serie.nick};
nick = unique(nick);
nick(cellfun(@isempty,nick)) = []; % remove empty tags
out = zeros( numel(examArray), numel(nick));

for ex = 1 : numel(examArray)
    
    exam_tags  = {examArray(ex).serie.tag };
    exam_nicks = unique({examArray(ex).serie.nick});
    
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
        N = sum ( ~cellfun( @isempty, regexp(exam_tags,nick{n}) ) );
        out(ex,n) = N;
    end
    
end

% Convert the num array to a table
out = array2table(out);
out.Properties.RowNames      = {examArray.name};
out.Properties.VariableNames = nick;

if nargout > 0
    varargout{1} = out;
else
    disp(out)
end

end % end
