function plotCountSeries( examArray, serie_regex )
%PLOTCOUNTSERIES shows graphically the output of examArray.countSeries
% regex : allow you to select series with regexp

if nargin < 2
    serie_regex = '.*';
end


%% Count the series

T = examArray.countSeries( serie_regex );


%% Prepare the color for each count

vectHTML = cell(length(T.Properties.RowNames),length(T.Properties.VariableNames));

for c = 1 : length(T.Properties.VariableNames)
    
    % Vector : number of series in each exam
    countOfSerie = T.(T.Properties.VariableNames{c}); % [0 0 1 1 1 1 2 1 1 1 1 2 1 1 6 1 1 1 2 1]
    
    % Get their unique
    uniqueNrSerie = unique(countOfSerie); % [0 1 2 6]
    
    if length(uniqueNrSerie) > 1
        
        histNrSerie = hist(countOfSerie,uniqueNrSerie); % [ 2(x0) 14(x1) 3(x2) 6(x1) ]
        
        [~,maxNrSerie] = max(histNrSerie); % where is max in [2 14 3 6] ? in slot #2
        
        n = length(uniqueNrSerie);
        
        nrDown = maxNrSerie - 1; % 1 slot bellow from 14
        nrUp   = n - maxNrSerie; % 2 slots upper from 14
        nrMax  = max(nrUp,nrDown);
        
        % Fill a balanced count of series
        balancedNrSerie = nan(nrMax*2+1,1); % [Nan 0 1 2 6] => the maxCount is in the middle
        if nrDown < nrUp
            balancedNrSerie(end-n+1:end) = uniqueNrSerie;
        elseif nrUp < nrDown
            balancedNrSerie(1:n) = uniqueNrSerie;
        else
            balancedNrSerie = uniqueNrSerie;
        end
        
    else
        balancedNrSerie = uniqueNrSerie;
        
    end
    
    if length(balancedNrSerie) == 1
        colorRGB = parula(3);
        colorRGB = colorRGB(2,:);
    else
        colorRGB = parula(length(balancedNrSerie));
    end
    
    for v = 1 : length(countOfSerie)
        vectHTML{v,c} = color2html( colorRGB(balancedNrSerie==countOfSerie(v),:), countOfSerie(v) );
    end
    
end


%% Plot

f=figure();

t = uitable(f,...
    'UserData',examArray,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'RowStriping','off',...
    'CellSelectionCallback',@CellSelectionCallback);

t.ColumnName = T.Properties.VariableNames;
t.RowName    = T.Properties.RowNames;

t.Data = vectHTML;


end % function

%--------------------------------------------------------------------------
function str = color2html( rgb, value )
% Transform [R G B] = [0-1 0-1 0-1] into hexadecimal #rrggbb ,
% then add it into an html code, with the corresponding value

s = cellstr(dec2hex(round(rgb*255)))';

color = sprintf('#%s%s%s',s{:});

str = ['<html>< <table bgcolor=',color,'>',num2str(value),'</table></html>'];

end % function

%--------------------------------------------------------------------------
function CellSelectionCallback(src,event)

examArray = src.UserData;

x = event.Indices(1); % line
y = event.Indices(2); % column

if y > 1 % x==1 is 'NrExams'
    
    last_exam  = examArray.getExam(src.RowName{x});
    last_serie = last_exam.getSerie(src.ColumnName{y});
    
    fprintf('Serie selected, sent to base workspace as ''last_serie'', and exam as ''last_exam'': \n')
    disp(last_exam )
    disp(last_serie)
    assignin('base','last_exam' ,last_exam )
    assignin('base','last_serie',last_serie)
    fprintf('\n')
    
end

end % function
