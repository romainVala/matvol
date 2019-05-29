function r = do_checkreg(f,autowait)

if ~exist('autowait','var')
    autowait=0;
end

[pp ss] = get_parent_path(f);

for k=1:length(f)
    
    v=spm_vol(char(f(k)));
    spm_check_registration(v)
    spm_orthviews('MaxBB')

    fprintf('Viewing %s \n',pp{k})
    if autowait
        pause(autowait)
    else
        aa = input('Is it ok?','s')
        if isempty(aa); aa=' ';end
        r(k) = aa;
    end
    
end