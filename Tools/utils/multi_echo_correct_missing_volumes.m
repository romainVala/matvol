function multi_echo_correct_missing_volumes(img,par)
% MULTI_ECHO_CORRECT_MISSING_VOLUMES will check the number of volumes in each eachos of the same run, and correct it eventually
%
% img : - cellstr of volumes paths
%       OR
%       - @volume object


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end
par.sge = 0;

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

if isa(img,'volume')
    img_obj  = img;
    img = img_obj.getPath;
end


%% Main

nRun = numel(img);

for iRun = 1 : nRun
    
    echos_path = img{iRun};
    if isempty(echos_path)
        continue
    end
    
    nVol     = size(echos_path,1);
    volCount = zeros(1,nVol);
    for iVol = 1 : nVol
        V = nifti(deblank( echos_path(iVol,:) ));
        volCount(iVol) = V.dat.dim(4);
    end
    
    if any(volCount(1) ~= volCount) % different number of volumes ?
        
        [ min_nrVol , idx_min_nrVol ] = min(volCount);
        [ max_nrVol , idx_max_nrVol ] = max(volCount);
        
        % Echo
        fprintf('[%s]: %s %s \n',mfilename, num2str(volCount - min_nrVol), fileparts( deblank( echos_path(iVol,:) )) )
        
        run_path = fileparts(deblank( echos_path(iVol,:) ));
        dic_json = gfile(run_path,'^dic_.*json$', struct('verbose',0));
        dic_json = dic_json{1};
        
        AcquisitionNumber = cell(nVol,1);
        for iVol = 1 : nVol
            content = get_file_content_as_char( deblank(dic_json(iVol,:)) );
            AcquisitionNumber{iVol,1} =  cellfun( @str2double, get_field_mul(content, 'AcquisitionNumber',0) );
        end
        
        MIN = cellfun(@min   ,AcquisitionNumber);
        MAX = cellfun(@max   ,AcquisitionNumber);
        N   = cellfun(@length,AcquisitionNumber);
        
        same_MIN = all(MIN(1) == MIN);
        same_MAX = all(MAX(1) == MAX);
        same_N   = all(  N(1) ==   N);
        
        MAX_equal_N = all( MAX == N );
        
        total_volDiff = sum(diff(N));
        
        last_volume_missing   = same_MIN & ~same_MAX & ~same_N &  MAX_equal_N & total_volDiff;
        middle_volume_missing = same_MIN &  same_MAX & ~same_N & ~MAX_equal_N & total_volDiff;
        
        if last_volume_missing
            V = nifti(deblank( echos_path(idx_max_nrVol,:) ));
            if V.dat.dim(4) > min_nrVol
                V.dat.dim(4) = min_nrVol;
                V.dat(:,:,:,:) = V.dat(:,:,:,1:min_nrVol);
                create(V); % write volume
                clear V
            end
        elseif middle_volume_missing
            diff_vol_idx   = [ AcquisitionNumber{idx_min_nrVol} , [ diff(AcquisitionNumber{idx_min_nrVol}) ; 0 ] ];
            idx_interp_vol = diff_vol_idx(diff_vol_idx(:,2) == 2,1) + 1;
            V = nifti(deblank( echos_path(idx_min_nrVol,:) ));
            % I need a trick to "add" a volume in the 4D file
            prev   = V.dat(:,:,:,1:idx_interp_vol-1);
            middle = (V.dat(:,:,:,idx_interp_vol-1)+V.dat(:,:,:,idx_interp_vol))/2 ; % missing volume is average athe two surroundings
            next   = V.dat(:,:,:,idx_interp_vol:end);
            new_4D = cat(4,prev, middle, next);
            V.dat.dim(4) = max_nrVol;
            for idx = 1 : max_nrVol
                V.dat(:,:,:,idx) = new_4D(:,:,:,idx);
            end
            clear prev middle next new_4D
            create(V); % write volume
            clear V
        else
            error(' ')
        end
        
    end
    
end

fprintf('[%s]: ok ! \n', mfilename);


end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_field_mul(content, regex,concatenate)

if ~exist('concatenate','var'),    concatenate=1; end

% Fetch the line content
start = regexp(content           , regex, 'once');
idx1 = regexp(content(start:end),'[','once');
idx2 = regexp(content(start:end),',','once');
if idx1 < idx2
    stop  = regexp(content(start:end), ']'  , 'once');
else
    stop  = regexp(content(start:end), ','  , 'once');
end
line = content(start:start+stop);

if strfind(line(length(regex):end),'Csa') % in cas of single value, and not multiple ( such as signle B0 value for diff )
    stop  = regexp(content(start:end), ','  , 'once');
    line = content(start:start+stop);
end

token = regexp(line, ': (.*),','tokens'); % extract the value from the line
if isempty(token)
    result = [];
    return
else
    res    = token{1}{1};
    VECT_cell_raw = strsplit(res,'\n')';
    if length(VECT_cell_raw)>1
        VECT_cell = VECT_cell_raw(2:end-1);
    else
        VECT_cell = VECT_cell_raw;
    end
    VECT_cell = strrep(VECT_cell,',','');
    VECT_cell = strrep(VECT_cell,' ','');
    result    = strrep(VECT_cell,'"','');
end

if concatenate
    if ischar(result{1}) % instead of a cell vector of string just concatenate with _
        rr=result{1};
        for kk=2:length(result); rr=[rr '_' result{kk}];end
        result = rr;
    end
end

end % function
