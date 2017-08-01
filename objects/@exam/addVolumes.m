function addVolumes( examArray, series_tag_regex, file_regex, tags)
% Syntax  : examArray.addVolumes( 'series_tag_regex', {'file_regex_1', 'file_regex_2', ...}, {'tag_1', 'tag_2', ...} );
% Example : examArray.addVolumes( 'run1'            , '^f.*nii'                            , 'f' );
% Example : examArray.addVolumes( 'run'             , {'^f.*nii', '^swrf.*nii'}            , {'f', 'swrf'} );

AssertIsExamArray(examArray);

for ex = 1 : numel(examArray)
    
    file_regex = cellstr(file_regex);
    tags       = cellstr(tags);
    assert( length(file_regex) == length(tags) , 'file_regex and tags must be the same size' )
    
    found = 0;
    
    for ser = 1 : length(examArray(ex).series)
        
        if ...
                ~isempty(examArray(ex).series(ser).tag) && ...                            % tag is present in the @serie ?
                ~isempty(regexp(examArray(ex).series(ser).tag, series_tag_regex, 'once')) % found a corresponding serie.tag to the regex ?
            
            found = 1;
            
            % Be sure to add new volumes to the volumeArray
            nrVolumes = length(examArray(ex).series(ser).volumes);
            counter = 0;
            
            for vol = 1 : length(file_regex)
                
                try
                volume_found = get_subdir_regex_files(examArray(ex).series(ser).path,file_regex{vol},struct('verbose',0,'wanted_number_of_file',1));
                counter = counter + 1;
                examArray(ex).series(ser).volumes(nrVolumes + counter) = volume(char(volume_found), tags{vol}, examArray(ex), examArray(ex).series(ser));
                
                catch
                    % When volumes are not found
                    warning([
                        'Could not find recursivly any dir corresponding to the regex [ %s ] \n'...
                        '#%d : %s ' ...
                        ], file_regex{vol}, ex, examArray(ex).series(ser).path )
        
                end
                
            end % volume
            
        end % found a serie
        
    end % serie in exam
    
    
    if found == 0
        
        % When series are not found
        warning([
            'Could not find a serie corresponding to the regex [ %s] \n'...
            '#%d : %s ' ...
            ], sprintf('%s ',series_tag_regex), ex, examArray(ex).path ) %#ok<SPWRN>
       
    end
    
    
end % exam

end % function
