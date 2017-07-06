function addSeriesRegex( examArray, regex, tags )

AssertIsExamArray(examArray);

for ex = 1 : numel(examArray)
    
    tags = cellstr(tags);
    
    nrSeries = length(examArray(ex).series);
    counter = 0;
    
    serieList  = get_subdir_regex( examArray(ex).path, regex );
    
    if ~isempty(serieList)
        for ser = 1 : length(serieList)
            counter = counter + 1;
            examArray(ex).series(nrSeries + counter) = serie(serieList{ser}, tags{ser},examArray(ex) ); %#ok<*AGROW>
        end
    else
        examArray(ex).series(end+1) = serie;
    end
    
end % exam

end % function
