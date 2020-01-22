function correct_missing_volumes(img,par)
% to be used with great consion, ... only tested for a few volume missing
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
%unzip keeping the same cell structure
for iRun = 1 : nRun
    img{iRun} = char(unzip_volume(img(iRun)));
end

for iRun = 1 : nRun

    echos_path = img{iRun};
    if isempty(echos_path)
        continue
    end
    
    nVol     = size(echos_path,1);
    volCount = zeros(1,nVol);
    AcquisitionNumber = cell(nVol,1);
    dic_json = addprefixtofilenames(change_file_extension(echos_path,'.json'),'dic_param_');

    for iVol = 1 : nVol       
        V = nifti(deblank( echos_path(iVol,:) ));
        volCount(iVol) = V.dat.dim(4);
        if ~exist(deblank(dic_json(iVol,:)))
            fprintf('Can not find corresponding dic_prama json for %s\n', echos_path(iVol,:))
            continue
        end
        content = get_file_content_as_char( deblank(dic_json(iVol,:)) );
        AcqNum =  cellfun( @str2double, get_field_mul(content, 'AcquisitionNumber',0) );
        AcquisitionNumber{iVol,1} = AcqNum;
       
        missing = max(AcqNum) - length(AcqNum);
        if missing
            dd = diff(AcqNum);
            ind = find(dd>1);
            fprintf('%d Missing Volume for %s\n',missing,echos_path(iVol,:));
            if min(AcqNum)>1
                fprintf(' Starting at %d (missing %d volume in the beginin\n',min(AcqNum),min(AcqNum)-1);
            end
            
            if isempty(ind)
                fprintf('No missing volume in the middel\n');
                continue
            end
            
            if max(dd)>2
                warning('2 or more consecutive volume \n')
                fprintf('skiping correction for %s\n',echos_path(iVol,:));
                continue
            end
            
            if length(ind)>1, waring('Romain need to check, not sure if it works with more than one volume to interpolate');end
            for nb_missing = 1:length(ind)
                
                idx_interp_vol = ind(nb_missing);
                AcquisitionNumber{iVol,1} = [AcquisitionNumber{iVol,1} ;idx_interp_vol+1];
                fprintf('Interpoling Vol %d\n',idx_interp_vol+1)
                
                prev   = V.dat(:,:,:,1:idx_interp_vol);
                middle = (V.dat(:,:,:,idx_interp_vol)+V.dat(:,:,:,idx_interp_vol+1))/2 ; % missing volume is average athe two surroundings
                next   = V.dat(:,:,:,idx_interp_vol+1:end);
                new_4D = cat(4,prev, middle, next);
                
                V.dat.dim(4) = V.dat.dim(4) + 1;
                V =  replace_volume(V,new_4D);

                clear prev middle next new_4D
                volCount(iVol) =  volCount(iVol) + 1;
                ind = ind +1; %because one more volume, TO CHECK if 
            end
            
            clear V
            
        end
        
    end
    
    if nVol > 1 %multiecho case, try to adjust first or last
        if any(volCount(1) ~= volCount) % different number of volumes ?
            
            %[ min_nrVol , idx_min_nrVol ] = min(volCount);
            %[ max_nrVol , idx_max_nrVol ] = max(volCount);
            min_nrVol =  min(volCount);
            idx_min_nrVol = find( min(volCount) == volCount) ;
            idx_max_nrVol = find( max(volCount) == volCount)  ;
            
            % Echo
            fprintf('Finding different volume (comparing to other echos) for serie %s\n',fileparts( deblank( echos_path(iVol,:) )))
            Volume_toomuch = volCount -  min(volCount);
            
            MIN = cellfun(@min   ,AcquisitionNumber);
            MAX = cellfun(@max   ,AcquisitionNumber);
            N   = cellfun(@length,AcquisitionNumber);
            
            same_MIN = all(MIN(1) == MIN);
            same_MAX = all(MAX(1) == MAX);
            same_N   = all(  N(1) ==   N);
            
            %MAX_equal_N = all( MAX == N );
            
            total_volDiff = sum(diff(N));            
            last_volume_missing   = ~same_MAX & ~same_N & total_volDiff;            
            first_volume_missing  = ~same_MIN & ~same_N & total_volDiff;            
            middle_volume_missing = same_MIN &  same_MAX & ~same_N & total_volDiff;
            
            if middle_volume_missing
                error('This should not happend, contact romain')
            end
            
            if last_volume_missing                
                for volume_to_change=1:length(idx_max_nrVol)
                    [~, vn] = fileparts( deblank( echos_path(idx_max_nrVol(volume_to_change),:) ));
                    fprintf('Removing %d LAST volume for echo %s\n',Volume_toomuch(idx_max_nrVol(volume_to_change)), vn);
                    
                    V = nifti(deblank( echos_path(idx_max_nrVol(volume_to_change),:) ));
                    if V.dat.dim(4) > min_nrVol
                        
                        new_4D = V.dat(:,:,:,1:min_nrVol);
                        V.dat.dim(4) = min_nrVol;                        
                        replace_volume(V,new_4D)                       
                        clear V
                    end
                end                
            end
            
            if first_volume_missing
                for volume_to_change=1:length(idx_max_nrVol)
                    [~, vn] = fileparts( deblank( echos_path(idx_max_nrVol(volume_to_change),:) ));
                    fprintf('Removing %d FIRST volume for echo %s\n',Volume_toomuch(idx_max_nrVol(volume_to_change)), vn);
                    
                    V = nifti(deblank( echos_path(idx_max_nrVol(volume_to_change),:) ));
                    if V.dat.dim(4) > min_nrVol
                        start_ind = V.dat.dim(4) - min_nrVol +1;
                        
                        new_4D = V.dat(:,:,:,start_ind:end);
                        V.dat.dim(4) = min_nrVol;  %attention ca change la taille du 4D
                                                
                        replace_volume(V,new_4D)
                        clear V
                    end
                end            
            end
            
        end
    end
    
end

fprintf('[%s]: ok ! \n', mfilename);


end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function V = replace_volume(V,new_4D)
%change output filename taking into account the new volume number

old_name = V.dat.fname;
[fname_dir, fname] = get_parent_path( old_name );
ii = strfind(fname,'_');
new_fname = sprintf('f%3d%s',size(V.dat,4),fname(ii(1):end));
fprintf('Creating %s and Deleting %s\n',new_fname,old_name);
V.dat.fname = fullfile(fname_dir, new_fname);

if strcmp(new_fname,fname)
    error('new name and old name is the same\n')
end

if exist('new_4D','var')
    V.dat(:,:,:,:) = new_4D;
end

create(V); % write volume
do_delete(old_name,0);

end %function
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
