function checkreg( volumeArray )
% CHECKREG

AssertIsVolumeArray(volumeArray);

spm_check_registration( char(volumeArray.path) )

end % function
