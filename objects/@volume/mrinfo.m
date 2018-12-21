function mrinfo( volumeArray )
% See volume.show


%% Check input arguments

volumeArray = shiftdim(volumeArray,1); % need to shift dimensions to have the volumes displayed in meaningful order.

if numel(volumeArray) == 0
    error('[@volume:mrinfo] no volume to use')
end

% Load user cfg
p = matvol_config;
prepend_content = p.volume_show_prepend;


%% Show with mrview, using the prefix (if they exist)

cmd = [ prepend_content ' mrinfo' ];

for vol = 1 : numel(volumeArray)
    for p = 1 : size(volumeArray(vol).path,1)
        cmd = [cmd ' ' volumeArray(vol).path(p,:)]; %#ok<AGROW>
    end
end

system(cmd);


end % function
