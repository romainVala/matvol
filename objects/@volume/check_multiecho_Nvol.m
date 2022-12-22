function check_multiecho_Nvol( volumeArray )
% check_multiecho_Nvol will check the number of volumes in all echos of
% each run, then propose the fix if necessary.

nVol = numel(volumeArray);

for iVol = 1 : nVol
    volume = volumeArray(iVol); % shortcut
    volume_dir = get_parent_path( deblank(volume.path(1,:)) );
    nEcho = size(volume.path,1);

    % already trimmed ?
    orig_dir = fullfile(volume_dir,'Nvol_notOK_orig_files');
    if exist(orig_dir,'dir') > 0
        % fprintf('[%s] trimmed : %s \n', mfilename, volume_dir)
        continue
    end
    
    % already checked ?
    check_file = fullfile(volume_dir,'Nvol_OK.txt');
    if exist(check_file,'file') > 0
        % fprintf('[%s] OK : %s \n', mfilename, volume_dir)
        continue
    end

    % load nifti header
    data = struct; % this is a temporary data container, cleaned for every volume
    for iEcho = 1 : nEcho
        data(iEcho).header = spm_vol(deblank(volume.path(iEcho,:)));
        data(iEcho).Nvol   = length(data(iEcho).header);
    end

    Nvol = [data.Nvol]';

    if ~all(Nvol(1) == Nvol) % same number of volumes in all echos ?

        % logs
        fprintf('[%s] different number of volumes detected : %s \n', mfilename, get_parent_path(volume.path(1,:)))
        for iEcho = 1 : nEcho
            fprintf('[%s] %d  //  %s \n', mfilename, Nvol(iEcho), deblank(volume.name(iEcho,:)))
        end

        min_Nvol = min(Nvol);

        % copy original
        fprintf('[%s]: copy original files in %s... \n', mfilename, orig_dir)
        mkdir(orig_dir)
        for iEcho = 1 : nEcho
            src = deblank(volume.path(iEcho,:));
            dst = fullfile(orig_dir,deblank(volume.name(iEcho,:)));
            copyfile(src,dst)
        end
        fprintf('[%s]: ... copy done \n', mfilename)

        % trim
        for iEcho = 1 : nEcho
            if Nvol(iEcho) > min_Nvol
                fprintf('[%s]: trimming %s \n', mfilename, deblank(volume.name(iEcho,:)))
                data(iEcho).nifti = data(iEcho).header(1).private;
                data(iEcho).nifti.dat.dim(4) = min_Nvol;
                data(iEcho).nifti.dat(:,:,:,:) = data(iEcho).nifti.dat(:,:,:,1:min_Nvol);
                create(data(iEcho).nifti); % write on disk
            end
        end
        fprintf('[%s]: ... trimming to %d volumes done \n', mfilename, min_Nvol)

    else
        
        % just write the file
        fprintf('[%s] checked : %s \n', mfilename, volume_dir)
        fid = fopen(check_file,'w'); fclose(fid);
        
    end


end % iVol

end % function
