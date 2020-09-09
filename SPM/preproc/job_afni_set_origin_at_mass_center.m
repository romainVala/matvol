function job_afni_set_origin_at_mass_center(img)
% JOB_AFNI_SET_ORIGIN_AT_MASS_CENTER - AFNI:3dCM - AFNI:3drefit
%
% INPUT : img can be 'char' of volume(file), multi-level 'cellstr' of volume(file), '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

if isa(img,'volume')
    in_obj  = img;
    img = in_obj.removeEmpty.toJob;
end


%% 3dCM 3drefit

for j = 1 : numel(img)
    
    % Get center of mass (in mm)
    [status,result] = system( sprintf( '3dCM %s', img{j} ) );
    if status~=0
        warning(result)
    end
    % Parse the output of the cmd line
    res = strsplit(result,'\n')';    % if "oblique" dataset, several lines...
    res(cellfun('isempty',res)) = []; % last line is empty
    res = res{end};                  % get this new last line
    res = strsplit(res,' ');         % split the 3 values delimited by a space
    
    % Check if euclidian normal is > 1mm
    XYZ_CenterOfMass = str2double(res);
    euclidian_norm = sqrt(sum(XYZ_CenterOfMass.^2));
    if isnan(euclidian_norm) || euclidian_norm < 1 % no, then skip
        fprintf( 'already at center of mass : %s \n', img{j} )
        continue
    end
    
    % Perform origin shift
    shift = -XYZ_CenterOfMass; % simply take the opposite
    fprintf( 'origin shift : %s \n', img{j} )
    cmd = sprintf( '3drefit -dxorigin %g -dyorigin %g -dzorigin %g %s', shift(1), shift(2), shift(3), img{j} );
    [status,result] = system( cmd );
    if status~=0
        warning(result)
    end
    
end


end % function
