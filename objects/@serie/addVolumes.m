function addVolumes( serieArray, file_regex, tags )
% Syntax  : serieArray.addVolumes( {'file_regex_1', 'file_regex_2', ...}, {'tag_1', 'tag_2', ...} );
% Example : serieArray.addVolumes( '^f.*nii'                            , 'f' );
% Example : serieArray.addVolumes( {'^f.*nii', '^swrf.*nii'}            , {'f', 'swrf'} );


%% Check inputs

AssertIsSerieArray(serieArray);

AssertIsCharOrCellstr(file_regex);
AssertIsCharOrCellstr(tags );

file_regex = cellstr(file_regex);
tags       = cellstr(tags);

assert( length(file_regex) == length(tags) , 'file_regex and tags must be the same size' )


%% addVolumes to @serie

for ser = 1 : numel(serieArray)
    
    % Be sure to add new volumes to the volumeArray
    nrVolumes = length(serieArray(ser).volumes);
    counter = 0;
    
    for vol = 1 : length(file_regex)
        
        try
            
            volume_found = get_subdir_regex_files(serieArray(ser).path,file_regex{vol},struct('verbose',0,'wanted_number_of_file',1)); % error from this function if not found
            counter = counter + 1;
            serieArray(ser).volumes(nrVolumes + counter) = volume(char(volume_found), tags{vol}, serieArray(ser).exam , serieArray(ser));
            
        catch
            
            [exam_idx,serie_idx] = ind2sub(size(serieArray),ser);
            
            % When volumes are not found
            warning([
                'Could not find recursivly any dir corresponding to the regex [ %s ] \n'...
                '#[%d %d] : %s ' ...
                ], file_regex{vol}, exam_idx, serie_idx, serieArray(ser).exam.path )
            
            serieArray(ser).exam.is_incomplete = 1; % set incomplete flag
            
        end
        
    end % volume
    
end % serie


end % function
