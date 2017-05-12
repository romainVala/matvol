
suj=get_subdir_regex(pwd,'DEV')

reg_ex = {'DP_TSE','T1_TSE','T2FLAIR','DWI_b150'}
reg_ex = {'DP_TSE','T1_TSE'}


for kr=1:length(reg_ex)
    
    dd = get_subdir_regex_multi(suj,reg_ex(kr));
    ff=get_subdir_regex_files(dd,'img');
    
    dout = r_mkdir(suj,['concat_' reg_ex{kr}]);
    
    %fs = cellstr(ff{nbs});
    
    %avec le realign
    par.resample='100x100x200';        par.prefix='rz2_';
    do_c3d_resize(ff,par)
    
    fr = get_subdir_regex_files(dd,'^rz2.*nii')
    
    par.realign.type = 'mean_and_reslice'
    for k=1:length(fr)
        j(k)=do_realign(fr(k),par);
    end
    spm_jobman('run',j)
    
end

%pour la DTI
for nbs=1:length(suj)
    dd = get_subdir_regex(suj(nbs),'DWI_b');
    ff=get_subdir_regex_files(dd,'img');
    par.resample='100x100x200';        par.prefix='rz2_';
    do_c3d_resize(ff,par)
    
    fr = get_subdir_regex_files(dd,'^rz2.*nii')
    par.realign.type = 'mean_and_reslice'
    for nbf=1:size(fr{1},1)
        ff = {[fr{1}(nbf,:) ; fr{2}(nbf,:)]};
        j=do_realign(ff,par);
        spm_jobman('run',j)
    end
end
for nbs=1:length(suj)
    
    dd = get_subdir_regex(suj(nbs),'DWI_b');
    ff=get_subdir_regex_files(dd,'img');
    dout = r_mkdir(suj(nbs),'DTIconcat');
    par.imgregex = '^meanrz2';
    dti_import_multiple(dd(1),dout,par)
end

dti =get_subdir_regex(suj,'DTIconcat_in')
fdti=get_subdir_regex_files(dti,'4D')
clear par;par.sge=0
do_fsl_bet(fdti,par)
do_fsl_dtifit(fdti,par)


%DTI methode daniel
for nbs=1:length(suj)
    dd = get_subdir_regex(suj(nbs),'DWI_b');
    ff=get_subdir_regex_files(dd,'img');
    
    fout = concat_interleaved(ff(1),ff(2));
    dout = r_mkdir(suj(nbs),'DTIconcat_interleav');
    par.imgregex = '^rintercal_f.*img';
    dti_import_multiple(dd(1),dout,par)
end