function check_multiecho_Nvol( volumeArray )
% check_multiecho_Nvol will check the number of volumes in all echos of
% each run, then propose the fix if necessary. WARNING : this step is very
% IO intensive, it is recomanded to do it once, as a sanity check, then to
% comment it in the main script

nVol = numel(volumeArray);

for iVol = 1 : nVol
    volume = volumeArray(iVol); % shortcut
    volume_dir = get_parent_path( deblank(volume.path(1,:)) );
    nEcho = size(volume.path,1);

    % already trimmed ?
    orig_dir = fullfile(volume_dir,'orig_me');
    if exist(orig_dir,'dir') > 0
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

    end

    fprintf('\n')

end % iVol

end % function
